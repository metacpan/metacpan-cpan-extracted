use strict;
use warnings;

# Allow the use of ORACLE_USERID or DBO_TEST_ORACLE_USER
BEGIN {
    $ENV{DBO_TEST_ORACLE_USER} = $ENV{ORACLE_USERID}
        if exists $ENV{ORACLE_USERID} and not exists $ENV{DBO_TEST_ORACLE_USER};
}
# Create the DBO (2 tests)
my $dbo;
use Test::DBO Oracle => 'Oracle', tests => 112, connect_ok => [\$dbo];

# Use the default Schema
undef $Test::DBO::test_db;
undef $Test::DBO::test_sch;
$Test::DBO::case_sensitivity_sql = 'SELECT COUNT(*) FROM DUAL WHERE ? LIKE ?';
$Test::DBO::can{truncate} = 1;

# Table methods: do, select* (28 tests)
my $t = Test::DBO::basic_methods($dbo);

# Advanced table methods: insert, update, delete (2 tests)
Test::DBO::advanced_table_methods($dbo, $t);

# Row methods: (20 tests)
Test::DBO::row_methods($dbo, $t);

# Query methods: (32 tests)
my $q = Test::DBO::query_methods($dbo, $t);

# Advanced query methods: (15 tests)
Test::DBO::advanced_query_methods($dbo, $t, $q);

# Join methods: (12 tests)
Test::DBO::join_methods($dbo, $t->{Name});

END {
    # Cleanup (1 test)
    Test::DBO::cleanup($dbo) if $dbo;
}

