
use strict;
use warnings;

use Test::More tests => 12;

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
    skip($@, 12) if $@ && chomp $@;

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

    #####

    ($tree, $childhash) = test_create_test_tree($dbh);

    $childhash->{'1.1'}->delete_descendants();

    $descendants = $tree->get_descendants();
    $count       = 0;
    $text        = '';
    $path        = '';
    $descendants->traverse($coderef);

    $msg = 'delete_descendants() for depth-1 leaf node';
    is($text, 'abcdfe', $msg);
    is($path, ' 1.1 1.2 1.3 1.3.1 1.3.1.1 1.3.2', $msg);

    #####

    ($tree, $childhash) = test_create_test_tree($dbh);

    $childhash->{'1.3.2'}->delete_descendants();

    $descendants = $tree->get_descendants();
    $count       = 0;
    $text        = '';
    $path        = '';
    $descendants->traverse($coderef);

    $msg = 'delete_descendants() for depth-2 leaf node';
    is($text, 'abcdfe', $msg);
    is($path, ' 1.1 1.2 1.3 1.3.1 1.3.1.1 1.3.2', $msg);

    #####

    ($tree, $childhash) = test_create_test_tree($dbh);

    $childhash->{'1.3.1.1'}->delete_descendants();

    $descendants = $tree->get_descendants();
    $count       = 0;
    $text        = '';
    $path        = '';
    $descendants->traverse($coderef);

    $msg = 'delete_descendants() for depth-3 leaf node';
    is($text, 'abcdfe', $msg);
    is($path, ' 1.1 1.2 1.3 1.3.1 1.3.1.1 1.3.2', $msg);

    #####

    ($tree, $childhash) = test_create_test_tree($dbh);

    $childhash->{'1.3.1'}->delete_descendants();

    $descendants = $tree->get_descendants();
    $count       = 0;
    $text        = '';
    $path        = '';
    $descendants->traverse($coderef);

    $msg = 'delete_descendants() for depth-2 node';
    is($text, 'abcde', $msg);
    is($path, ' 1.1 1.2 1.3 1.3.1 1.3.2', $msg);

    #####

    ($tree, $childhash) = test_create_test_tree($dbh);

    $childhash->{'1.3'}->delete_descendants();

    $descendants = $tree->get_descendants();
    $count       = 0;
    $text        = '';
    $path        = '';
    $descendants->traverse($coderef);

    $msg = 'delete_descendants() for depth-1 node';
    is($text, 'abc',          $msg);
    is($path, ' 1.1 1.2 1.3', $msg);

    #####

    ($tree, $childhash) = test_create_test_tree($dbh);

    $tree->delete_descendants();

    $descendants = $tree->get_descendants();
    $count       = 0;
    $text        = '';
    $path        = '';
    $descendants->traverse($coderef);

    $msg = 'delete_descendants() for root node';
    is($text, '', $msg);
    is($path, '', $msg);
}

