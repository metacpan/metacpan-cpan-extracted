use v5.26;
use warnings;

use Test2::V0;

use Authorization::AccessControl::Dispatch;

use experimental qw(signatures);

use constant true  => !0;
use constant false => !1;

# Constructor Tests

ok(Authorization::AccessControl::Dispatch->new(),                       'empty instance');
ok(dies {Authorization::AccessControl::Dispatch->new(denied => undef)}, 'unsupported parameter');

ok(Authorization::AccessControl::Dispatch->new(entity => {}),    'entity set');
ok(Authorization::AccessControl::Dispatch->new(entity => undef), 'entity undef');

ok(Authorization::AccessControl::Dispatch->new(granted => 0),     'granted false');
ok(Authorization::AccessControl::Dispatch->new(granted => 1),     'granted true');
ok(Authorization::AccessControl::Dispatch->new(granted => undef), 'granted undef');

ok(Authorization::AccessControl::Dispatch->new(entity => {}, granted => 0),     'entity set, granted false');
ok(Authorization::AccessControl::Dispatch->new(entity => {}, granted => 1),     'entity set, granted true');
ok(Authorization::AccessControl::Dispatch->new(entity => {}, granted => undef), 'entity set, granted undef');

ok(Authorization::AccessControl::Dispatch->new(entity => undef, granted => 0),     'entity set, granted false');
ok(Authorization::AccessControl::Dispatch->new(entity => undef, granted => 1),     'entity set, granted true');
ok(Authorization::AccessControl::Dispatch->new(entity => undef, granted => undef), 'entity set, granted undef');

my $yr;

# Test is_granted

$yr = Authorization::AccessControl::Dispatch->new(granted => 1);
is($yr->is_granted, true, 'granted without entity');
$yr = Authorization::AccessControl::Dispatch->new(granted => 'abc');
is($yr->is_granted, true, 'granted without entity - string value');
$yr = Authorization::AccessControl::Dispatch->new(granted => \'abc');
is($yr->is_granted, true, 'granted without entity - ref value');

$yr = Authorization::AccessControl::Dispatch->new(granted => 1, entity => "v");
is($yr->is_granted, true, 'granted with entity');
$yr = Authorization::AccessControl::Dispatch->new(granted => 'abc', entity => "v");
is($yr->is_granted, true, 'granted with entity - string value');
$yr = Authorization::AccessControl::Dispatch->new(granted => \'abc', entity => "v");
is($yr->is_granted, true, 'granted with entity - ref value');

$yr = Authorization::AccessControl::Dispatch->new(granted => 0, entity => "v");
is($yr->is_granted, false, 'denied - num');
$yr = Authorization::AccessControl::Dispatch->new(granted => false, entity => "v");
is($yr->is_granted, false, 'denied - boolean');
$yr = Authorization::AccessControl::Dispatch->new(granted => '', entity => "v");
is($yr->is_granted, false, 'denied - empty string');

# Test callback arg handling

ok(Authorization::AccessControl::Dispatch->new(granted => true, entity => "v")->granted(sub($entity) { }), 'granted one arg');
ok(
  dies {
    Authorization::AccessControl::Dispatch->new(granted => true, entity => "v")->granted(sub() { })
  },
  'granted no args'
);

ok(Authorization::AccessControl::Dispatch->new(granted => false, entity => "v")->denied(sub() { }), 'denied no args');
ok(
  dies {
    Authorization::AccessControl::Dispatch->new(granted => false, entity => "v")->denied(sub($entity) { })
  },
  'denied one arg'
);

ok(Authorization::AccessControl::Dispatch->new(granted => undef, entity => "v")->null(sub() { }), 'null no args');
ok(
  dies {
    Authorization::AccessControl::Dispatch->new(granted => undef, entity => "v")->null(sub($entity) { })
  },
  'null one arg'
);

# Test granted

my $r;

$r = [];
Authorization::AccessControl::Dispatch->new(granted => true, entity => "v")->granted(sub($entity) {push($r->@*, $entity)});
is($r, ["v"], 'check granted called with data value');

$r = [];
Authorization::AccessControl::Dispatch->new(granted => true, entity => undef)->granted(sub($entity) {push($r->@*, $entity)});
is($r, [undef], 'check granted called with undef data value');

$r = [];
Authorization::AccessControl::Dispatch->new(granted => true, entity => "v")->granted(sub($entity) {push($r->@*, $entity)})
  ->granted(sub($entity) {push($r->@*, "'$entity'")});
is($r, ['v', "'v'"], 'check granted called twice, in order');

$r = [];
Authorization::AccessControl::Dispatch->new(granted => true, entity => "v")->granted(sub($entity) {push($r->@*, "'$entity'")})
  ->granted(sub($entity) {push($r->@*, $entity)});
is($r, ["'v'", 'v'], 'check granted called twice, reverse order');

$r = [];
Authorization::AccessControl::Dispatch->new(granted => true, entity => "v")->granted(sub($entity) {push($r->@*, $entity)})
  ->denied(sub() {push($r->@*, "d")})->granted(sub($entity) {push($r->@*, "'$entity'")});
is($r, ['v', "'v'"], 'check granted called twice and denied not called');

$r = [];
Authorization::AccessControl::Dispatch->new(granted => true, entity => "v")->granted(sub($entity) {push($r->@*, $entity)})
  ->null(sub() {push($r->@*, "n")})->granted(sub($entity) {push($r->@*, "'$entity'")});
is($r, ['v', "'v'"], 'check granted called twice and null not called');

$r = [];
Authorization::AccessControl::Dispatch->new(granted => true, entity => "v")->null(sub() {push($r->@*, "n")});
is($r, [], 'check null not called');

$r = [];
Authorization::AccessControl::Dispatch->new(granted => true, entity => "v")->denied(sub() {push($r->@*, "n")});
is($r, [], 'check denied not called');

# Test denied

$r = [];
Authorization::AccessControl::Dispatch->new(granted => false, entity => "v")->denied(sub() {push($r->@*, "d")});
is($r, ["d"], 'check denied called with data value');

$r = [];
Authorization::AccessControl::Dispatch->new(granted => false, entity => undef)->denied(sub() {push($r->@*, "d")});
is($r, ["d"], 'check denied called with undef data value');

$r = [];
Authorization::AccessControl::Dispatch->new(granted => false, entity => "v")->denied(sub() {push($r->@*, "d")})
  ->denied(sub() {push($r->@*, "'d'")});
is($r, ['d', "'d'"], 'check denied called twice, in order');

$r = [];
Authorization::AccessControl::Dispatch->new(granted => false, entity => "v")->denied(sub() {push($r->@*, "'d'")})
  ->denied(sub() {push($r->@*, 'd')});
is($r, ["'d'", 'd'], 'check denied called twice, reverse order');

$r = [];
Authorization::AccessControl::Dispatch->new(granted => false, entity => "v")->denied(sub() {push($r->@*, 'd')})
  ->granted(sub($entity) {push($r->@*, $entity)})->denied(sub() {push($r->@*, "'d'")});
is($r, ['d', "'d'"], 'check denied called twice and granted not called');

$r = [];
Authorization::AccessControl::Dispatch->new(granted => false, entity => "v")->denied(sub() {push($r->@*, 'd')})
  ->null(sub() {push($r->@*, "n")})->denied(sub() {push($r->@*, "'d'")});
is($r, ['d', "'d'"], 'check denied called twice and null not called');

$r = [];
Authorization::AccessControl::Dispatch->new(granted => false, entity => "v")->null(sub() {push($r->@*, "n")});
is($r, [], 'check null not called');

$r = [];
Authorization::AccessControl::Dispatch->new(granted => false, entity => "v")->granted(sub($entity) {push($r->@*, $entity)});
is($r, [], 'check granted not called');

# Test null

$r = [];
Authorization::AccessControl::Dispatch->new(granted => undef, entity => "v")->null(sub() {push($r->@*, "n")});
is($r, ["n"], 'check null called with data value');

$r = [];
Authorization::AccessControl::Dispatch->new(granted => undef, entity => undef)->null(sub() {push($r->@*, "n")});
is($r, ["n"], 'check null called with undef data value');

$r = [];
Authorization::AccessControl::Dispatch->new(granted => undef, entity => "v")->null(sub() {push($r->@*, "n")})
  ->null(sub() {push($r->@*, "'n'")});
is($r, ['n', "'n'"], 'check null called twice, in order');

$r = [];
Authorization::AccessControl::Dispatch->new(granted => undef, entity => "v")->null(sub() {push($r->@*, "'n'")})
  ->null(sub() {push($r->@*, 'n')});
is($r, ["'n'", 'n'], 'check null called twice, reverse order');

$r = [];
Authorization::AccessControl::Dispatch->new(granted => undef, entity => "v")->null(sub() {push($r->@*, 'n')})
  ->granted(sub($entity) {push($r->@*, $entity)})->null(sub() {push($r->@*, "'n'")});
is($r, ['n', "'n'"], 'check null called twice and granted not called');

$r = [];
Authorization::AccessControl::Dispatch->new(granted => undef, entity => "v")->null(sub() {push($r->@*, 'n')})
  ->denied(sub() {push($r->@*, "d")})->null(sub() {push($r->@*, "'n'")});
is($r, ['n', "'n'"], 'check null called twice and denied not called');

$r = [];
Authorization::AccessControl::Dispatch->new(granted => undef, entity => "v")->denied(sub() {push($r->@*, "n")});
is($r, [], 'check denied not called');

$r = [];
Authorization::AccessControl::Dispatch->new(granted => undef, entity => "v")->granted(sub($entity) {push($r->@*, $entity)});
is($r, [], 'check granted not called');

done_testing;
