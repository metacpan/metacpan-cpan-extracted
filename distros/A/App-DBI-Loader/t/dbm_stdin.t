use Test::More tests => 9;

use FindBin;
use DBI;
use Getopt::Config::FromPod;

Getopt::Config::FromPod->set_class_default(-file => "$FindBin::Bin/../bin/dbiloader");

use_ok 'App::DBI::Loader';

my $parent = 1;

sub execute
{
    pipe(FROM_PARENT, TO_CHILD);
    my $pid = fork;
    die "fork failed: $!" if ! defined($pid);
    if($pid) {
        close FROM_PARENT;
        open my $fh, '<', $_[1];
        local $/;
        my $dat = <$fh>;
        close $fh;
        print TO_CHILD $dat;
        close TO_CHILD;
        waitpid $pid, 0;
    } else {
        $parent = 0;
        close TO_CHILD;
        # Need to close first, at least, on Win32
        close STDIN;
        open STDIN, "<&FROM_PARENT";
        App::DBI::Loader->run(@{$_[0]});
        close FROM_PARENT;
        exit;
    }
}

# fork inside lives_ok may fail in Win32
execute(['dbi:DBM:', 'test', '(id INTEGER PRIMARY KEY, value INTEGER)', '-'], "$FindBin::Bin/dat.csv");

{
    my $dbh = DBI->connect('dbi:DBM:', '', '');
    is($dbh->selectrow_arrayref('SELECT value FROM test WHERE id = 5')->[0], 80, 'lookup');
}

execute(['-c', '-t', '\t', 'dbi:DBM:', 'test'], "$FindBin::Bin/dat.tsv");

{
    my $dbh = DBI->connect('dbi:DBM:', '', '');
    is($dbh->selectrow_arrayref('SELECT value FROM test WHERE id = 5')->[0], 20, 'lookup');
}

execute(['-t', '\\\\s+', 'dbi:DBM:', 'test', '-'], "$FindBin::Bin/dat.ssv");

{
    my $dbh = DBI->connect('dbi:DBM:', '', '');
    is($dbh->selectrow_arrayref('SELECT value FROM test WHERE id = 4')->[0], 50, 'lookup1');
    is($dbh->selectrow_arrayref('SELECT value FROM test WHERE id = 5')->[0], 20, 'lookup2');
}

execute(['-c', '-t', '\\\\s+', 'dbi:DBM:', 'test', "$FindBin::Bin/dat.tsv", '-'], "$FindBin::Bin/dat.ssv");

{
    my $dbh = DBI->connect('dbi:DBM:', '', '');
    is($dbh->selectrow_arrayref('SELECT value FROM test WHERE id = 4')->[0], 50, 'lookup1');
    is($dbh->selectrow_arrayref('SELECT value FROM test WHERE id = 5')->[0], 20, 'lookup2');
}

execute(['-c', '-t', '\\\\s+', 'dbi:DBM:', 'test', '-', "$FindBin::Bin/dat.ssv", '-'], "$FindBin::Bin/dat.tsv");

{
    my $dbh = DBI->connect('dbi:DBM:', '', '');
    is($dbh->selectrow_arrayref('SELECT value FROM test WHERE id = 4')->[0], 50, 'lookup1');
    is($dbh->selectrow_arrayref('SELECT value FROM test WHERE id = 5')->[0], 20, 'lookup2');
}

# cleanup

END {
    if($parent) {
        my $dbh = DBI->connect('dbi:DBM:', '', '');
        $dbh->do('DROP TABLE test');
    }
}
