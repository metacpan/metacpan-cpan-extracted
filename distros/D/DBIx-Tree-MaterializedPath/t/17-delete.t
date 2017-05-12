
use strict;
use warnings;

use Test::More tests => 11;

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
    skip($@, 11) if $@ && chomp $@;

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

    my ($tree, $childhash);
    my $node;

    #####

    ($tree, $childhash) = test_create_test_tree($dbh);

    $msg = 'Can\'t delete root node';
    eval { $tree->delete; };
    like($@, qr/\broot\b/ix, $msg);

    #####

    ($tree, $childhash) = test_create_test_tree($dbh);

    $node = '1.1';
    $childhash->{$node}->delete();

    $descendants = $tree->get_descendants();
    $count       = 0;
    $text        = '';
    $path        = '';
    $descendants->traverse($coderef);

    $msg = "delete() for depth-1 leaf node ($node)";
    is($text, 'bcdfe', $msg);
    is($path, ' 1.1 1.2 1.2.1 1.2.1.1 1.2.2', $msg);

    #####

    ($tree, $childhash) = test_create_test_tree($dbh);

    $node = '1.3.2';
    $childhash->{$node}->delete();

    $descendants = $tree->get_descendants();
    $count       = 0;
    $text        = '';
    $path        = '';
    $descendants->traverse($coderef);

    $msg = "delete() for depth-2 leaf node ($node)";
    is($text, 'abcdf', $msg);
    is($path, ' 1.1 1.2 1.3 1.3.1 1.3.1.1', $msg);

    #####

    ($tree, $childhash) = test_create_test_tree($dbh);

    $node = '1.3.1.1';
    $childhash->{$node}->delete();

    $descendants = $tree->get_descendants();
    $count       = 0;
    $text        = '';
    $path        = '';
    $descendants->traverse($coderef);

    $msg = "delete() for depth-3 leaf node ($node)";
    is($text, 'abcde', $msg);
    is($path, ' 1.1 1.2 1.3 1.3.1 1.3.2', $msg);

    #####

    ($tree, $childhash) = test_create_test_tree($dbh);

    $node = '1.3.1';
    $childhash->{$node}->delete();

    $descendants = $tree->get_descendants();
    $count       = 0;
    $text        = '';
    $path        = '';
    $descendants->traverse($coderef);

    $msg = "delete() for depth-2 node ($node)";
    is($text, 'abce', $msg);
    is($path, ' 1.1 1.2 1.3 1.3.1', $msg);

    #####

    ($tree, $childhash) = test_create_test_tree($dbh);

    $node = '1.3';
    $childhash->{$node}->delete();

    $descendants = $tree->get_descendants();
    $count       = 0;
    $text        = '';
    $path        = '';
    $descendants->traverse($coderef);

    $msg = "delete() for depth-1 node ($node)";
    is($text, 'ab',       $msg);
    is($path, ' 1.1 1.2', $msg);
}

