#!/usr/bin/perl

use lib qw(t/lib);
use strict;
use warnings;

use Test2::Bundle::More;
use Test2::Tools::Compare;
use Test2::Tools::Exception;
use Test2::Tools::Explain;

use DBI;
use DBIx::Connector::Retry;

use Path::Class 'file';

my $root = file(__FILE__)->dir->parent;
my $db_file = $root->file('t', 'test.db');

############################################################

sub _connector {
    my @extra_args = @_;

    my %args = ( AutoCommit => 1, RaiseError => 1, PrintError => 0 );
    my @conn = $ENV{DBITEST_DSN} ?
        ( (map { $ENV{"DBITEST_${_}"} || '' } qw/DSN DBUSER DBPASS/), \%args ) :
        ( "dbi:SQLite:dbname=$db_file", '', '', \%args )
    ;

    my $conn = DBIx::Connector::Retry->new( connect_info => \@conn, @extra_args );

    # Create a very basic table
    my $dbh = $conn->dbh;
    $dbh->do("DROP TABLE IF EXISTS dbi_test");
    $dbh->do("CREATE TABLE dbi_test ( a VARCHAR(100) )");

    return $conn;
}

# Outside exception handler check
$SIG{__DIE__} = sub {
    fail "Outside exception handler didn't catch the DBI error";
    die $_[0];
};

############################################################

subtest 'No retries' => sub {
    # Constructor
    my $retries = 0;
    my $conn = _connector(
        retry_handler => sub { $retries++; 1 },
        retry_debug   => 0,
        max_attempts  => 1,
    );

    try_ok {
        $conn->run(ping => sub {
            my $dbh = shift;
            $dbh->do('INSERT INTO dbi_test (a) VALUES ("foobar")') for (1 .. 50);
            is($conn->execute_method, 'run', 'Inter-sub execute_method is correct');
        });
    } 'Run is successful';

    my ($row_count) = $conn->dbh->selectrow_array('SELECT COUNT(*) FROM dbi_test');
    is($conn->execute_method, '', 'Post-run execute_method is blank');
    cmp_ok($row_count, '==', 50, 'Row counts are as expected');
    cmp_ok($retries,   '==',  0, 'No retries');
};

subtest 'Super flaky connection' => sub {
    # Constructor
    my $retries = 0;
    my $conn = _connector(
        retry_handler => sub { $retries++; 1 },
        retry_debug   => 0,
        max_attempts  => 20,
    );

    my $i = 0;

    no warnings 'redefine';
    my $orig_exec_sub = \&DBIx::Connector::_exec;
    local *DBIx::Connector::_exec = sub {
        my ($dbh, $code, $wantarray) = @_;
        $i++;
        $dbh->disconnect if $i % 5;  # silently disconnect 4 out of 5 times
        $orig_exec_sub->(@_);
    };

    try_ok {
        # silence 'rollback ineffective with AutoCommit enabled' warnings
        local $SIG{__WARN__} = sub {};

        $conn->txn(ping => sub {
            my $dbh = shift;
            $dbh->do('INSERT INTO dbi_test (a) VALUES ("foobar")') for (1 .. 50);
            is($conn->execute_method, 'txn', 'Inter-sub execute_method is correct');
        });
    } 'Run is successful';

    my ($row_count) = $conn->dbh->selectrow_array('SELECT COUNT(*) FROM dbi_test');
    is($conn->execute_method, '', 'Post-run execute_method is blank');
    cmp_ok($row_count, '==', 50, 'Row counts are as expected');
    cmp_ok($retries,   '==',  4, 'Some retries');
};

my $nested_i = 0;
sub _nested_main_block {
    my ($dbh, $conn) = @_;
    $nested_i++;
    die 'Your sneedles are gootched' if $nested_i % 5;  # silently die 4 out of 5 times

    $dbh->do('INSERT INTO dbi_test (a) VALUES ("foobar")') for (1 .. 50);
    is($conn->execute_method, 'run', 'Nested inter-sub execute_method is correct');
}

subtest 'Nesting blocks' => sub {
    # Constructor
    my $retries = 0;
    my $conn = _connector(
        retry_handler => sub { $retries++; 1 },
        retry_debug   => 0,
        max_attempts  => 20,
    );

    try_ok {
        for (1..5) {
            $conn->txn(ping => sub {
                $conn->run(ping => sub { _nested_main_block($_, $conn) });
                is($conn->execute_method, 'txn', 'Inter-sub execute_method is correct');
            });
        }
    } 'Run is successful';

    my ($row_count) = $conn->dbh->selectrow_array('SELECT COUNT(*) FROM dbi_test');
    is($conn->execute_method, '', 'Post-run execute_method is blank');
    cmp_ok($row_count, '==', 250, 'Row counts are as expected');
    cmp_ok($retries,   '==',  20, 'Some retries');
};

############################################################

unlink $db_file if -e $db_file;

done_testing;
