
use strict;
use warnings;

use Test::More tests => 29;

BEGIN
{
    chdir 't' if -d 't';
    use File::Spec;
    my $testlib = File::Spec->catfile('testlib', 'testutils.pm');
    require $testlib;

    use_ok('DBIx::Tree::MaterializedPath');
}

my $tree;
my $node;
my $msg;

$msg = 'new() should catch missing $dbh';
eval { $tree = DBIx::Tree::MaterializedPath->new() };
like($@, qr/\bmissing\b.*\bdbh\b/i, $msg);

$msg = 'new() should catch invalid $dbh (options hashref)';
eval { $tree = DBIx::Tree::MaterializedPath->new({dbh => 1}) };
like($@, qr/\binvalid\b.*\bdbh\b/i, $msg);

$msg = 'new() should catch invalid $dbh (options list)';
eval { $tree = DBIx::Tree::MaterializedPath->new(dbh => 1) };
like($@, qr/\binvalid\b.*\bdbh\b/i, $msg);

SKIP:
{
    my $dbh;
    eval { $dbh = test_get_dbh() };
    skip($@, (29 - 4)) if $@ && chomp $@;

    # Start with empty DB:
    test_drop_table($dbh, 'my_tree');
    test_drop_table($dbh, 'other_tree');

    $msg = 'new() should catch missing database table';
    eval { $tree = DBIx::Tree::MaterializedPath->new({dbh => $dbh}); };
    like($@, qr/\btable\b .* \bmy_tree\b .* \bexist\b/ix, $msg);

    $msg = 'new() should use "table_name" if supplied (options hashref)';
    eval {
        $tree = DBIx::Tree::MaterializedPath->new(
                                     {dbh => $dbh, table_name => 'other_tree'});
    };
    like($@, qr/\btable\b .* \bother_tree\b .* \bexist\b/ix, $msg);

    $msg = 'new() should use "table_name" if supplied (options list)';
    eval {
        $tree =
          DBIx::Tree::MaterializedPath->new(dbh        => $dbh,
                                            table_name => 'other_tree');
    };
    like($@, qr/\btable\b .* \bother_tree\b .* \bexist\b/ix, $msg);

    test_initialize_empty_table($dbh);

    $msg = 'new() should use "id_column_name" if supplied';
    eval {
        $tree = DBIx::Tree::MaterializedPath->new(
                                   {dbh => $dbh, id_column_name => 'other_id'});
    };
    like($@, qr/\bcolumn\b .* \bother_id\b .* \bexist\b/ix, $msg);

    $msg = 'new() should use "path_column_name" if supplied';
    eval {
        $tree = DBIx::Tree::MaterializedPath->new(
                               {dbh => $dbh, path_column_name => 'other_path'});
    };
    like($@, qr/\bcolumn\b .* \bother_path\b .* \bexist\b/ix, $msg);

    $msg = 'new() should catch missing root node in database';
    eval {
        $tree = DBIx::Tree::MaterializedPath->new(
                                          {dbh => $dbh, auto_create_root => 0});
    };
    like($@, qr/No row /, $msg);

    $msg = 'new() should create missing root node in database';
    $tree = DBIx::Tree::MaterializedPath->new({dbh => $dbh});
    isa_ok($tree, 'DBIx::Tree::MaterializedPath', $msg);

    $msg = 'new() should find existing root node in database';
    $tree = DBIx::Tree::MaterializedPath->new({dbh => $dbh});
    isa_ok($tree, 'DBIx::Tree::MaterializedPath', $msg);

    $msg = 'new() as object method';
    my $new_tree = $tree->new({dbh => $dbh});
    isa_ok($new_tree, 'DBIx::Tree::MaterializedPath', $msg);
    is_deeply($tree, $new_tree, $msg . ' produces deep copy');

    #####

    $msg = 'Node->new() should catch missing root';
    eval { $node = DBIx::Tree::MaterializedPath::Node->new() };
    like($@, qr/\bmissing\b.*\broot\b/i, $msg);

    $msg = 'Node->new() should catch invalid root';
    eval { $node = DBIx::Tree::MaterializedPath::Node->new(1) };
    like($@, qr/\binvalid\b.*\broot\b/i, $msg);

    $msg = 'Node->new() should catch invalid root';
    my $foo = bless {}, 'Foo';
    eval { $node = DBIx::Tree::MaterializedPath::Node->new($foo) };
    like($@, qr/\binvalid\b.*\broot\b/i, $msg);

    $msg  = 'Node->new()';
    $node = DBIx::Tree::MaterializedPath::Node->new($tree);
    isa_ok($node, 'DBIx::Tree::MaterializedPath::Node', $msg);

    $msg = 'Node->new() with options hashref';
    $node = DBIx::Tree::MaterializedPath::Node->new($tree, {foo => 1});
    isa_ok($node, 'DBIx::Tree::MaterializedPath::Node', $msg);

    $msg = 'Node->new() with options list';
    $node = DBIx::Tree::MaterializedPath::Node->new($tree, 'foo' => 1);
    isa_ok($node, 'DBIx::Tree::MaterializedPath::Node', $msg);

    $msg = 'Node->new() as object method';
    my $new_node = $node->new($tree);
    isa_ok($new_node, 'DBIx::Tree::MaterializedPath::Node', $msg);
    is_deeply($node, $new_node, $msg . ' produces deep copy');

    #####

    $msg               = 'new() without existing transaction';
    $dbh->{AutoCommit} = 1;
    $tree              = DBIx::Tree::MaterializedPath->new({dbh => $dbh});
    is($tree->{_can_do_transactions}, 1, $msg . ' (can do transactions)');
    is(($dbh->{AutoCommit} ? 1 : 0), 1, $msg . ' (AutoCommit = 1)');

    $msg = 'new() with existing transaction';
    $dbh->begin_work;
    is(($dbh->{AutoCommit} ? 1 : 0), 0, $msg . ' (AutoCommit = 0)');
    $tree = DBIx::Tree::MaterializedPath->new({dbh => $dbh});
    is($tree->{_can_do_transactions}, 1, $msg . ' (can do transactions)');
    is(($dbh->{AutoCommit} ? 1 : 0), 0, $msg . ' (AutoCommit = 0)');
    $dbh->commit;
    is(($dbh->{AutoCommit} ? 1 : 0), 1, $msg . ' (AutoCommit = 1)');

    #####

    $msg = '_do_transaction() with bad code';
    eval {
        $tree->_do_transaction(sub { die 'BADNESS' });
    };
    like($@, qr/^BADNESS at /, $msg);
}

