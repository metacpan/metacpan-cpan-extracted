
use strict;
use warnings;

use Test::More tests => 7;

use DBIx::Tree::MaterializedPath;

BEGIN
{
    chdir 't' if -d 't';
    use File::Spec;
    my $testlib = File::Spec->catfile('testlib', 'testutils.pm');
    require $testlib;
}

my $msg;

SKIP:
{
    my $dbh;
    eval { $dbh = test_get_dbh() };
    skip($@, 7) if $@ && chomp $@;

    my ($tree, $childhash) = test_create_test_tree($dbh);

    my $descendants;
    my $child;

    #####

    $descendants = $tree->get_descendants();

    $msg = 'Object returned by get_descendants()';
    isa_ok($descendants, 'DBIx::Tree::MaterializedPath::TreeRepresentation',
           $msg);

    $msg = 'num_nodes() returns correct number of descendants for root node';
    ok($descendants->has_nodes, $msg);
    is($descendants->num_nodes, 6, $msg);

    #####

    $child = $childhash->{'1.3'};

    $msg = 'num_nodes() returns correct number of children for child node';
    $descendants = $child->get_descendants();
    ok($descendants->has_nodes, $msg);
    is($descendants->num_nodes, 3, $msg);

    #####

    $child = $childhash->{'1.3.2'};

    $msg         = 'num_nodes() returns no children for leaf node';
    $descendants = $child->get_descendants();
    ok(!$descendants->has_nodes, $msg);
    is($descendants->num_nodes, 0, $msg);
}

