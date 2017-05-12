
use strict;
use warnings;

use Test::More tests => 28;

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
    skip($@, 28) if $@ && chomp $@;

    my ($tree, $childhash) = test_create_test_tree($dbh);

    my $foo = bless {}, 'Foo';

    $msg = 'is_ancestor_of() should catch missing node';
    eval { $tree->is_ancestor_of() };
    like($@, qr/\bmissing\b .* \bnode\b/ix, $msg);

    $msg = 'is_ancestor_of() should catch invalid node';
    eval { $tree->is_ancestor_of('I am not an node') };
    like($@, qr/\binvalid\b .* \bnode\b/ix, $msg);

    $msg = 'is_ancestor_of() should catch invalid node';
    eval { $tree->is_ancestor_of($foo) };
    like($@, qr/\binvalid\b .* \bnode\b/ix, $msg);

    $msg = 'is_descendant_of() should catch missing node';
    eval { $tree->is_descendant_of() };
    like($@, qr/\bmissing\b .* \bnode\b/ix, $msg);

    $msg = 'is_descendant_of() should catch invalid node';
    eval { $tree->is_descendant_of('I am not an node') };
    like($@, qr/\binvalid\b .* \bnode\b/ix, $msg);

    $msg = 'is_descendant_of() should catch invalid node';
    eval { $tree->is_descendant_of($foo) };
    like($@, qr/\binvalid\b .* \bnode\b/ix, $msg);

    #####

    $msg = 'root ! is_ancestor_of() self';
    ok(!$tree->is_ancestor_of($tree), $msg);

    $msg = 'root is_ancestor_of() depth-1 child';
    ok($tree->is_ancestor_of($childhash->{'1.3'}), $msg);

    $msg = 'root is_ancestor_of() depth-2 child';
    ok($tree->is_ancestor_of($childhash->{'1.3.1'}), $msg);

    $msg = 'root is_ancestor_of() depth-3 child';
    ok($tree->is_ancestor_of($childhash->{'1.3.1.1'}), $msg);

    #####

    $msg = 'depth-1 child ! is_ancestor_of() root';
    ok(!$childhash->{'1.2'}->is_ancestor_of($tree), $msg);

    $msg = 'depth-1 child ! is_ancestor_of() self';
    ok(!$childhash->{'1.2'}->is_ancestor_of($childhash->{'1.2'}), $msg);

    $msg = 'depth-1 child ! is_ancestor_of() sibling';
    ok(!$childhash->{'1.2'}->is_ancestor_of($childhash->{'1.3'}), $msg);

    $msg = 'depth-1 child ! is_ancestor_of() sibling depth-2 child';
    ok(!$childhash->{'1.2'}->is_ancestor_of($childhash->{'1.3.1'}), $msg);

    $msg = 'depth-1 child is_ancestor_of() depth-2 child';
    ok($childhash->{'1.3'}->is_ancestor_of($childhash->{'1.3.1'}), $msg);

    $msg = 'depth-1 child is_ancestor_of() depth-3 child';
    ok($childhash->{'1.3'}->is_ancestor_of($childhash->{'1.3.1.1'}), $msg);

    $msg = 'depth-2 child is_ancestor_of() depth-3 child';
    ok($childhash->{'1.3.1'}->is_ancestor_of($childhash->{'1.3.1.1'}), $msg);

    #####

    $msg = 'root ! is_descendant_of() self';
    ok(!$tree->is_descendant_of($tree), $msg);

    $msg = 'root ! is_descendant_of() depth-1 child';
    ok(!$tree->is_descendant_of($childhash->{'1.3'}), $msg);

    $msg = 'root ! is_descendant_of() depth-2 child';
    ok(!$tree->is_descendant_of($childhash->{'1.3.1'}), $msg);

    $msg = 'root ! is_descendant_of() depth-3 child';
    ok(!$tree->is_descendant_of($childhash->{'1.3.1.1'}), $msg);

    #####

    $msg = 'depth-1 child is_descendant_of() root';
    ok($childhash->{'1.2'}->is_descendant_of($tree), $msg);

    $msg = 'depth-1 child ! is_descendant_of() self';
    ok(!$childhash->{'1.2'}->is_descendant_of($childhash->{'1.2'}), $msg);

    $msg = 'depth-1 child ! is_descendant_of() sibling';
    ok(!$childhash->{'1.2'}->is_descendant_of($childhash->{'1.3'}), $msg);

    $msg = 'depth-2 child ! is_descendant_of() parent depth-1 sibling';
    ok(!$childhash->{'1.3.1'}->is_descendant_of($childhash->{'1.2'}), $msg);

    $msg = 'depth-3 child is_descendant_of() depth-1 child';
    ok($childhash->{'1.3.1.1'}->is_descendant_of($childhash->{'1.3'}), $msg);

    $msg = 'depth-3 child is_descendant_of() depth-2 child';
    ok($childhash->{'1.3.1.1'}->is_descendant_of($childhash->{'1.3.1'}), $msg);

    $msg = 'depth-2 child is_descendant_of() depth-1 child';
    ok($childhash->{'1.3.1'}->is_descendant_of($childhash->{'1.3'}), $msg);
}

