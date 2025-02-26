use 5.014;
use warnings;

# Create the DBO
my $dbo;
use lib '.';
use Test::DBO DBM => 'DBM', tests => '+1', tempdir => 1, connect_ok => [\$dbo];

# In DBM there is no Schema
undef $Test::DBO::test_db;
undef $Test::DBO::test_sch;

# Make sure QuoteIdentifier is OFF for DBM (1 test)
is $dbo->config('QuoteIdentifier'), 0, 'Method $dbo->config';

my $t = Test::DBO::basic_methods($dbo);
Test::DBO::skip_advanced_table_methods($dbo, $t);
Test::DBO::row_methods($dbo, $t);
my $q = Test::DBO::query_methods($dbo, $t);
Test::DBO::skip_advanced_query_methods($dbo, $t, $q);
Test::DBO::skip_join_methods($dbo);

END {
    Test::DBO::cleanup($dbo);
}

