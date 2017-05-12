
use strict;
use warnings;

use Test::More tests => 24;

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
    skip($@, 24) if $@ && chomp $@;

    my ($tree, $childhash);
    ($tree, $childhash) = test_create_test_tree($dbh);

    $msg = 'add_children_at_left() should catch missing data';
    eval { $tree->add_children_at_left(); };
    like($@, qr/\bno\b .* \bdata\b/ix, $msg);

    $msg = 'add_children_at_left() should catch empty data list';
    eval { $tree->add_children_at_left([]); };
    like($@, qr/\binput\b .* \bempty\b/ix, $msg);

    $msg = 'add_children_at_left() should catch bad child data';
    eval { $tree->add_children_at_left(['I am not a HASHREF']); };
    like($@, qr/\bdata\b .* \bHASHREF\b/ix, $msg);

    $msg = 'add_children_at_left() should catch overwriting id column';
    eval { $tree->add_children_at_left([{name => 'Bob', id => 'some data'}]); };
    like($@, qr/\bdata\b .* \boverwrite\b .* \bcolumn\b/ix, $msg);

    $msg = 'add_children_at_left() should catch overwriting path column';
    eval {
        $tree->add_children_at_left([{name => 'Bob', path => 'some data'}]);
    };
    like($@, qr/\bdata\b .* \boverwrite\b .* \bcolumn\b/ix, $msg);

    $msg = 'add_children_at_left() should catch bad column name';
    eval {
        $tree->add_children_at_left({name => 'Bob', bad_col => 'some data'});
    };
    like($@, qr/\bdata\b .* \binvalid\b .* \bcolumn\b/ix, $msg);

    my $children;
    my $child;

    $children = $tree->add_children_at_left(
                                 [{name => '1'}, {name => '2'}, {name => '3'}]);

    $msg = 'correct number of nodes returned';
    is(scalar(@$children), 3, $msg);

    isa_ok($children->[0], 'DBIx::Tree::MaterializedPath::Node', 'child 1.1');
    isa_ok($children->[1], 'DBIx::Tree::MaterializedPath::Node', 'child 1.2');
    isa_ok($children->[2], 'DBIx::Tree::MaterializedPath::Node', 'child 1.3');

    is($children->[0]->{_path}, $tree->_map_path('1.1'),
        'child 1.1 path is ok');
    is($children->[1]->{_path}, $tree->_map_path('1.2'),
        'child 1.2 path is ok');
    is($children->[2]->{_path}, $tree->_map_path('1.3'),
        'child 1.3 path is ok');

    is($children->[0]->data->{name}, '1', 'child 1.1 data is ok');
    is($children->[1]->data->{name}, '2', 'child 1.2 data is ok');
    is($children->[2]->data->{name}, '3', 'child 1.3 data is ok');

    my $descendants;
    my $count;
    my $text;
    my $coderef = sub {
        my ($node, $parent) = @_;
        $count++;
        $text .= $node->data->{name};
    };

    $descendants = $tree->get_descendants();
    $count       = 0;
    $text        = '';
    $descendants->traverse($coderef);

    $msg = 'correct number of children added to root node';
    is($count, 9, $msg);

    $msg = 'correct node order after adding to root node';
    is($text, '123abcdfe', $msg);

    #####

    ($tree, $childhash) = test_create_test_tree($dbh);

    $child = $childhash->{'1.3'};

    $children = $child->add_children_at_left(
                                 [{name => '1'}, {name => '2'}, {name => '3'}]);

    $descendants = $tree->get_descendants();
    $count       = 0;
    $text        = '';
    $descendants->traverse($coderef);

    $msg = 'correct number of children added to deeper node';
    is($count, 9, $msg);

    $msg = 'correct node order after adding to deeper node';
    is($text, 'abc123dfe', $msg);

    #####

    ($tree, $childhash) = test_create_test_tree($dbh);

    $child = $childhash->{'1.2'};

    $children = $child->add_children_at_left(
                                 [{name => '1'}, {name => '2'}, {name => '3'}]);

    $descendants = $tree->get_descendants();
    $count       = 0;
    $text        = '';
    $descendants->traverse($coderef);

    $msg = 'correct number of children added to leaf node';
    is($count, 9, $msg);

    $msg = 'correct node order after adding to leaf node';
    is($text, 'ab123cdfe', $msg);

    #####

    ($tree, $childhash) = test_create_test_tree($dbh);

    $child = $childhash->{'1.3.2'};

    $children = $child->add_children_at_left(
                                 [{name => '1'}, {name => '2'}, {name => '3'}]);

    $descendants = $tree->get_descendants();
    $count       = 0;
    $text        = '';
    $descendants->traverse($coderef);

    $msg = 'correct number of children added to last node';
    is($count, 9, $msg);

    $msg = 'correct node order after adding to last node';
    is($text, 'abcdfe123', $msg);
}

