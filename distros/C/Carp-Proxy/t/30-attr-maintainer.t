# -*- cperl -*-
use warnings;
use strict;
use 5.010;

use English '-no_match_vars';
use Test::More;
use Test::Exception;

my $call_me;
BEGIN {
    $call_me = 'call-me 555-1212';

    use_ok( 'Carp::Proxy',

            fatal  => { context    => 'none'   },

            fatalm => { context    => 'none',
                        maintainer => $call_me },
          );
}

main();
done_testing();

#----------------------------------------------------------------------

sub handler {
    my( $cp, $setting ) = @_;

    $cp->maintainer( $setting )
        if defined $setting;

    $cp->contact_maintainer;
    return;
}

sub main {

    my $empty_rex =
        qr{
              ~+ \s+
              Fatal [ ] << [ ] handler [ ] >> \s+
              ~+ \s+
              \z
          }x;

    my $contact_rex =
        qr{
              ~+                       \r? \n
              \QFatal << handler >>\E  \r? \n
              ~+                       \r? \n

              \Q  *** Please contact the maintainer ***\E  \r? \n
              \Q    call-me 555-1212\E                     \r? \n
          }x;

    foreach my $tuple
        ([ \&fatal,  undef,    $empty_rex,   'default'     ],
         [ \&fatal,  $call_me, $contact_rex, 'override'    ],
         [ \&fatalm, undef,    $contact_rex, 'constructor' ],
         [ \&fatalm, '',       $empty_rex,   'over-cons'   ],
        ) {

        my( $proxy, $setting, $rex, $title ) = @{ $tuple };

        throws_ok{ $proxy->( 'handler', $setting )}
            $rex,
            $title;
    }

    return;
}
