use strict;
use warnings;
use Test::More;
use lib 't';
use Mock::Basic;
use Test::Requires {
    'DBD::SQLite' => undef,
};

for my $logic ( qw/ MySQLFoundRows PlusOne Count / ) {
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
            push @insert_data, +{ name => $counter };
            $counter++;
        }
        $skinny->bulk_insert('mock_basic', \@insert_data);

        my ($iter, $pager) = $skinny->search_with_pager(mock_basic => {
            name => { '<' => 20 },
        }, {
            pager_logic => $logic,
            page => 2,
            limit => 5,
        });

        is($pager->current_page, 2, "current page");
        is($pager->entries_per_page, 5, "entries_per_page");
        if ( $logic eq "PlusOne" ) {
            is($pager->total_entries, 11, "total entries");
        } else {
            is($pager->total_entries, 15, "total entries");
        }
        is($iter->count, 5, "iter should have 5 items");

        done_testing;
        $skinny->cleanup_test_db;

    };
}

done_testing;

