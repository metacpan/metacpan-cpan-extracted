
use strict;
use warnings;

use Test::More tests => 49;

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
    skip($@, 49) if $@ && chomp $@;

    my ($tree, $childhash) = test_create_test_tree($dbh);

    my $child;
    my $descendants;
    my $count;
    my $text;
    my $coderef;

    $descendants = $tree->get_descendants();

    $msg = 'traverse() should catch missing coderef';
    eval { $descendants->traverse() };
    like($@, qr/\bmissing\b .* \bcoderef\b/ix, $msg);

    $msg = 'traverse() should catch invalid coderef';
    eval { $descendants->traverse('I am not an CODEREF') };
    like($@, qr/\binvalid\b .* \bcoderef\b/ix, $msg);

    $msg     = 'Object in traverse()';
    $coderef = sub {
        my ($node, $parent) = @_;
        isa_ok($node, 'DBIx::Tree::MaterializedPath::Node', 'Traversed node');
        isa_ok($parent,
               'DBIx::Tree::MaterializedPath::Node',
               'Traversed parent');
        ok($parent->is_same_node_as($node->get_parent),
            'Node and parent are consistent');
    };

    $descendants->traverse($coderef);

    #####

    # This is *not* how you'd normally do it, just testing some
    # constructor error handling...

    my $foo = bless {}, 'Foo';

    my $column_names = [qw(id path name)];

    $msg = 'TreeRepresentation->new() should catch missing node';
    eval {
        $descendants = DBIx::Tree::MaterializedPath::TreeRepresentation->new();
    };
    like($@, qr/\bmissing\b .* \bnode\b/ix, $msg);

    $msg = 'TreeRepresentation->new() should catch invalid node';
    eval {
        $descendants =
          DBIx::Tree::MaterializedPath::TreeRepresentation->new({});
    };
    like($@, qr/\binvalid\b .* \bnode\b/ix, $msg);

    $msg = 'TreeRepresentation->new() should catch invalid node';
    eval {
        $descendants =
          DBIx::Tree::MaterializedPath::TreeRepresentation->new($foo);
    };
    like($@, qr/\binvalid\b .* \bnode\b/ix, $msg);

    $msg = 'TreeRepresentation->new() should catch missing column names';
    eval {
        $descendants =
          DBIx::Tree::MaterializedPath::TreeRepresentation->new($tree);
    };
    like($@, qr/\bmissing\b .* \bcolumn\b/ix, $msg);

    $msg = 'TreeRepresentation->new() should catch invalid column names';
    eval {
        $descendants =
          DBIx::Tree::MaterializedPath::TreeRepresentation->new($tree,
                                                          'I AM NOT A LISTREF');
    };
    like($@, qr/\binvalid\b .* \bcolumn\b/ix, $msg);

    $msg = 'TreeRepresentation->new() should catch missing rows';
    eval {
        $descendants =
          DBIx::Tree::MaterializedPath::TreeRepresentation->new($tree,
                                                                $column_names);
    };
    like($@, qr/\bmissing\b .* \brows\b/ix, $msg);

    $msg = 'TreeRepresentation->new() should catch invalid rows';
    eval {
        $descendants =
          DBIx::Tree::MaterializedPath::TreeRepresentation->new($tree,
                                           $column_names, 'I AM NOT A LISTREF');
    };
    like($@, qr/\binvalid\b .* \brows\b/ix, $msg);

    my $pm = DBIx::Tree::MaterializedPath::PathMapper->new();

    my $rows = [
                [2, $pm->map('1.1'), "a"],
                [3, $pm->map('1.2'), "b"],
                [4, $pm->map('1.3'), "c"],
               ];

    $msg = 'TreeRepresentation->new() should catch missing path column name';
    eval {
        $descendants =
          DBIx::Tree::MaterializedPath::TreeRepresentation->new($tree,
                                                         ['id', 'name'], $rows);
    };
    like($@, qr/\bpath\b .* \bnot\b .* \bfound\b/ix, $msg);

    $descendants = DBIx::Tree::MaterializedPath::TreeRepresentation->new($tree,
                                                          $column_names, $rows);

    $descendants->traverse($coderef);

    # ok, done mucking around...

    #####

    $descendants = $tree->get_descendants();

    $coderef = sub {
        my ($node, $parent) = @_;
        $count++;
        $text .= $node->data->{name};
    };

    $count = 0;
    $text  = '';
    $descendants->traverse($coderef);

    $msg = 'traverse() returns correct number of children for root node';
    is($count, 6, $msg);

    $msg = 'traverse() follows correct order for root node';
    is($text, 'abcdfe', $msg);

    $child       = $childhash->{'1.3'};
    $descendants = $child->get_descendants();
    $count       = 0;
    $text        = '';
    $descendants->traverse($coderef);

    $msg = 'traverse() returns correct number of children for deeper node';
    is($count, 3, $msg);

    $msg = 'traverse() follows correct order for deeper node';
    is($text, 'dfe', $msg);

    $child       = $childhash->{'1.3.1.1'};
    $descendants = $child->get_descendants();
    $count       = 0;
    $text        = '';
    $descendants->traverse($coderef);

    $msg = 'traverse() operates on no children for leaf node';
    is($count, 0, $msg);

    #####

    $msg = 'get_descendants() returns no data yet using delay_load';
    $descendants = $tree->get_descendants(delay_load => 1);

    $coderef = sub {
        my ($node, $parent) = @_;
        ok(!exists $node->{_data}, $msg);
    };

    $descendants->traverse($coderef);

    $msg = 'data now loaded using delay_load';

    $coderef = sub {
        my ($node, $parent) = @_;
        $text .= $node->data->{name};
    };

    $text = '';
    $descendants->traverse($coderef);

    is($text, 'abcdfe', $msg);
}

