
use strict;
use warnings;

use Test::More tests => 47;

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
    skip($@, 47) if $@ && chomp $@;

    test_initialize_empty_table($dbh);

    $tree = DBIx::Tree::MaterializedPath->new({dbh => $dbh});

    $msg = 'add_children() should catch missing data';
    eval { $tree->add_children(); };
    like($@, qr/\bno\b .* \bdata\b/ix, $msg);

    $msg = 'add_children() should catch empty data list';
    eval { $tree->add_children([]); };
    like($@, qr/\binput\b .* \bempty\b/ix, $msg);

    $msg = 'add_children() should catch bad child data';
    eval { $tree->add_children(['I am not a HASHREF']); };
    like($@, qr/\bdata\b .* \bHASHREF\b/ix, $msg);

    $msg = 'add_children() should catch overwriting id column';
    eval { $tree->add_children([{name => 'Bob', id => 'some data'}]); };
    like($@, qr/\bdata\b .* \boverwrite\b .* \bcolumn\b/ix, $msg);

    $msg = 'add_children() should catch overwriting path column';
    eval { $tree->add_children([{name => 'Bob', path => 'some data'}]); };
    like($@, qr/\bdata\b .* \boverwrite\b .* \bcolumn\b/ix, $msg);

    my $children =
      $tree->add_children([{name => 'a'}, {name => 'b'}, {name => 'c'}]);

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

    is($children->[0]->data->{name}, 'a', 'child 1.1 data is ok');
    is($children->[1]->data->{name}, 'b', 'child 1.2 data is ok');
    is($children->[2]->data->{name}, 'c', 'child 1.3 data is ok');

    $msg = 'add_children() should catch bad column name';
    eval { $tree->add_children({name => 'Bob', bad_col => 'some data'}); };
    like($@, qr/\bdata\b .* \binvalid\b .* \bcolumn\b/ix, $msg);

    my $child = $children->[2];
    $children = $child->add_children([{name => 'd'}, {name => 'e'}]);

    $msg = 'correct number of nodes returned';
    is(scalar(@$children), 2, $msg);

    isa_ok($children->[0], 'DBIx::Tree::MaterializedPath::Node', 'child 1.3.1');
    isa_ok($children->[1], 'DBIx::Tree::MaterializedPath::Node', 'child 1.3.2');

    $msg = 'child 1.3.1 path is ok';
    is($children->[0]->{_path}, $tree->_map_path('1.3.1'), $msg);
    $msg = 'child 1.3.2 path is ok';
    is($children->[1]->{_path}, $tree->_map_path('1.3.2'), $msg);

    is($children->[0]->data->{name}, 'd', 'child 1.3.1 data is ok');
    is($children->[1]->data->{name}, 'e', 'child 1.3.2 data is ok');

    $child = $children->[0];
    @$children = $child->add_child({name => 'f'});

    $msg = 'correct number of nodes returned';
    is(scalar(@$children), 1, $msg);

    isa_ok($children->[0],
           'DBIx::Tree::MaterializedPath::Node',
           'child 1.3.1.1');

    $msg = 'child 1.3.1.1 path is ok';
    is($children->[0]->{_path}, $tree->_map_path('1.3.1.1'), $msg);

    is($children->[0]->data->{name}, 'f', 'child 1.3.1.1 data is ok');

    #####

    test_initialize_empty_table($dbh);

    $tree = DBIx::Tree::MaterializedPath->new({dbh => $dbh});

    $msg = 'add_children() without existing transaction';
    $dbh->{AutoCommit} = 1;
    $children =
      $tree->add_children([{name => 'a'}, {name => 'b'}, {name => 'c'}]);
    is(scalar(@$children), 3, $msg);
    is(($dbh->{AutoCommit} ? 1 : 0), 1, $msg . ' (AutoCommit = 1)');

    $msg = 'add_children() with existing transaction';
    $dbh->begin_work;
    is(($dbh->{AutoCommit} ? 1 : 0), 0, $msg . ' (AutoCommit = 0)');
    $children =
      $tree->add_children([{name => 'a'}, {name => 'b'}, {name => 'c'}]);
    is(scalar(@$children), 3, $msg);
    is(($dbh->{AutoCommit} ? 1 : 0), 0, $msg . ' (AutoCommit = 0)');
    $dbh->commit;
    is(($dbh->{AutoCommit} ? 1 : 0), 1, $msg . ' (AutoCommit = 1)');

    $msg = 'add_children() with transactions disabled';
    $tree->{_can_do_transactions} = 0;
    $dbh->begin_work;
    is(($dbh->{AutoCommit} ? 1 : 0), 0, $msg . ' (AutoCommit = 0)');
    $children =
      $tree->add_children([{name => 'a'}, {name => 'b'}, {name => 'c'}]);
    is(scalar(@$children), 3, $msg);
    is(($dbh->{AutoCommit} ? 1 : 0), 0, $msg . ' (AutoCommit = 0)');
    $dbh->commit;
    is(($dbh->{AutoCommit} ? 1 : 0), 1, $msg . ' (AutoCommit = 1)');

    #####

    test_initialize_empty_table($dbh);

    $tree = DBIx::Tree::MaterializedPath->new({dbh => $dbh});

    $children = $tree->add_children({}, {}, {});

    $msg = 'empty children - correct number of nodes returned';
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

    is_deeply($children->[0]->data, {}, 'child 1.1 data is ok');
    is_deeply($children->[1]->data, {}, 'child 1.2 data is ok');
    is_deeply($children->[2]->data, {}, 'child 1.3 data is ok');
}

