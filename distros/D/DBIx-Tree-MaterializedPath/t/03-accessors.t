
use strict;
use warnings;

use Test::More tests => 13;

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
    skip($@, 13) if $@ && chomp $@;

    test_drop_table($dbh);
    test_initialize_empty_table($dbh);

    $tree = DBIx::Tree::MaterializedPath->new({dbh => $dbh});

    my $root_node_path = $tree->_map_path('1');

    is($tree->_id, 1, 'Get _id()');
    is($tree->_path, $root_node_path, "Get _path() (Don't do this!)");

    is($tree->table_name, 'my_tree', 'Get table_name');

    # NOTE: Application code should never mess with _path()!
    my $dbpath = $tree->_map_path('1.1');
    $tree->_path($dbpath);
    is($tree->_path, $dbpath, "Set _path() (Don't do this!)");

    $msg = 'Set data() should catch invalid data';
    eval { $tree->data('I am not a HASHREF'); };
    like($@, qr/\bdata\b .* \bHASHREF\b/ix, $msg);

    $msg = 'Set data() should catch empty data hash';
    eval { $tree->data({}); };
    like($@, qr/\bdata\b .* \bempty\b/ix, $msg);

    $msg = 'Set data() should catch overwriting id column';
    eval { $tree->data({name => 'Bob', id => 'some data'}); };
    like($@, qr/\bdata\b .* \boverwrite\b .* \bcolumn\b/ix, $msg);

    $msg = 'Set data() should catch overwriting path column';
    eval { $tree->data({name => 'Bob', path => 'some data'}); };
    like($@, qr/\bdata\b .* \boverwrite\b .* \bcolumn\b/ix, $msg);

    $msg = 'Set data() should catch bad column name';
    eval { $tree->data({name => 'Bob', bad_col => 'some data'}); };
    like($@, qr/\bdata\b .* \binvalid\b .* \bcolumn\b/ix, $msg);

    $tree->data({name => 'new name'});
    is($tree->data->{name}, 'new name', 'Set data()');

    is($tree->data->{name}, 'new name', 'Get data()');

    # Change name in DB:
    test_update_node_name($dbh, $tree->_path, 'a different name');

    # Node data should not have changed yet:
    is($tree->data->{name}, 'new name', 'Get data() after DB change');

    # Refresh node data with DB data:
    $tree->refresh_data();
    is($tree->data->{name},
        'a different name',
        'Get data() after refresh_data()');
}

