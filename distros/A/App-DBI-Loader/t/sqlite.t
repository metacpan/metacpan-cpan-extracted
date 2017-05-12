use Test::More;
use Test::Exception;

use FindBin;
use DBI;
use Getopt::Config::FromPod;

eval { require DBD::SQLite; };
plan skip_all => "DBD::SQLite required for testing: $@" if $@;

Getopt::Config::FromPod->set_class_default(-file => "$FindBin::Bin/../bin/dbiloader");

plan tests => 9;

use_ok 'App::DBI::Loader';

lives_ok { App::DBI::Loader->run('dbi:SQLite:test.db', 'test', '(id INTEGER PRIMARY KEY, name TEXT, value INTEGER)', "$FindBin::Bin/dat2.csv"); } 'load with default';

{
    my $dbh = DBI->connect('dbi:SQLite:test.db', '', '');
    is($dbh->selectrow_arrayref('SELECT SUM(value) FROM test')->[0], 160, 'sum');
    is($dbh->selectrow_arrayref('SELECT COUNT(*) FROM test')->[0], 3, 'count');
    is($dbh->selectrow_arrayref('SELECT name FROM test WHERE value = 30')->[0], 'tenth', 'lookup');
}

lives_ok { App::DBI::Loader->run('-t', '\t', 'dbi:SQLite:test.db', 'test', "$FindBin::Bin/dat2.tsv"); } 'load with -t';

{
    my $dbh = DBI->connect('dbi:SQLite:test.db', '', '');
    is($dbh->selectrow_arrayref('SELECT SUM(value) FROM test')->[0], 250, 'sum');
    is($dbh->selectrow_arrayref('SELECT COUNT(*) FROM test')->[0], 7, 'count');
    is($dbh->selectrow_arrayref('SELECT value FROM test WHERE name = "fourth"')->[0], 10, 'lookup');
}

# cleanup 
END {
    unlink 'test.db';
}
