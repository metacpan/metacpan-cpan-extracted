use strict;
use warnings;

# Create the DBO (2 tests)
my $dbo;
use Test::DBO DBM => 'DBM', tests => 84, tempdir => 1, connect_ok => [\$dbo];

# In DBM there is no Schema
undef $Test::DBO::test_db;
undef $Test::DBO::test_sch;

# Make sure QuoteIdentifier is OFF for DBM (1 test)
is $dbo->config('QuoteIdentifier'), 0, 'Method $dbo->config';

# Table methods: do, select* (28 tests)
my $t = Test::DBO::basic_methods($dbo);

# Skip... (No tests)
Test::DBO::skip_advanced_table_methods($dbo, $t);

# Row methods: (20 tests)
Test::DBO::row_methods($dbo, $t);

# Query methods: (32 tests)
my $q = Test::DBO::query_methods($dbo, $t);

# Skip... (No tests)
Test::DBO::skip_advanced_query_methods($dbo, $t, $q);

END {
    # Cleanup (1 test)
    Test::DBO::cleanup($dbo);
}

