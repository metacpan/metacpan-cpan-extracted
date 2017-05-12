use Test::More tests => 11;
use Test::Exception;

use FindBin;
use DBI;
use Getopt::Config::FromPod;

Getopt::Config::FromPod->set_class_default(-file => "$FindBin::Bin/../bin/dbiloader");

use_ok 'App::DBI::Loader';

lives_ok { App::DBI::Loader->run('dbi:DBM:', 'test', '(id INTEGER PRIMARY KEY, value INTEGER)', "$FindBin::Bin/dat.csv"); } 'load with default';

{
    my $dbh = DBI->connect('dbi:DBM:', '', '');
    is($dbh->selectrow_arrayref('SELECT value FROM test WHERE id = 5')->[0], 80, 'lookup');
}

lives_ok { App::DBI::Loader->run('-c', '-t', '\t', 'dbi:DBM:', 'test', "$FindBin::Bin/dat.tsv"); } 'load with -t and -c';

{
    my $dbh = DBI->connect('dbi:DBM:', '', '');
    is($dbh->selectrow_arrayref('SELECT value FROM test WHERE id = 5')->[0], 20, 'lookup');
}

lives_ok { App::DBI::Loader->run('-t', '\\\\s+', 'dbi:DBM:', 'test', "$FindBin::Bin/dat.ssv"); } 'append with -t';

{
    my $dbh = DBI->connect('dbi:DBM:', '', '');
    is($dbh->selectrow_arrayref('SELECT value FROM test WHERE id = 4')->[0], 50, 'lookup1');
    is($dbh->selectrow_arrayref('SELECT value FROM test WHERE id = 5')->[0], 20, 'lookup2');
}

lives_ok { App::DBI::Loader->run('-c', '-t', '\\\\s+', 'dbi:DBM:', 'test', "$FindBin::Bin/dat.tsv", "$FindBin::Bin/dat.ssv"); } 'load multiple with -t and -c';

{
    my $dbh = DBI->connect('dbi:DBM:', '', '');
    is($dbh->selectrow_arrayref('SELECT value FROM test WHERE id = 4')->[0], 50, 'lookup1');
    is($dbh->selectrow_arrayref('SELECT value FROM test WHERE id = 5')->[0], 20, 'lookup2');
}

# cleanup 

END {
    my $dbh = DBI->connect('dbi:DBM:', '', '');
    $dbh->do('DROP TABLE test');
}
