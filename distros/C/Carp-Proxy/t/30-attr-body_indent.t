# -*- cperl -*-
use warnings;
use strict;
use 5.010;

use English '-no_match_vars';
use Test::More;
use Test::Exception;

my $original;
my $replacement;
BEGIN {
    $original    = 2;      #----- Default for 'body_indent' attribute
    $replacement = 6;

    use_ok( 'Carp::Proxy',
            fatal      => {},
            fatal_body => { body_indent => $replacement },
          );
}

main();
done_testing();

#----------------------------------------------------------------------

sub handler {
    my( $cp, $setting ) = @_;

    $cp->body_indent( $setting )
        if defined $setting;

    $cp->filled('Diagnostic message here');
    return;
}

sub main {

    foreach my $tuple
        ([ \&fatal,      undef,        $original,    'default'     ],
         [ \&fatal,      $replacement, $replacement, 'override'    ],
         [ \&fatal,      0,            0,            'zero_test'   ],
         [ \&fatal_body, undef,        $replacement, 'constructed' ],
         [ \&fatal_body, $original,    $original,    'cons-over'   ],
        ) {

        my( $proxy, $setting, $compare, $title ) = @{ $tuple };

        #----- The default for 'header_indent' is 2
        my $with_header = 2 + $compare;

        throws_ok{ $proxy->( 'handler', $setting ) }
            qr{
                  \A

                  ~+                                            \r? \n
                  \QFatal << handler >>\E                       \r? \n
                  ~+                                            \r? \n

                  \Q  *** Description ***\E                     \r? \n
                  [ ]{$with_header} \QDiagnostic message here\E \r? \n
              }x,
              "Body indentation matches $compare for $title";
    }

    return;
}
