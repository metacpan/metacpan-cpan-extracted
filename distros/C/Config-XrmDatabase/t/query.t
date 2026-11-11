#! perl

use v5.26;
use Test2::V0;

use Config::XrmDatabase;

use experimental 'signatures';

sub create_db ( %args ) {
    my $db = Config::XrmDatabase->new( %args );
    $db->insert( 'xmh*Paned*activeForeground',       'red' );
    $db->insert( '*incorporate.Foreground',          'blue' );
    $db->insert( 'xmh.toc*Command*activeForeground', 'green' );
    $db->insert( 'xmh.toc*?.Foreground',             'white' );
    $db->insert( 'xmh.toc*Command.activeForeground', 'black' );

    $db;
}

sub query ( $which = 'query', %args ) {

    my $fail = delete $args{fail};

    my ( %new_args, %query_args );

    if ( $which eq 'new' ) {
        %new_args = map { ; "query_${_}" => $args{$_} } keys %args;
    }
    elsif ( $which eq 'query' ) {
        %query_args = %args;
    }

    else {
        die "unexpected which: $which";
    }

    my $db = create_db( %new_args );

    my $name = $fail ? 'What.Me.Worry.About.Anything' : 'Xmh.Paned.Box.Command.Foreground';

    $db->query( $name, 'xmh.toc.messagefunctions.incorporate.activeForeground', %query_args );
}

sub return_value ( $which ) {

    subtest 'default' => sub {
        is( query( $which ), 'black', 'value' );
    };

    subtest 'value' => sub {
        is( query( $which, return_value => 'value' ), 'black', 'value' );
    };

    subtest 'reference' => sub {
        is( query( $which, return_value => 'reference' )->$*, 'black', 'value' );
    };

    subtest 'all' => sub {
        is(
            query( $which, return_value => 'all' ),
            hash {
                field value       => 'black';
                field key         => [ 'xmh', 'toc', q{*}, 'Command', 'activeForeground' ];
                field match_count => 1;
                end;
            },
            'value',
        );
    };
}

sub failure ( $which ) {

    subtest 'default' => sub {
        is( query( $which, fail => 1 ), U(), 'value' );
    };

    subtest 'undef' => sub {
        is( query( $which, fail => 1, on_failure => 'undef' ), U(), 'value' );
    };

    subtest 'throw' => sub {
        my $res = dies {
            query( $which, fail => 1, on_failure => 'throw' );
        };

        isa_ok( $res, ['Config::XrmDatabase::Failure::query'], 'exception' );
        ## no critic  (ComplexRegexes)
        like(
            "$res",
            qr{ \Qxmh.toc.messagefunctions.incorporate.activeForeground\E
                  .*
                 \QWhat.Me.Worry.About.Anything\E
                }x,
        );
    };

    subtest 'code' => sub {
        my $failed;
        is( query( $which, fail => 1, on_failure => sub { $failed = 7; 42; } ), 42, 'return value' );
        is( $failed,                                                            7,  'code ran' );
    };

}

subtest 'return value' => sub {

    subtest 'constructor args', \&return_value, 'new';
    subtest 'query args',       \&return_value, 'query';

};

subtest failure => sub {

    subtest 'constructor args', \&failure, 'new';
    subtest 'query args',       \&failure, 'query';

};

# create a db from @$keys (each key's value is the key) and query it
# with the given name (class is the upper-cased name).  fails if the
# query generates any warnings.
sub query_db ( $keys, $name, %args ) {
    my $db = Config::XrmDatabase->new;
    $db->insert( $_, $_ ) for @$keys;
    my $res;
    ok( no_warnings { $res = $db->query( uc $name, $name, %args ) }, 'no warnings' );
    return $res;
}

subtest 'loose binding matches zero components' => sub {

    for my $test ( [ 'a*b', 'a.b' ], [ '*b', 'b' ], [ 'a*b*c', 'a.b.c' ], [ 'a.b.c*d', 'a.b.c.d' ], ) {
        my ( $key, $name ) = @$test;
        subtest "$key matches $name" => sub {
            is( query_db( [$key], $name ), $key, 'value' );
        };
    }
};

subtest 'interior node without a value is not a match' => sub {

    subtest 'default' => sub {
        is( query_db( ['a.b.c'], 'a.b' ), U(), 'value' );
    };

    subtest 'all' => sub {
        is( query_db( ['a.b.c'], 'a.b', return_value => 'all' ), U(), 'value' );
    };

    subtest 'reference' => sub {
        is( query_db( ['a.b.c'], 'a.b', return_value => 'reference' ), U(), 'value' );
    };

    subtest 'throw' => sub {
        my $res = dies { query_db( ['a.b.c'], 'a.b', on_failure => 'throw' ) };
        isa_ok( $res, ['Config::XrmDatabase::Failure::query'], 'exception' );
    };

    subtest 'does not mask a loose match' => sub {
        is( query_db( [ 'a.b.c', 'a*b' ], 'a.b' ), 'a*b', 'value' );
    };
};

subtest 'single wildcard before last component' => sub {
    is( query_db( ['a?c'],   'a.b' ),   U(),   'a?c does not match a.b' );
    is( query_db( ['a?c.d'], 'a.b' ),   U(),   'a?c.d does not match a.b' );
    is( query_db( ['a?c'],   'a.b.c' ), 'a?c', 'a?c matches a.b.c' );
};

subtest 'matched key includes loose bindings' => sub {

    for my $test (
        [ 'a*b',   'a.b',     [qw( a * b )] ],
        [ '*b',    'b',       [qw( * b )] ],
        [ 'a*b.c', 'a.b.c',   [qw( a * b c )] ],
        [ 'a*b.c', 'a.x.b.c', [qw( a * b c )] ],
        [ 'a*?.c', 'a.b.c',   [qw( a * ? c )] ],
        [ 'a*b*c', 'a.b.c',   [qw( a * b * c )] ],
      )
    {
        my ( $key, $name, $expected ) = @$test;
        subtest "$key vs $name" => sub {
            my $res = query_db( [$key], $name, return_value => 'all' );
            is( $res->{key}, $expected, 'key' );
        };
    }
};

done_testing;
