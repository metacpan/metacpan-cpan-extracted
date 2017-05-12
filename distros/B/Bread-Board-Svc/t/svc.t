use strict;
use warnings;

use Test::More;
use Test::Exception;
use Bread::Board;
use Scalar::Util qw(refaddr);

BEGIN { use_ok( "Bread::Board::Svc", "svc", "svc_singleton" ) }

{

    package MY::Class;

    sub new {
        my $class = shift;
        my $data  = [@_];
        bless( $data, $class );
    }
    $INC{'MY/Class.pm'} = __FILE__;
}

sub test_container {
    return container C => as {
        service s1 => 'S1';
        service s2 => 'S2';
    };
}

sub test_service {
    my ( $build, $test ) = @_;

    my $svc_name = 'test';

    # adding service
    my $c = test_container();
    container $c => as { $build->($svc_name); };

    # testing
    $test->( sub { $c->fetch($svc_name)->get } );
}

test_service(
    sub { svc shift() => 'LITERAL'; },
    sub {
        is( shift()->(), 'LITERAL',
            "With one parameter svc returns literal service" );
    }
);

throws_ok {
    test_service(
        sub {
            svc_singleton( shift() => 'LITERAL' );
        },
        sub { }
    );
}
qr{svc_singleton: invalid args},
    'svc_singleton may not create literal service';

test_service(
    sub {
        svc shift(), 'MY::Class', [ 's2', 's1', ], sub { [@_]; };
    },
    sub {
        my $resolve = shift();

        my $resolved = $resolve->();
        my ( $class, %args ) = @$resolved;
        is_deeply(
            [ $class, \%args ],
            [ 'MY::Class', { s1 => 'S1', s2 => 'S2' } ],
            'passing class, array deps, block'
        );

        cmp_ok( refaddr($resolved), '!=', $resolve->(),
            "svc produces new structure with every call " );
    }
);

test_service(
    sub {
        svc_singleton shift(), 'MY::Class', [ 's2', 's1', ], sub { [@_]; };
    },
    sub {
        my $resolve = shift();

        my $resolved = $resolve->();
        my ( $class, %args ) = @$resolved;
        is_deeply(
            [ $class, \%args ],
            [ 'MY::Class', { s1 => 'S1', s2 => 'S2' } ],
            'passing class, array deps, block'
        );

        cmp_ok( refaddr($resolved), '==', $resolve->(),
            "svc_singleton produces same structure with every call " );
    }
);

test_service(
    sub {
        svc(shift(), 'MY::Class',
            { service1 => 's1', service2 => 's2', },
            sub { [@_]; }
        );
    },
    sub {
        my ( $class, %args ) = @{ shift()->() };
        is_deeply(
            [ $class, \%args ],
            [ 'MY::Class', { service1 => 'S1', service2 => 'S2' } ],
            'passing class, hash deps, block'
        );
    }
);

test_service(
    sub {
        svc( shift(), 'MY::Class', \[ 's1', 's2' ], sub { [@_]; } );
    },
    sub {
        is_deeply(
            shift()->(),
            [ 'MY::Class', 'S1', 'S2' ],
            'passing class, pos deps, block'
        );
    }
);

test_service(
    sub {
        svc( shift(), 'MY::Class', [ 's2', 's1', ] );
    },
    sub {
        my $got = shift()->();
        my $expected = MY::Class->new( s1 => 'S1', s2 => 'S2' );
        is_deeply( ( map { [ ref $_, +{@$_} ]; } $got, $expected ),
            'passing class, array deps' );
    }
);

test_service(
    sub {
        svc( shift(), 'MY::Class', { service1 => 's1', service2 => 's2', }, );
    },
    sub {
        my $got = shift()->();
        my $expected = MY::Class->new( service1 => 'S1', service2 => 'S2' );
        is_deeply( ( map { [ ref $_, +{@$_} ]; } $got, $expected ),
            'passing class, hash deps' );
    }
);

test_service(
    sub {
        svc( shift(), 'MY::Class', \[ 's2', 's1' ], );
    },
    sub {
        is_deeply(
            shift()->(),
            MY::Class->new( 'S2', 'S1' ),
            'passing class, pos deps'
        );
    }
);

test_service(
    sub {
        svc shift(), [ 's2', 's1', ], sub { [@_]; };
    },
    sub {
        my %params = @{ shift()->() };
        is_deeply(
            \%params,
            { s1 => 'S1', s2 => 'S2' },
            'passing array deps, block'
        );
    }
);

test_service(
    sub {
        svc( shift(), { service1 => 's1', service2 => 's2', },
            sub { [@_]; } );
    },
    sub {
        my %params = @{ shift()->() };
        is_deeply(
            \%params,
            { service1 => 'S1', service2 => 'S2' },
            'passing hash deps, block'
        );
    }
);

test_service(
    sub {
        svc( shift(), \[ 's1', 's2' ], sub { [@_]; } );
    },
    sub {
        is_deeply( shift()->(), [ 'S1', 'S2' ], 'passing pos deps, block' );
    }
);


done_testing();

# vim: expandtab:shiftwidth=4:tabstop=4:softtabstop=0:textwidth=78:
