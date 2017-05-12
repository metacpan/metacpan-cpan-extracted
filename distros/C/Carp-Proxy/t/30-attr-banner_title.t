# -*- cperl -*-
use warnings;
use strict;
use 5.010;

use English '-no_match_vars';
use Test::More;
use Test::Exception;

my $original;
my $replacement;
BEGIN{
    $original    = 'Fatal';   #----- Carp::Proxy default for 'banner_title'
    $replacement = 'Oops';

    use_ok( 'Carp::Proxy',
            fatal        => {},
            fatal_banner => { banner_title => $replacement },
          );
}

main();
done_testing();

#----------------------------------------------------------------------

sub handler {
    my( $cp, $setting ) = @_;

    $cp->banner_title( $setting )
        if defined $setting;

    $cp->filled('Diagnostic message here');

    return;
}

sub main {

    foreach my $tuple
        ([ \&fatal,        undef,        $original,    'default'     ],
         [ \&fatal,        $replacement, $replacement, 'override'    ],
         [ \&fatal_banner, undef,        $replacement, 'constructed' ],
         [ \&fatal_banner, $original,    $original,    'cons_over'   ],
        ) {

        my( $proxy, $setting, $compare, $title ) = @{ $tuple };

        throws_ok{ $proxy->( 'handler', $setting ) }
            qr{
                  \A

                  ~+                              \r? \n
                  $compare \Q << handler >>\E     \r? \n
                  ~+                              \r? \n

                  \Q  *** Description ***\E       \r? \n
                  \Q    Diagnostic message here\E \r? \n
              }x,
              "banner_title affects banner for $title";
    }

    return;
}
