use strict;
use warnings;
use Test::More;
use lib 't';
use Mock::Basic;
use Test::Requires {
    'DBD::SQLite' => undef,
};

    for my $logic ( qw(MySQLFoundRows PlusOne Count) ) {
        subtest $logic => sub {
            my $skinny;
            my ($dsn, $username, $password) = @ENV{map { "SKINNY_MYSQL_${_}" } qw/DSN USER PASS/};
            if ( $dsn && $username ) {
                $skinny = Mock::Basic->new({ dsn => $dsn, username => $username, password => $password });
                $skinny->setup_test_db;
            } else {
                if ( $logic eq "MySQLFoundRows" ) {
                    plan skip_all => 'Set $ENV{SKINNY_MYSQL_DSN}, _USER and _PASS to run this test', 1 unless ($dsn && $username);
                } else {
                    $skinny = Mock::Basic->new({ dsn => "dbi:SQLite:" });
                    $skinny->setup_test_db;
                }
            }
            my @insert_data;
            my $total_record = 15;
            my $counter = 0;
            while ( $counter < $total_record) {
                push @insert_data, +{ id => $counter + 1, name => $counter };
                $counter++;
            }
            $skinny->bulk_insert('mock_basic', \@insert_data);

            subtest "normal case" => sub {
                my $rs = $skinny->resultset_with_pager($logic, {
                    page => 1,
                    limit => 10,
                });
                isa_ok($rs, "DBIx::Skinny::Pager::Logic::$logic");
                $rs->from(['mock_basic']);
                $rs->select(['name']);
                my ($iter, $pager) = $rs->retrieve;

                if ( $logic eq "PlusOne" ) {
                    is($pager->total_entries, 10 + 1, "total_entries");
                } else {
                    is($pager->total_entries, $total_record, "total_entries");
                }
                is($pager->current_page, 1, "current_page");
                is($pager->entries_per_page, 10, "entries_per_page");
                is($iter->count, 10, "iterator item count");
                my $last_row;
                while ( my $row = $iter->next ) {
                    $last_row = $row;
                }
                is($last_row->name, 10 - 1, "last item name");

                done_testing;
            };

            subtest 'with where' => sub {
                my $rs = $skinny->resultset_with_pager($logic, {
                    page => 4,
                    limit => 3,
                });
                isa_ok($rs, "DBIx::Skinny::Pager::Logic::$logic");
                $rs->from(['mock_basic']);
                $rs->add_where(name => { '<' => 10 });
                $rs->select(['name']);
                my ($iter, $pager) = $rs->retrieve;

                if ( $logic eq "PlusOne" ) {
                    is($pager->total_entries, 3 * (3 + 1) + 0, "total_entries");
                } else {
                    is($pager->total_entries, 10, "total_entries");
                }
                is($pager->current_page, 4, "current_page");
                is($pager->entries_per_page, 3, "entries_per_page");
                is($iter->count, 1, "iterator item count");
                my $last_row;
                while ( my $row = $iter->next ) {
                    $last_row = $row;
                }
                is($last_row->name, 9, "last item name");

                done_testing;
            };

            subtest "with group by" => sub {
                my $rs = $skinny->resultset_with_pager($logic, {
                    page => 1,
                    limit => 10,
                });
                isa_ok($rs, "DBIx::Skinny::Pager::Logic::$logic");
                $rs->from(['mock_basic']);
                $rs->group({ column => 'id' });
                $rs->select(['name']);
                my ($iter, $pager) = $rs->retrieve;

                if ( $logic eq "PlusOne" ) {
                    is($pager->total_entries, 10 + 1, "total_entries");
                } else {
                    is($pager->total_entries, $total_record, "total_entries");
                }
                is($pager->current_page, 1, "current_page");
                is($pager->entries_per_page, 10, "entries_per_page");
                is($iter->count, 10, "iterator item count");
                my $last_row;
                while ( my $row = $iter->next ) {
                    $last_row = $row;
                }
                is($last_row->name, 10 - 1, "last item name");

                done_testing;
            };

            subtest "with resultset" => sub {
                my $rs = $skinny->resultset_with_pager($logic, {
                    page => 1,
                    limit => 10,
                });
                $rs->from(['mock_basic']);
                $rs->group({ column => 'id' });
                $rs->select(['name']);
                my $resultset = $rs->retrieve;
                isa_ok($resultset, "DBIx::Skinny::Pager::ResultSet");
                isa_ok($resultset->pager, "Data::Page");
                isa_ok($resultset->iterator, "DBIx::Skinny::Iterator");

                done_testing;
            };

            subtest 'with page to string' => sub {
                local $SIG{__WARN__} = sub {}; # XXX: What you want to do is not understood. 
                my $rs = $skinny->resultset_with_pager($logic, {
                    page => 'aiueo',
                    limit => 10,
                });
                $rs->from(['mock_basic']);
                $rs->group({ column => 'id' });
                $rs->select(['name']);
                my $resultset = $rs->retrieve;
                isa_ok($resultset, "DBIx::Skinny::Pager::ResultSet");
                isa_ok($resultset->pager, "Data::Page");
                isa_ok($resultset->iterator, "DBIx::Skinny::Iterator");

                done_testing;
            };

            $skinny->cleanup_test_db;
            done_testing;
        };

    }

done_testing();

