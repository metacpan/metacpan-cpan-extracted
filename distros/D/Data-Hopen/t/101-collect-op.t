#!perl
# 006-passthrough-op.t: test Data::Hopen::G::CollectOp
use rlib 'lib';
use HopenTest;

use Data::Hopen qw(hnew);
use Scalar::Util qw(refaddr);

sub not_identical($$;$) {
    cmp_ok(refaddr($_[0]), '!=', refaddr($_[1]), $_[2]);
}

$Data::Hopen::VERBOSE=@ARGV;
    # say `perl -Ilib t/011-scope-env.t -- foo` to turn on verbose output

use Data::Hopen::Scope::Hash;

use Data::Hopen::G::CollectOp;

my $e = Data::Hopen::G::CollectOp->new(name=>'foo');
isa_ok($e, 'Data::Hopen::G::CollectOp');
is($e->name, 'foo', 'Name was set by constructor');
$e->name('bar');
is($e->name, 'bar', 'Name was set by accessor');

is_deeply($e->run(-context => Data::Hopen::Scope::Hash->new), {}, 'run() returns {} when inputs are empty');

my $scope = Data::Hopen::Scope::Hash->new;
$scope->put(foo=>1, bar=>2, baz=>{quux=>1337}, quuux=>[1,2,3,[42,43,44]]);
my $newhr = $e->run(-context => $scope);
is_deeply($newhr, $scope->_content, 'run() clones its inputs');
not_identical($scope->_content, $newhr, 'run() returns a clone, not its input');

# Nested scopes: stop at local
my $inner_scope = hnew 'Scope::Hash' => 'inner';
$inner_scope->put(inner=>'yes');
$inner_scope->local(true);
$inner_scope->outer($scope);
$newhr = $e->run(-context=>$inner_scope);
is_deeply($newhr, {inner => 'yes'}, 'run() 2 stops at local');
not_identical($scope->_content, $newhr, 'run() 2 returns a clone, not its input');

# Test different -levels values
$e = Data::Hopen::G::CollectOp->new(name=>'foo', levels => 2);
    # levels = 0 => just the node's overrides
    # levels = 1 => also the node's context ($inner_scope)
    # levels = 2 => also the context's outer ($scope)
$newhr = $e->run(-context=>$inner_scope);
is_deeply($newhr, {%{$inner_scope->_content}, %{$scope->_content}}, 'levels=1 run() gets both');
not_identical($inner_scope->_content, $newhr, 'levels=1 run() does not clone inner scope');
not_identical($scope->_content, $newhr, 'levels=1 run() does not clone outer scope');

my $outer_scope = Data::Hopen::Scope::Hash->new;
$outer_scope->put(outer=>'yep');
$scope->outer($outer_scope);
$newhr = $e->run(-context=>$inner_scope);
is_deeply($newhr, {%{$inner_scope->_content}, %{$scope->_content}}, 'levels=1 run() does not get outermost');
not_identical($inner_scope->_content, $newhr, 'levels=1 run() with outer does not clone inner scope');
not_identical($scope->_content, $newhr, 'levels=1 run() with outer does not clone outer scope');
not_identical($outer_scope->_content, $newhr, 'levels=1 run() with outer does not clone outermost scope');

done_testing();
