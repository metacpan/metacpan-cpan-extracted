
use strict;
use warnings;

use Test::More tests => 4;

use DBIx::Tree::MaterializedPath;

BEGIN
{
    chdir 't' if -d 't';
    use File::Spec;
    my $testlib = File::Spec->catfile('testlib', 'testutils.pm');
    require $testlib;
}

my $tree;
my $msg;

SKIP:
{
    my $dbh;
    eval { $dbh = test_get_dbh() };
    skip($@, 4) if $@ && chomp $@;

    my ($tree, $childhash) = test_create_test_tree($dbh);

    $msg = 'depth() returns 0 for root';
    is($tree->depth(), 0, $msg);

    $msg = 'depth() returns 1 for depth-1 child';
    is($childhash->{'1.3'}->depth(), 1, $msg);

    $msg = 'depth() returns 2 for depth-2 child';
    is($childhash->{'1.3.1'}->depth(), 2, $msg);

    $msg = 'depth() returns 3 for depth-3 child';
    is($childhash->{'1.3.1.1'}->depth(), 3, $msg);
}

