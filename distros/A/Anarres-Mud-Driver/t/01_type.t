use strict;
use Data::Dumper;
use Test::More tests => 24;

my ($t, $u, $v, $w);

BEGIN { use_ok('Anarres::Mud::Driver::Compiler::Type', ':all'); }

$t = T_STRING;
ok($$t eq 's', 'Construct T_STRING (from cache)');

$t = new Anarres::Mud::Driver::Compiler::Type("*s");
ok($$t eq '*s', 'Construct string pointer');

$t = new Anarres::Mud::Driver::Compiler::Type("*s");
ok($$t eq '*s', 'Construct string pointer from cache');

$t = T_CLASS("a", T_STRING);
ok($$t =~ m/^{/, 'Construct T_CLASS');
ok($t->dump eq '{a:s}', 'Class dump looks OK');

$t = T_CLASS("b", T_STRING, T_INTEGER, T_CLASS("c", T_STRING, T_INTEGER));
ok($$t =~ m/^{/, 'Construct complex T_CLASS');
# print STDERR $t->dump, "\n";
ok($t->dump eq '{b:si{c:si}}', 'Complex class dump looks OK');

my $cond = 1;
my $cache = \%Anarres::Mud::Driver::Compiler::Type::CACHE;
foreach (keys %$cache) {
	$cond = 0 unless $_ eq ${$cache->{$_}};
}
ok($cond, 'Cache integrity check');

$t = T_CLASS("d", T_STRING, T_INTEGER, T_CLASS("e", T_STRING, T_INTEGER));
$u = T_CLASS("f", T_STRING, T_INTEGER, T_CLASS("g", T_STRING));
my $v = $t->array;
my $w = $u->array;

my ($td, $ud, $vd, $wd) = map { $_->dump } ($t, $u, $v, $w);

ok(T_NIL->compatible(T_INTEGER), 'Can assign NIL to INTEGER');
ok(T_BOOL->compatible(T_INTEGER), 'Can assign BOOL to INTEGER');
ok(!(T_INTEGER->compatible(T_NIL)), 'Cannot assign INTEGER to NIL');
ok(!(T_INTEGER->compatible(T_BOOL)), 'Cannot assign INTEGER to BOOL');
ok(T_NIL->compatible(T_CLASS("h", T_INTEGER)), 'Can assign NIL to class');
ok($t->compatible($t), 'Can assign $t to itself');
ok($u->compatible($u), 'Can assign $u to itself');
ok(!($t->compatible($u)), 'Cannot assign simple class to complex');
ok(!($u->compatible($t)), 'Cannot assign complex class to simple');

ok(T_NIL->unify(T_INTEGER)->equals(T_INTEGER), 'U(n, i) = i');
ok(T_INTEGER->unify(T_INTEGER)->equals(T_INTEGER), 'U(i, i) = i');
ok(T_STRING->unify(T_INTEGER)->equals(T_UNKNOWN), 'U(s, i) = ?');
ok($u->unify($u)->equals($u), "U($ud, $ud) = $ud");
ok($u->unify($t)->equals(T_UNKNOWN), "U($ud, $td) = ?");
ok($v->unify($w)->equals(T_UNKNOWN->array), "U($vd, $wd) = *?");
