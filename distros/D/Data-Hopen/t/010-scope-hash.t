#!perl
# t/010-scope.t: test Data::Hopen::Scope
use rlib 'lib';
use HopenTest 'Data::Hopen::Scope::Hash';

sub makeset {
    my $set = Set::Scalar->new;
    $set->insert(@_);
    return $set;
}

# --- creation and put -----------------------------------------------
my $s = $DUT->new();
isa_ok($s, "$DUT");

$s->put(foo => 42);
cmp_ok($s->find('foo'), '==', 42, 'Retrieving works');

ok($s->names->is_equal(makeset('foo')), 'names works with a non-nested scope');
ok($s->names(0)->is_equal(makeset('foo')), 'names(0) works with a non-nested scope');

my $t = $DUT->new()->put(bar => 1337);
$t->outer($s);
ok($t->names->is_equal(makeset(qw(foo bar))), 'names works with a nested scope');
ok($t->names(1)->is_equal(makeset(qw(foo bar))), 'names(1) works with a nested scope');
ok($t->names(0)->is_equal(makeset(qw(bar))), 'names(0) works with a nested scope');

cmp_ok($s->find('foo'), '==', 42, 'Retrieving from a parent (outer) scope works');

my $u = $DUT->new()->put(quux => 128);
$u->outer($t);
ok($u->names->is_equal(makeset(qw(foo bar quux))), 'names works with a doubly-nested scope');
ok($u->names(2)->is_equal(makeset(qw(foo bar quux))), 'names(2) works with a doubly-nested scope');
ok($u->names(1)->is_equal(makeset(qw(bar quux))), 'names(1) works with a doubly-nested scope');
ok($u->names(0)->is_equal(makeset(qw(quux))), 'names(0) works with a doubly-nested scope');

cmp_ok($s->find('foo'), '==', 42, 'Retrieving from a grandparent scope works');

# --- merge ----------------------------------------------------------

# Default merge strategy

sub defstrat {
    my $strategy = shift;
    my $sname = $strategy // 'undef';
    $s = $DUT->new();   # merge into empty
    $s->merge_strategy($strategy) if defined $strategy;
    $s->merge(foo=>2);
    is_deeply($s->as_hashref, {foo=>2}, "$sname Merge into empty works");
    cmp_ok($s->find('foo'), '==', 2, "$sname Merge into empty works (find)");

    $s = $DUT->new();   # put then merge scalars
    $s->merge_strategy($strategy) if defined $strategy;
    $s->put(foo=>1);
    $s->merge(foo=>2);
    is_deeply($s->as_hashref, {foo=>[1,2]}, "$sname Merge retainment works");
    is_deeply($s->find('foo'), [1,2], "$sname Merge retainment works (find)");

    $s = $DUT->new();   # put then merge arrays
    $s->merge_strategy($strategy) if defined $strategy;
    $s->put(foo=>[1,2,3]);
    $s->merge(foo=>[4,5,6]);
    is_deeply($s->as_hashref, {foo=>[1,2,3,4,5,6]}, "$sname Merge retainment works (arrays)");
    is_deeply($s->find('foo'), [1,2,3,4,5,6], "$sname Merge retainment works (arrays) (find)");

    $s->put(foo=>3);    # overwrite using put
    is_deeply($s->as_hashref, {foo=>3}, "$sname Overwrite works");
    cmp_ok($s->find('foo'), '==', 3, "$sname Overwrite works (find)");
}

defstrat;
defstrat 'combine';

# Keep merge strategy

$s = $DUT->new();
$s->merge_strategy('keep');
$s->put(foo=>1);
$s->merge(foo=>2);
is_deeply($s->as_hashref, {foo=>1}, 'Keep retainment works');
cmp_ok($s->find('foo'), '==', 1, 'Keep retainment works (find)');

# Replace merge strategy

$s = $DUT->new();
$s->merge_strategy('replace');
$s->put(foo=>1);
$s->merge(foo=>2);
is_deeply($s->as_hashref, {foo=>2}, 'Replace retainment works');
cmp_ok($s->find('foo'), '==', 2, 'Replace retainment works (find)');

done_testing();
# vi: set fenc=utf8:
