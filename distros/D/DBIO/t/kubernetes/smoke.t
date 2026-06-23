use strict;
use warnings;
use Test::More;

plan skip_all => 'Set DBIO_TEST_KUBECONFIG to enable Kubernetes smoke tests'
    unless $ENV{DBIO_TEST_KUBECONFIG} || $ENV{KUBECONFIG};

# This test verifies the Kubernetes test infrastructure works by:
# 1. Connecting to each provisioned database
# 2. Running a simple SELECT 1

my @tests;

if ($ENV{DBIO_TEST_PG_DSN}) {
    push @tests, {
        name => 'PostgreSQL',
        dsn  => $ENV{DBIO_TEST_PG_DSN},
        user => $ENV{DBIO_TEST_PG_USER},
        pass => $ENV{DBIO_TEST_PG_PASS},
    };
}

if ($ENV{DBIO_TEST_MYSQL_DSN}) {
    push @tests, {
        name => 'MySQL',
        dsn  => $ENV{DBIO_TEST_MYSQL_DSN},
        user => $ENV{DBIO_TEST_MYSQL_USER},
        pass => $ENV{DBIO_TEST_MYSQL_PASS},
    };
}

plan skip_all => 'No database DSN env vars set (run via maint/k8s-test)'
    unless @tests;

plan tests => scalar @tests * 2;

require DBI;

for my $t (@tests) {
    my $dbh = eval {
        DBI->connect($t->{dsn}, $t->{user}, $t->{pass}, {
            RaiseError => 1,
            PrintError => 0,
        });
    };

    ok($dbh, "$t->{name}: connected successfully")
        or diag("Connection failed: " . ($@ || DBI->errstr));

    SKIP: {
        skip "$t->{name}: no connection", 1 unless $dbh;

        my ($result) = $dbh->selectrow_array('SELECT 1');
        is($result, 1, "$t->{name}: SELECT 1 returns 1");

        $dbh->disconnect;
    }
}
