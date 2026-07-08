use Test2::V0 '!meta', '!pass';
use Socket qw/AF_UNIX PF_UNSPEC SOCK_STREAM/;

use DBIx::QuickORM;
use DBIx::QuickORM::Row;

subtest builtin_shaped_calls => sub {
    # connect/index/socket are DSL builders that shadow the Perl built-ins in a
    # package that imported DBIx::QuickORM. A call shaped like the built-in now
    # croaks with a hint to use CORE:: instead of silently misrouting into the
    # builder.
    like(
        dies { index( 'abcdef', 'cd' ) },
        qr/CORE::index/,
        "built-in-shaped index() croaks pointing at CORE::index",
    );

    like(
        dies { socket( my $fh, AF_UNIX, SOCK_STREAM, PF_UNSPEC ) },
        qr/CORE::socket/,
        "built-in-shaped socket() croaks pointing at CORE::socket",
    );

    # CORE:: reaches the real built-ins.
    is( CORE::index( 'abcdef', 'cd' ), 2, "CORE::index reaches the Perl built-in" );

    ok(
        lives {
            CORE::socket( my $fh, AF_UNIX, SOCK_STREAM, PF_UNSPEC );
            close($fh) if $fh;
        },
        "CORE::socket reaches the Perl built-in",
    );
};

subtest alt_overrides => sub {
    schema dsl_alt => sub {
        table things => sub {
            column id => sub {
                primary_key;
                affinity 'numeric';
                type \'INTEGER';
            };

            column value => sub {
                affinity 'string';
                type \'TEXT';
            };

            alt mysql => sub {
                column value => sub {
                    affinity 'numeric';
                    type \'BIGINT';
                };
            };
        };
    };

    my $table = schema('dsl_alt:mysql')->{tables}->{things};
    is( $table->{columns}->{value}->{affinity},
        'numeric', "alt hash values override base values" );
    is( ${ $table->{columns}->{value}->{type} },
        'BIGINT', "alt scalar-ref values override base scalar refs" );

    like(
        dies { schema('dsl_alt:bogus') },
        qr/not a defined Schema variant/,
        "unknown variants croak instead of silently returning the base object",
    );
};

subtest column_coderef_default_shorthand => sub {
    my $default = sub { 42 };

    schema dsl_default => sub {
        table things => sub {
            column id => sub {
                primary_key;
                affinity 'numeric';
            };

            column answer => default($default);
        };
    };

    my $column = schema('dsl_default')->{tables}->{things}->{columns}->{answer};
    ref_is( $column->{perl_default},
        $default, "column foo => default(sub {...}) keeps the perl default" );
};

{

    package Test::QORM::DSLBaseRow;
    our @ISA = ('DBIx::QuickORM::Row');
    $INC{'Test/QORM/DSLBaseRow.pm'} = __FILE__;

    package Test::QORM::DSLTable;
    $INC{'Test/QORM/DSLTable.pm'} = __FILE__;

    use DBIx::QuickORM type => 'table';

    my $default = sub { 7 };

    table dsl_table => sub {
        row_class '+Test::QORM::DSLBaseRow';

        column id => sub {
            primary_key;
            affinity 'numeric';
        };

        column generated => default($default);
    };
}

package main;

subtest table_class_metadata => sub {
    isa_ok(
        'Test::QORM::DSLTable',
        ['Test::QORM::DSLBaseRow'],
        "table class honors row_class as its base class"
    );

    ok(
        lives { Test::QORM::DSLTable->qorm_table },
        "qorm_table can clone metadata containing coderefs"
    );

    my $one = Test::QORM::DSLTable->qorm_table;
    my $two = Test::QORM::DSLTable->qorm_table;
    ref_is_not( $one, $two, "qorm_table returns a fresh clone" );
    ref_is(
        $one->{meta}->{columns}->{generated}->{meta}->{perl_default},
        $two->{meta}->{columns}->{generated}->{meta}->{perl_default},
        "coderef defaults are preserved in clones"
    );
};

done_testing;
