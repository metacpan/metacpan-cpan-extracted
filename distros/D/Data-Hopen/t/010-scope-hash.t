#!perl
# t/010-scope.t: test Data::Hopen::Scope
use rlib 'lib';
use HopenTest;

sub makeset {
    my $set = Set::Scalar->new;
    $set->insert(@_);
    return $set;
}

use Data::Hopen::Scope::Hash;

my $s = Data::Hopen::Scope::Hash->new();
isa_ok($s, 'Data::Hopen::Scope::Hash');

$s->add(foo => 42);
cmp_ok($s->find('foo'), '==', 42, 'Retrieving works');

ok($s->names->is_equal(makeset('foo')), 'names works with a non-nested scope');
ok($s->names(0)->is_equal(makeset('foo')), 'names(0) works with a non-nested scope');

my $t = Data::Hopen::Scope::Hash->new()->add(bar => 1337);
$t->outer($s);
ok($t->names->is_equal(makeset(qw(foo bar))), 'names works with a nested scope');
ok($t->names(1)->is_equal(makeset(qw(foo bar))), 'names(1) works with a nested scope');
ok($t->names(0)->is_equal(makeset(qw(bar))), 'names(0) works with a nested scope');

cmp_ok($s->find('foo'), '==', 42, 'Retrieving from a parent (outer) scope works');

my $u = Data::Hopen::Scope::Hash->new()->add(quux => 128);
$u->outer($t);
ok($u->names->is_equal(makeset(qw(foo bar quux))), 'names works with a doubly-nested scope');
ok($u->names(2)->is_equal(makeset(qw(foo bar quux))), 'names(2) works with a doubly-nested scope');
ok($u->names(1)->is_equal(makeset(qw(bar quux))), 'names(1) works with a doubly-nested scope');
ok($u->names(0)->is_equal(makeset(qw(quux))), 'names(0) works with a doubly-nested scope');

cmp_ok($s->find('foo'), '==', 42, 'Retrieving from a grandparent scope works');

done_testing();
# vi: set fenc=utf8:
