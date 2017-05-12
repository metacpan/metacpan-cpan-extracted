# -*- cperl -*-
use warnings;
use strict;
use 5.010;

use English '-no_match_vars';
use Test::More;
use Test::Exception;
use YAML::XS qw( Load );

BEGIN {
    use_ok( 'Carp::Proxy',
            fatal      => {},
            fatal_yaml => { as_yaml => 1 },
            );
}

main();
done_testing();

#----------------------------------------------------------------------

sub handler {
    my( $cp, $setting ) = @_;

    $cp->as_yaml( $setting )
        if defined $setting;

    $cp->filled('Diagnostic message here');
    return;
}

sub main {

    verify_message_throws();
    verify_yaml_throws();

    return;
}

sub verify_message_throws {

    foreach my $tuple ([ \&fatal,      undef, 'default'    ],
                       [ \&fatal,      0,     'explicit'   ],
                       [ \&fatal_yaml, 0,     'overridden' ],
                      ) {

        my( $proxy, $setting, $title ) = @{ $tuple };

        throws_ok{ $proxy->( 'handler', $setting ) }
            qr{
                  \Q  *** Description ***\E        \r? \n
                  \Q    Diagnostic message here\E  \r? \n
              }x,
            "Non yaml throw for $title";
    }

    return;
}

sub verify_yaml_throws {

    foreach my $tuple ([ \&fatal,      1,     'overridden'  ],
                       [ \&fatal_yaml, undef, 'constructed' ],
                      ) {

        my( $proxy, $setting, $title ) = @{ $tuple };

        eval{ $proxy->( 'handler', $setting )};

        my $yaml = $EVAL_ERROR;

        is 0 + not(length $yaml), 0,
            "Proxy continues to throw when as_yaml is true for $title";

        my $reconstituted;
        lives_ok{ $reconstituted = Load( $yaml )}
            "Load() reconstitutes as_yaml output for $title";

        isa_ok
            $reconstituted,
            'Carp::Proxy',
            "Reconstituted as_yaml output isa Carp::Proxy for $title";

        is_deeply
            $reconstituted->sections->[0],
            [ 'filled_section', 'Diagnostic message here', undef ],
            "Reconstituted section matches our message for $title";
    }

    return;
}
