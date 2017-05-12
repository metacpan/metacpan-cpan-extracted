## no critic (RCS,VERSION,encapsulation,Module)

use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIx::Connector;

BEGIN {
    use_ok( 'Class::User::DBI::DB', qw( db_run_ex %USER_QUERY %PRIV_QUERY ) );
}

# WARNING:  Tables will be dropped before and after running these tests.
#           Only run the tests against a test database containing no data
#           of value.
#           cud_privileges
#           By default, tests are run against an in-memory database. (safe)
# YOU HAVE BEEN WARNED.

# SQLite database settings.
my $dsn     = 'dbi:SQLite:dbname=:memory:';
my $db_user = q{};
my $db_pass = q{};

# mysql database settings.
# my $database = 'cudbi_test';
# my $dsn      = "dbi:mysql:database=$database";
# my $db_user  = 'tester';
# my $db_pass  = 'testers_pass';

my $conn = DBIx::Connector->new(
    $dsn, $db_user, $db_pass,
    {
        RaiseError => 1,
        AutoCommit => 1,
    }
);

can_ok( 'Class::User::DBI::DB', 'db_run_ex' );

dies_ok { db_run_ex() }
'db_run_ex(): Dies if not given a DBIx::Connector object.';
dies_ok { db_run_ex( bless {}, 'strangeness' ) }
'db_run_ex(): Dies if given an object that is not DBIx::Connector.';
dies_ok { db_run_ex('Strangeness') }
'db_run_ex(): Dies if parameter is not a DBIx::Connector object.';

ok(
    db_run_ex(
        $conn, 'CREATE TABLE mydbpm_test ( col1 VARCHAR(24) PRIMARY KEY )'
    ),
    'db_run_ex(): Connected to DB and created a test table.'
);

done_testing();

