use 5.014;
use warnings;

my $dbo;
use lib '.';
use Test::DBO SQLite => 'SQLite', tests => '+0', tempdir => 1, connect_ok => [\$dbo];

# In SQLite there is no Schema
undef $Test::DBO::test_db;
undef $Test::DBO::test_sch;
$Test::DBO::can{collate} = 'BINARY';
$Test::DBO::can{auto_increment_id} = 'INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT';

my $t = Test::DBO::basic_methods($dbo);
Test::DBO::advanced_table_methods($dbo, $t);
Test::DBO::row_methods($dbo, $t);
my $q = Test::DBO::query_methods($dbo, $t);
Test::DBO::advanced_query_methods($dbo, $t, $q);
Test::DBO::join_methods($dbo, $t->{Name}, 1);

END {
    Test::DBO::cleanup($dbo) if $dbo;
}

