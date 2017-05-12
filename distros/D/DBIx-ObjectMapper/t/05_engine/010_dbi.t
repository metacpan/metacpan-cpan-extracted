use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIx::ObjectMapper::Engine;
use DBIx::ObjectMapper::Engine::DBI;
use DBI;
use List::MoreUtils;
use DBIx::ObjectMapper::Log;
use Try::Tiny;

{ # basic
    check_interface('DBIx::ObjectMapper::Engine');
    check_interface('DBIx::ObjectMapper::Engine::DBI');
};

{ # dbi-sqlite
    dies_ok{ DBIx::ObjectMapper::Engine::DBI->new() };

    dies_ok{
        DBIx::ObjectMapper::Engine::DBI->new(
            'DBI:SQLite:', undef, undef,
            {
                on_connect_do => q{SOIAFOEOAWPFEWAPFEAW}
            }
        )->connect;
    };

    dies_ok{
        DBIx::ObjectMapper::Engine::DBI->new(
            'DBI:SQLite', undef, undef,
            {
                on_connect_do => q{SOIAFOEOAWPFEWAPFEAW}
            }
        )->connect;
    };

    ok my $dr = DBIx::ObjectMapper::Engine::DBI->new(
        [
            'DBI:SQLite:',
            undef,
            undef,
            {
                on_connect_do => [
                    q{CREATE TABLE test1 (id integer primary key, t text, key1 integer, key2 integer, UNIQUE(key1, key2) )},
                    q{CREATE TABLE test2 (id integer primary key )},
                    q{CREATE TABLE test3 (id integer primary key, test2_id integer REFERENCES test2(id) ) },
                    q{CREATE TABLE test4 (id integer primary key, test3_id integer, test3_test2_id integer, FOREIGN KEY(test3_id,test3_test2_id) REFERENCES test3(id,test2_id) )},
                ]
            },
        ]
    );
    ok $dr->dbh;
    is $dr->driver_type, 'SQLite';

    ok my $dr2 = DBIx::ObjectMapper::Engine::DBI->new({
        dsn => 'DBI:SQLite:',
        username => undef,
        password => undef,
        on_connect_do => [
            q{CREATE TABLE test1 (id integer primary key, t text)}
        ],
    });
    ok $dr2->dbh;
    is $dr2->driver_type, 'SQLite';

    # get_primary_key
    is_deeply [ $dr->get_primary_key('test1') ], [ 'id' ];

    # get_column_info
    my @columns = map{ $_->{name} } @{$dr->get_column_info('test1')};
    my %defind_columns = (
        id => 1,
        t => 1,
        key1 => 1,
        key2 => 1,
    );
    ok List::MoreUtils::all{ $defind_columns{$_} } @columns;

    # get_unique_key
    my @keys = @{$dr->get_unique_key('test1')->[0][1]};
    my %uniq_keys = ( key1 => 1, key2 => 1);
    ok List::MoreUtils::all{ $uniq_keys{$_} } @keys;

    # get_tables
    my @tables = $dr->get_tables;
    is_deeply(\@tables, [qw(test1 test2 test3 test4)]);

    # get_foreign_key
    is_deeply $dr->get_foreign_key('test1'), [];
    is_deeply $dr->get_foreign_key('test2'), [];
    is_deeply $dr->get_foreign_key('test3'), [
        {
            keys => ['test2_id'],
            refs => ['id'],
            table => 'test2',
        }
    ];
    is_deeply $dr->get_foreign_key('test4'), [
        {
            keys => ['test3_id', 'test3_test2_id'],
            refs => ['id', 'test2_id'],
            table => 'test3',
        }
    ];

    # insert
    is_deeply { id => 1, t => 'texttext', key1 => 1, key2 => 1 },
        $dr->insert(
        {   into   => 'test1',
            values => {
                t    => 'texttext',
                key1 => 1,
                key2 => 1,
            },
        },
        undef,
        ['id']
        ),
        'insert';

    # update
    ok $dr->update({
        table => 'test1',
        set => { key1 => 2, key2 => 2 },
        where => [ [ 'id', 1 ] ],
    });

    # select_single
    is_deeply [qw(1 texttext 2 2)], $dr->select_single({
        from => 'test1',
        where => [ [ 'id', 1 ] ],
    });

    # select
    my $it = $dr->select({
        from => 'test1',
        where => [ [ 'id', 1 ] ],
    });
    is_deeply [qw(1 texttext 2 2)], $it->next;
    $it = undef;

    # delele
    ok $dr->delete({ table => 'test1', where => [ [ 'id', 1 ]] });

    ok !$dr->select_single({
        from => 'test1',
        where => [ [ 'id', 1 ] ],
    });


    # transaction
    $dr->transaction(
        sub{
            my $res = $dr->insert(
                $dr->query->insert->into('test1')->values(
                    t => 'texttext2',
                    key1 => 3,
                    key2 => 3,
                ),
                ['id']
            )
        }
    );

    ok $dr->select_single({
        from => 'test1',
        where => [ [ 'id', 1 ] ],
    });


    # rollback
    try {
        $dr->transaction(
            sub{
                my $res2 = $dr->insert({
                    into   => 'test1',
                    values => {
                        t => 'texttext3',
                        key1 => 4,
                        key2 => 4,
                    },
                }, ['id']);
                die "died!";
            }
        );
    } catch {
        ok ~/died!/;
    };

    ok !$dr->select_single({
        from => 'test1',
        where => [ [ 'id', 2 ] ],
    });

    # txn_do
    ok my $transaction = $dr->transaction;
    is ref($transaction), 'DBIx::ObjectMapper::Engine::DBI::Transaction';
    $transaction = undef;

    $dr->transaction(
        sub{
            $dr->insert({
                into   => 'test1',
                values => {
                    t => 'texttext_txn_do',
                    key1 => 5,
                    key2 => 5,
                },
            },['id']);
            $dr->insert({
                into   => 'test1',
                values => {
                    t => 'texttext_txn_do',
                    key1 => 6,
                    key2 => 6,
                },
            }, ['id']);
        }
    );

    is_deeply [ [qw(2 5 5)], [qw(3 6 6)] ], [ $dr->select({
        column => [qw(id key1 key2)],
        from => 'test1',
        where => [ [ 't', 'texttext_txn_do' ] ],
    })->all ];


    # txn_do fail
    {
        local $@;
        try {
            $dr->transaction(
                sub{
                    $dr->delete({ table => 'test1', where => [ [ 'id', 1 ]] });
                    $dr->insert({
                        into   => 'test2',
                        values => {
                            t => 'texttext_txn_do_fail',
                            key1 => 7,
                            key2 => 7,
                        },
                    }, ['id']);
                }
            );
        } catch {
            ok $_, $_;
        };
    };

    ok $dr->select_single({
        from => 'test1',
        where => [ [ 'id', 1 ] ],
    });

    # disconnect
    is $dr->{_dbh_gen}, 1;
    $dr->disconnect;
    ok $dr->dbh;
    is $dr->{_dbh_gen}, 2;


    dies_ok{
        $dr->select_single({
            from => 'test_hogefuag',
            where => [ [ 'id', 1 ] ],
        });
    };

    dies_ok {
        $dr->select_single({
            from => 'test1',
            where => [ [ 'foo', 1 ] ],
        });
    };

};

sub check_interface {
    my $pkg = shift;
    for(
        'new',
        '_init',
        'transaction',
        'namesep',
        'driver',
        'quote',
        'iterator',
        'datetime_parser',
        'get_primary_key',
        'get_column_info',
        'get_unique_key',
        'get_tables',
        'select',
        'select_single',
        'update',
        'insert',
        'delete',
        'log',
    ) {
        ok $pkg->can($_), "$pkg can $_";
    }
}

done_testing;
