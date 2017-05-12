
use strict;
use warnings;

use Test::More tests => 26;

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
    skip($@, 26) if $@ && chomp $@;

    my ($tree,  $childhash);
    my ($node1, $node2);

    my $descendants;
    my $count;
    my $text;
    my $path;
    my $coderef = sub {
        my ($node, $parent) = @_;
        $count++;
        $text .= $node->data->{name};
        $path .= ' ' . $node->{_root}->{_pathmapper}->unmap($node->{_path});
    };

    #####

    ($tree, $childhash) = test_create_test_tree($dbh);

    my $foo = bless {}, 'Foo';

    $msg = 'swap_node() should catch missing data';
    eval { $tree->swap_node(); };
    like($@, qr/\bmissing\b .* \bnode\b/ix, $msg);

    $msg = 'swap_node() should catch invalid node';
    eval { $tree->swap_node('I am not a node'); };
    like($@, qr/\binvalid\b .* \bnode\b/ix, $msg);

    $msg = 'swap_node() should catch invalid node';
    eval { $tree->swap_node($foo); };
    like($@, qr/\binvalid\b .* \bnode\b/ix, $msg);

    $msg = 'Can\'t swap_node() root with another node';
    eval { $tree->swap_node($childhash->{'1.3.2'}); };
    like($@, qr/\broot\b/ix, $msg);

    $msg = 'Can\'t swap_node() another node with root';
    eval { $childhash->{'1.3.2'}->swap_node($tree); };
    like($@, qr/\broot\b/ix, $msg);

    $node1 = $childhash->{'1.1'};
    $node2 = $childhash->{'1.3'};

    $msg = 'swap_node() with itself is a no-op';
    $node1->swap_node($node1);
    is($node1->{_path}, $tree->_map_path('1.1'), $msg);

    $node1->swap_node($node2);

    $msg = 'swap_node() swaps paths';
    is($node1->{_path}, $tree->_map_path('1.3'), $msg);
    is($node2->{_path}, $tree->_map_path('1.1'), $msg);

    $msg = 'swap_node() data stays with node';
    is($node1->data->{name}, 'a', $msg);
    is($node2->data->{name}, 'c', $msg);

    $descendants = $tree->get_descendants();
    $count       = 0;
    $text        = '';
    $path        = '';
    $descendants->traverse($coderef);

    $msg = 'swap_node() maintains other tree data';
    is($text, 'cbadfe', $msg);
    is($path, ' 1.1 1.2 1.3 1.3.1 1.3.1.1 1.3.2', $msg);

    #####

    ($tree, $childhash) = test_create_test_tree($dbh);

    $msg = 'swap_subtree() should catch missing data';
    eval { $tree->swap_subtree(); };
    like($@, qr/\bmissing\b .* \bnode\b/ix, $msg);

    $msg = 'swap_subtree() should catch invalid node';
    eval { $tree->swap_subtree('I am not a node'); };
    like($@, qr/\binvalid\b .* \bnode\b/ix, $msg);

    $msg = 'swap_subtree() should catch invalid node';
    eval { $tree->swap_subtree($foo); };
    like($@, qr/\binvalid\b .* \bnode\b/ix, $msg);

    $msg = 'Can\'t swap_subtree() root with another node';
    eval { $tree->swap_subtree($childhash->{'1.3'}); };
    like($@, qr/\broot\b/ix, $msg);

    $msg = 'Can\'t swap_subtree() another node with root';
    eval { $childhash->{'1.3'}->swap_subtree($tree); };
    like($@, qr/\broot\b/ix, $msg);

    $msg = 'Can\'t swap_subtree() with ancestor';
    eval { $childhash->{'1.3.1'}->swap_subtree($childhash->{'1.3'}); };
    like($@, qr/\bancestor\b/ix, $msg);

    $msg = 'Can\'t swap_subtree() with descendant';
    eval { $childhash->{'1.3'}->swap_subtree($childhash->{'1.3.1'}); };
    like($@, qr/\bdescendant\b/ix, $msg);

    $node1 = $childhash->{'1.1'};
    $node2 = $childhash->{'1.3'};

    $msg = 'swap_subtree() with itself is a no-op';
    $node1->swap_subtree($node1);
    is($node1->{_path}, $tree->_map_path('1.1'), $msg);

    $node1->swap_subtree($node2);

    $msg = 'swap_subtree() swaps paths';
    is($node1->{_path}, $tree->_map_path('1.3'), $msg);
    is($node2->{_path}, $tree->_map_path('1.1'), $msg);

    $msg = 'swap_subtree() data stays with node';
    is($node1->data->{name}, 'a', $msg);
    is($node2->data->{name}, 'c', $msg);

    $descendants = $tree->get_descendants();
    $count       = 0;
    $text        = '';
    $path        = '';
    $descendants->traverse($coderef);

    $msg = 'swap_subtrees() updates subtree data';
    is($text, 'cdfeba', $msg);
    is($path, ' 1.1 1.1.1 1.1.1.1 1.1.2 1.2 1.3', $msg);
}

