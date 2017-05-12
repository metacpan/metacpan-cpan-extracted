use strict;
use warnings;
use lib 't/lib';
use DBIx::ThinSQL ':all';
use Test::DBIx::ThinSQL qw/run_in_tempdir/;
use Test::Fatal qw/exception/;
use Test::More;

plan skip_all => 'only test with DBD::SQLite'
  unless eval { require DBD::SQLite };

# now let's make a database check our syntax
run_in_tempdir {

    my $driver = eval { require DBD::SQLite } ? 'SQLite' : 'DBM';

    # DBD::DBM doesn't seem to support this style of construction
  SKIP: {
        skip 'DBD::DBM limitation', 1 if $driver eq 'DBM';

        my $db = DBI->connect(
            "dbi:$driver:dbname=x",
            '', '',
            {
                RaiseError => 1,
                PrintError => 0,
                RootClass  => 'DBIx::ThinSQL',
            },
        );

        isa_ok $db, 'DBIx::ThinSQL::db';
    }

    my $db =
      DBIx::ThinSQL->connect( "dbi:$driver:dbname=x'", '', '',
        { RaiseError => 1, PrintError => 0, },
      );

    isa_ok $db, 'DBIx::ThinSQL::db';

    $db->do("CREATE TABLE users ( name TEXT PRIMARY KEY, phone TEXT )");
    my $res;
    my @res;

    $res = $db->xdo(
        insert_into => 'users',
        values      => [ 'name1', bv('phone1') ],
    );
    is $res, 1, 'xdo insert 1';

    $res = $db->xdo(
        insert_into => 'users',
        values      => [ bv('name2'), 'phone4' ],
    );
    is $res, 1, 'xdo insert 2';

    $res = $db->xdo(
        insert_into => 'users',
        values      => [ 'name3', 'phone3' ],
    );
    is $res, 1, 'xdo insert 3';

    $res = $db->xdo(
        delete_from => 'users',
        where       => [ 'name = ', bv('name3') ],
    );
    is $res, 1, 'xdo delete 3';

    $res = $db->xdo(
        update => 'users',
        set    => [ 'phone = ', bv('phone2') ],
        where  => [ 'name = ', bv('name2') ],
    );
    is $res, 1, 'xdo update 2';

    $db->xdo(
        insert_into => 'users',
        values      => [ 'name5', 'phone5' ],
    );

    $res = $db->xdo(
        update => 'users',
        set    => { 'phone' => 'xxx' },
        where  => { 'name !' => [ 'name1', 'name2' ] },
    );

    $res = $db->xval(
        select => [qw/phone/],
        from   => 'users',
        where  => { name => 'name5' },
    );

    is $res, 'xxx', '! / NOT';

    $res = $db->xdo(
        delete_from => 'users',
        where       => [ 'name = ', bv('name5') ],
    );

    subtest 'xval', sub {
        $res = $db->xval(
            select   => [qw/name phone/],
            from     => 'users',
            order_by => 'name desc',
        );

        is $res, 'name2', 'xval';
    };

    subtest 'xlist', sub {
        @res = $db->xlist(
            select   => [qw/name phone/],
            from     => 'users',
            order_by => 'name desc',
        );

        is_deeply \@res, [ 'name2', 'phone2' ], 'xlist';

        @res = $db->xlist(
            select => [qw/name phone/],
            from   => 'users',
            where  => 'name IS NULL',
        );
        is_deeply \@res, [], 'xlist null';
    };

    subtest 'xarrayref', sub {
        $res = $db->xarrayref(
            select   => 'name, phone',
            from     => 'users',
            order_by => 'name',
        );

        is_deeply $res, [ 'name1', 'phone1' ], 'xarrayref scalar';

        $res = $db->xarrayref(
            select => 'name, phone',
            from   => 'users',
            where  => 'name IS NULL',
        );

        is_deeply $res, undef, 'xarrayref scalar undef';

        is_deeply \@res, [], 'list undef';
    };

    subtest 'xarrayrefs', sub {
      SKIP: {
            skip 'DBD::DBM limitation', 1 if $driver eq 'DBM';
            $res = $db->xarrayrefs(
                select   => [qw/name phone/],
                from     => 'users',
                group_by => [qw/name phone/],
                order_by => 'name asc',
            );

            is_deeply $res,
              [ [qw/name1 phone1/], [qw/name2 phone2/] ],
              'xarrayrefs scalar';
        }

        $res = $db->xarrayrefs(
            select => [qw/name phone/],
            from   => 'users',
            where  => 'name IS NULL',
        );

        is_deeply $res, undef, 'xarrayrefs scalar undef';

        @res = $db->xarrayrefs(
            select   => [qw/name phone/],
            from     => 'users',
            order_by => 'name desc',
        );

        is_deeply \@res, [ [qw/name2 phone2/], [qw/name1 phone1/] ],
          'xarrayrefs list';

        @res = $db->xarrayrefs(
            select => [qw/name phone/],
            from   => 'users',
            where  => 'name IS NULL',
        );

        is_deeply \@res, [], 'xarrayrefs list undef';

    };

    subtest 'xhashref', sub {
        $res = $db->xhashref(
            select   => [qw/name phone/],
            from     => 'users',
            order_by => 'name desc',
        );

        is_deeply $res, { name => 'name2', phone => 'phone2' },
          'xhashref scalar';

        $res = $db->xhashref(
            select => [qw/name phone/],
            from   => 'users',
            where  => 'name IS NULL',
        );

        is_deeply $res, undef, 'xhashref scalar undef';

    };

    subtest 'xhashrefs', sub {
        $res = $db->xhashrefs(
            select   => [qw/name phone/],
            from     => 'users',
            order_by => 'name asc',
        );

        is_deeply $res,
          [
            { name => 'name1', phone => 'phone1', },
            { name => 'name2', phone => 'phone2', },
          ],
          'xhashrefs scalar';

        $res = $db->xhashrefs(
            select => [qw/name phone/],
            from   => 'users',
            where  => 'name IS NULL',
        );

        is_deeply $res, [], 'xhashrefs scalar undef';

        @res = $db->xhashrefs(
            select   => [qw/name phone/],
            from     => 'users',
            order_by => 'name desc',
        );

        is_deeply \@res,
          [
            { name => 'name2', phone => 'phone2' },
            { name => 'name1', phone => 'phone1' },
          ],
          'xhashrefs list';

        @res = $db->xhashrefs(
            select => [qw/name phone/],
            from   => 'users',
            where  => 'name IS NULL',
        );

        is_deeply \@res, [], 'xhashrefs list undef';
    };

  SKIP: {
        skip 'DBD::DBM limitation', 2 if $driver eq 'DBM';
        $res = $db->xdo(
            insert_into => 'users(name, phone)',
            select      => [ qv('name3'), qv('phone3') ],
        );
        is $res, 1, 'insert into select';

        $res = $db->xarrayrefs(
            select => [qw/name phone/],
            from   => 'users',
            where  => [ 'phone = ', bv('phone3'), 'OR name = ', qv('name2') ],
            order_by => [ 'phone', 'name' ],
        );

        is_deeply $res, [ [qw/name2 phone2/], [qw/name3 phone3/] ], 'where';
    }

    $res = $db->xdo(
        insert_into => 'users',
        values      => { name => 'name4', phone => 'phone4' },
    );
    is $res, 1, 'insert using hashref';

    $res = $db->xval(
        select => 'subquery.col',
        from   => sq( select => '3 AS col', )->as('subquery'),
    );
    is $res, 3, 'sq';

    $db->do('DELETE FROM users');

  SKIP: {
        skip 'DBD::DBM limitation', 1 if ( $driver eq 'DBM' );
        subtest 'txn', sub {
            $res = undef;
            ok $db->{AutoCommit}, 'have autocommit';

            $db->txn(
                sub {
                    ok !$db->{AutoCommit}, 'no autocommit in txn';
                    $res = 1;
                }
            );

            ok $db->{AutoCommit}, 'have autocommit';
            is $res, 1, 'sub ran in txn()';

            $res = undef;
            like exception {
                $db->txn(
                    sub {
                        die 'WTF';
                    }
                );
                die "WRONG";
            }, qr/WTF/, 'correct exception propagated';

            is $db->{private_DBIx_ThinSQL_txn}, 0, 'txn 0';

            $res = $db->txn(
                sub {
                    $db->txn(
                        sub {
                            $db->xdo(
                                insert_into => 'users',
                                values      => {
                                    name  => 'name1',
                                    phone => 'phone1'
                                },
                            );

                            $res = $db->xarrayrefs(
                                select => [qw/name phone/],
                                from   => 'users',
                            );
                        }
                    );
                }
            );

            is_deeply $res, [ [qw/name1 phone1/] ], 'nested txn';
            is $db->{private_DBIx_ThinSQL_txn}, 0, 'txn 0';

            my $err;
            @res = $db->txn(
                sub {
                    eval {
                        $db->txn(
                            sub {
                                $db->xdo(
                                    insert_into => 'users',
                                    values      => {
                                        name  => 'name1',
                                        phone => 'phone1'
                                    },
                                );
                            }
                        );
                    };

                    $err = $@;

                    $db->xdo(
                        insert_into => 'users',
                        values      => { name => 'name2', phone => 'phone2' },
                    );

                    return $db->xarrayrefs(
                        select   => [qw/name phone/],
                        from     => 'users',
                        order_by => 'name',
                    );
                }
            );

            ok $err, 'know that duplicate insert failed';
            is_deeply \@res,
              [ [qw/name1 phone1/], [qw/name2 phone2/] ],
              'nested txn/svp';
            is $db->{private_DBIx_ThinSQL_txn}, 0, 'txn 0';

        };

        $db->disconnect;

    }
};

done_testing();
