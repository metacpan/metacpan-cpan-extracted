use 5.014;
use warnings;

# Allow the use of ORACLE_USERID or DBO_TEST_ORACLE_USER
BEGIN {
    $ENV{DBO_TEST_ORACLE_USER} = $ENV{ORACLE_USERID}
        if exists $ENV{ORACLE_USERID} and not exists $ENV{DBO_TEST_ORACLE_USER};
}

my $dbo;
use lib '.';
use Test::DBO Oracle => 'Oracle', tests => '+0', connect_ok => [\$dbo];

# Use the default Schema
undef $Test::DBO::test_db;
undef $Test::DBO::test_sch;
$Test::DBO::case_sensitivity_sql = 'SELECT COUNT(*) FROM DUAL WHERE ? LIKE ?';
$Test::DBO::can{truncate} = 1;

my $t = Test::DBO::basic_methods($dbo);
Test::DBO::advanced_table_methods($dbo, $t);
Test::DBO::row_methods($dbo, $t);
my $q = Test::DBO::query_methods($dbo, $t);
Test::DBO::advanced_query_methods($dbo, $t, $q);
Test::DBO::join_methods($dbo, $t->{Name});

END {
    Test::DBO::cleanup($dbo) if $dbo;
}

