
use strict;
use warnings;

use Test::More tests => 77;

BEGIN
{
    chdir 't' if -d 't';
    use File::Spec;
    my $testlib = File::Spec->catfile('testlib', 'testutils.pm');
    require $testlib;

    use_ok('DBIx::Tree::MaterializedPath::PathMapper');
}

my $msg;

$msg = 'new()';
my $mapper = DBIx::Tree::MaterializedPath::PathMapper->new();
isa_ok($mapper, 'DBIx::Tree::MaterializedPath::PathMapper', $msg);

$msg = 'new() as object method';
my $new_mapper = $mapper->new();
isa_ok($new_mapper, 'DBIx::Tree::MaterializedPath::PathMapper', $msg);
is_deeply($mapper, $new_mapper, $msg . ' produces deep copy');

my $path_1 = '1';
$msg = qq{map/unmap is consistent for "$path_1"};
my $dbpath_1 = $mapper->map($path_1);
is($mapper->unmap($dbpath_1), $path_1, $msg);
$msg = qq{depth for "$path_1"};
is($mapper->depth($dbpath_1), 0, $msg);
$msg = qq{is_root for "$path_1"};
is($mapper->is_root($dbpath_1), 1, $msg);

my $path_1_17 = '1.17';
$msg = qq{map/unmap is consistent for "$path_1_17"};
my $dbpath_1_17 = $mapper->map($path_1_17);
is($mapper->unmap($dbpath_1_17), $path_1_17, $msg);
$msg = qq{depth for "$path_1_17"};
is($mapper->depth($dbpath_1_17), 1, $msg);
$msg = qq{is_root for "$path_1_17"};
is($mapper->is_root($dbpath_1_17), 0, $msg);

my $path_1_17_2 = '1.17.2';
$msg = qq{map/unmap is consistent for "$path_1_17_2"};
my $dbpath_1_17_2 = $mapper->map($path_1_17_2);
is($mapper->unmap($dbpath_1_17_2), $path_1_17_2, $msg);
$msg = qq{depth for "$path_1_17_2"};
is($mapper->depth($dbpath_1_17_2), 2, $msg);
$msg = qq{is_root for "$path_1_17_2"};
is($mapper->is_root($dbpath_1_17_2), 0, $msg);

#####

$msg = qq{parent path for "$path_1"};
is($mapper->parent_path($dbpath_1), '', $msg);

$msg = qq{parent path for "$path_1_17"};
is($mapper->parent_path($dbpath_1_17), $dbpath_1, $msg);

$msg = qq{parent path for "$path_1_17_2"};
is($mapper->parent_path($dbpath_1_17_2), $dbpath_1_17, $msg);

#####

my ($sql, @bind_params);

$msg = qq{parent where for "$path_1"};
($sql, @bind_params) = $mapper->parent_where('path', $dbpath_1);
is($sql,                 undef, $msg . ' (sql)');
is(scalar(@bind_params), 1,     $msg . ' (number of bind params)');
is($bind_params[0],      undef, $msg . ' (correct bind params)');

$msg = qq{parent where for "$path_1_17"};
($sql, @bind_params) = $mapper->parent_where('path', $dbpath_1_17);
is($sql, ' WHERE ( path = ? )', $msg . ' (sql)');
is(scalar(@bind_params), 1,         $msg . ' (number of bind params)');
is($bind_params[0],      $dbpath_1, $msg . ' (correct bind params)');

$msg = qq{parent where for "$path_1_17_2"};
($sql, @bind_params) = $mapper->parent_where('path', $dbpath_1_17_2);
is($sql, ' WHERE ( path = ? )', $msg . ' (sql)');
is(scalar(@bind_params), 1,            $msg . ' (number of bind params)');
is($bind_params[0],      $dbpath_1_17, $msg . ' (correct bind params)');

$msg = qq{where};
($sql, @bind_params) = $mapper->where({'path' => $dbpath_1_17});
is($sql, ' WHERE ( path = ? )', $msg . ' (sql)');
is(scalar(@bind_params), 1,            $msg . ' (number of bind params)');
is($bind_params[0],      $dbpath_1_17, $msg . ' (correct bind params)');

#####

$msg = qq{path for "$path_1" sorts less than path for "$path_1_17"};
cmp_ok($dbpath_1, 'lt', $dbpath_1_17, $msg);

$msg = qq{path for "$path_1_17" sorts less than path for "$path_1_17_2"};
cmp_ok($dbpath_1_17, 'lt', $dbpath_1_17_2, $msg);

my $path_1_271   = '1.271';
my $dbpath_1_271 = $mapper->map($path_1_271);
$msg = qq{path for "$path_1_17_2" sorts less than path for "$path_1_271"};
cmp_ok($dbpath_1_17_2, 'lt', $dbpath_1_271, $msg);

#####

my $path;
my $nextpath;

$path     = '1.3.5.7';
$nextpath = '1.3.5.8';
$msg      = "next child after $path is $nextpath";
is($mapper->next_child_path($mapper->map($path)), $mapper->map($nextpath),
    $msg);

$path     = '1.1';
$nextpath = '1.2';
$msg      = "next child after $path is $nextpath";
is($mapper->next_child_path($mapper->map($path)), $mapper->map($nextpath),
    $msg);

$path     = '1.1';
$nextpath = '1.5';
$msg      = "4th next child after $path is $nextpath";
is($mapper->next_child_path($mapper->map($path), 4),
    $mapper->map($nextpath), $msg);

$path     = '1';
$nextpath = '';
$msg      = "next child after $path is empty";
is($mapper->next_child_path($mapper->map($path)), $nextpath, $msg);

#####

$path     = '1.3.5';
$nextpath = '1.3.5.1';
$msg      = "first child of $path is $nextpath";
is($mapper->first_child_path($mapper->map($path)),
    $mapper->map($nextpath), $msg);

$path     = '1';
$nextpath = '1.1';
$msg      = "first child of $path is $nextpath";
is($mapper->first_child_path($mapper->map($path)),
    $mapper->map($nextpath), $msg);

#####

$msg = 'is_ancestor_of() should catch missing path';
eval { $mapper->is_ancestor_of() };
like($@, qr/\bmissing\b .* \bpath\b/ix, $msg);

$msg = 'is_ancestor_of() should catch missing path';
eval { $mapper->is_ancestor_of($path) };
like($@, qr/\bmissing\b .* \bpath\b/ix, $msg);

$msg = 'is_descendant_of() should catch missing path';
eval { $mapper->is_descendant_of() };
like($@, qr/\bmissing\b .* \bpath\b/ix, $msg);

$msg = 'is_descendant_of() should catch missing path';
eval { $mapper->is_descendant_of($path) };
like($@, qr/\bmissing\b .* \bpath\b/ix, $msg);

#####

$path     = '1';
$nextpath = '1';
$msg      = 'root ! is_ancestor_of() self';
ok(!$mapper->is_ancestor_of($mapper->map($path), $mapper->map($nextpath)),
    $msg);

$path     = '1';
$nextpath = '1.3';
$msg      = 'root is_ancestor_of() depth-1 child';
ok($mapper->is_ancestor_of($mapper->map($path), $mapper->map($nextpath)), $msg);

$path     = '1';
$nextpath = '1.3.1';
$msg      = 'root is_ancestor_of() depth-2 child';
ok($mapper->is_ancestor_of($mapper->map($path), $mapper->map($nextpath)), $msg);

$path     = '1';
$nextpath = '1.3.1.1';
$msg      = 'root is_ancestor_of() depth-3 child';
ok($mapper->is_ancestor_of($mapper->map($path), $mapper->map($nextpath)), $msg);

$path     = '1.2';
$nextpath = '1';
$msg      = 'depth-1 child ! is_ancestor_of() root';
ok(!$mapper->is_ancestor_of($mapper->map($path), $mapper->map($nextpath)),
    $msg);

$path     = '1.2';
$nextpath = '1.2';
$msg      = 'depth-1 child ! is_ancestor_of() self';
ok(!$mapper->is_ancestor_of($mapper->map($path), $mapper->map($nextpath)),
    $msg);

$path     = '1.2';
$nextpath = '1.3';
$msg      = 'depth-1 child ! is_ancestor_of() sibling';
ok(!$mapper->is_ancestor_of($mapper->map($path), $mapper->map($nextpath)),
    $msg);

$path     = '1.2';
$nextpath = '1.3.1';
$msg      = 'depth-1 child ! is_ancestor_of() sibling depth-2 child';
ok(!$mapper->is_ancestor_of($mapper->map($path), $mapper->map($nextpath)),
    $msg);

$path     = '1.3';
$nextpath = '1.3.1';
$msg      = 'depth-1 child is_ancestor_of() depth-2 child';
ok($mapper->is_ancestor_of($mapper->map($path), $mapper->map($nextpath)), $msg);

$path     = '1.3';
$nextpath = '1.3.1.1';
$msg      = 'depth-1 child is_ancestor_of() depth-3 child';
ok($mapper->is_ancestor_of($mapper->map($path), $mapper->map($nextpath)), $msg);

$path     = '1.3.1';
$nextpath = '1.3.1.1';
$msg      = 'depth-2 child is_ancestor_of() depth-3 child';
ok($mapper->is_ancestor_of($mapper->map($path), $mapper->map($nextpath)), $msg);

#####

$path     = '1';
$nextpath = '1';
$msg      = 'root ! is_descendant_of() self';
ok(!$mapper->is_descendant_of($mapper->map($path), $mapper->map($nextpath)),
    $msg);

$path     = '1';
$nextpath = '1.3';
$msg      = 'root ! is_descendant_of() depth-1 child';
ok(!$mapper->is_descendant_of($mapper->map($path), $mapper->map($nextpath)),
    $msg);

$path     = '1';
$nextpath = '1.3.1';
$msg      = 'root ! is_descendant_of() depth-2 child';
ok(!$mapper->is_descendant_of($mapper->map($path), $mapper->map($nextpath)),
    $msg);

$path     = '1';
$nextpath = '1.3.1.1';
$msg      = 'root ! is_descendant_of() depth-3 child';
ok(!$mapper->is_descendant_of($mapper->map($path), $mapper->map($nextpath)),
    $msg);

$path     = '1.2';
$nextpath = '1';
$msg      = 'depth-1 child is_descendant_of() root';
ok($mapper->is_descendant_of($mapper->map($path), $mapper->map($nextpath)),
    $msg);

$path     = '1.2';
$nextpath = '1.2';
$msg      = 'depth-1 child ! is_descendant_of() self';
ok(!$mapper->is_descendant_of($mapper->map($path), $mapper->map($nextpath)),
    $msg);

$path     = '1.2';
$nextpath = '1.3';
$msg      = 'depth-1 child ! is_descendant_of() sibling';
ok(!$mapper->is_descendant_of($mapper->map($path), $mapper->map($nextpath)),
    $msg);

$path     = '1.3.1';
$nextpath = '1.2';
$msg      = 'depth-1 child ! is_descendant_of() sibling depth-2 child';
ok(!$mapper->is_descendant_of($mapper->map($path), $mapper->map($nextpath)),
    $msg);

$path     = '1.3.1.1';
$nextpath = '1.3';
$msg      = 'depth-3 child is_descendant_of() depth-1 child';
ok($mapper->is_descendant_of($mapper->map($path), $mapper->map($nextpath)),
    $msg);

$path     = '1.3.1.1';
$nextpath = '1.3.1';
$msg      = 'depth-3 child is_descendant_of() depth-2 child';
ok($mapper->is_descendant_of($mapper->map($path), $mapper->map($nextpath)),
    $msg);

$path     = '1.3.1';
$nextpath = '1.3';
$msg      = 'depth-2 child is_descendant_of() depth-1 child';
ok($mapper->is_descendant_of($mapper->map($path), $mapper->map($nextpath)),
    $msg);

#####

$msg = 'new(chunksize => 3) options list';
$mapper = DBIx::Tree::MaterializedPath::PathMapper->new(chunksize => 3);
isa_ok($mapper, 'DBIx::Tree::MaterializedPath::PathMapper', $msg);
is($mapper->{_chunksize}, 3, $msg);

$msg = 'new(chunksize => 3) options hashref';
$mapper = DBIx::Tree::MaterializedPath::PathMapper->new({chunksize => 3});
isa_ok($mapper, 'DBIx::Tree::MaterializedPath::PathMapper', $msg);
is($mapper->{_chunksize}, 3, $msg);

$msg           = qq{map/unmap is consistent for "$path_1_17_2"};
$dbpath_1_17_2 = $mapper->map($path_1_17_2);
is($mapper->unmap($dbpath_1_17_2), $path_1_17_2, $msg);
$msg = qq{depth for "$path_1_17_2"};
is($mapper->depth($dbpath_1_17_2), 2, $msg);
$msg = qq{is_root for "$path_1_17_2"};
is($mapper->is_root($dbpath_1_17_2), 0, $msg);

$msg = 'new(chunksize => 13) options list should revert to 8';
$mapper = DBIx::Tree::MaterializedPath::PathMapper->new(chunksize => 13);
isa_ok($mapper, 'DBIx::Tree::MaterializedPath::PathMapper', $msg);
is($mapper->{_chunksize}, 8, $msg);

$msg = 'new(chunksize => 13) options hashref should revert to 8';
$mapper = DBIx::Tree::MaterializedPath::PathMapper->new({chunksize => 13});
isa_ok($mapper, 'DBIx::Tree::MaterializedPath::PathMapper', $msg);
is($mapper->{_chunksize}, 8, $msg);

$msg           = qq{map/unmap is consistent for "$path_1_17_2"};
$dbpath_1_17_2 = $mapper->map($path_1_17_2);
is($mapper->unmap($dbpath_1_17_2), $path_1_17_2, $msg);
$msg = qq{depth for "$path_1_17_2"};
is($mapper->depth($dbpath_1_17_2), 2, $msg);
$msg = qq{is_root for "$path_1_17_2"};
is($mapper->is_root($dbpath_1_17_2), 0, $msg);

