use v5.26;
use warnings;

use Test2::V0;

use Authorization::AccessControl::Grant;

# Test constructor

ok(dies {Authorization::AccessControl::Grant->new()},                                                   'fail without resource');
ok(dies {Authorization::AccessControl::Grant->new(resource => 'User')},                                 'fail without action');
ok(dies {Authorization::AccessControl::Grant->new(resource => 'User', action => 'read', context => 1)}, 'fail with extra params');
ok(dies {Authorization::AccessControl::Grant->new(resource => undef, action => 'read')},                'fail with undef resource');
ok(dies {Authorization::AccessControl::Grant->new(resource => 'User', action => undef)},                'fail with undef action');
ok(dies {Authorization::AccessControl::Grant->new(resource => 'User', action => 'read', role => '')},   'fail with empty role');
ok(Authorization::AccessControl::Grant->new(resource => 'User', action => 'read'),                      'required params');
ok(Authorization::AccessControl::Grant->new(resource => 'User', action => 'read', restrictions => {owned => 1}),
  'required params + restrictions');

# Test is_equal
my ($pa, $pb);

$pa = Authorization::AccessControl::Grant->new(resource => 'User',  action => 'read');
$pb = Authorization::AccessControl::Grant->new(resource => 'Image', action => 'read');

is($pa->is_equal($pb), bool(0), 'differing resource');

$pa = Authorization::AccessControl::Grant->new(resource => 'User', action => 'read');
$pb = Authorization::AccessControl::Grant->new(resource => 'User', action => 'write');

is($pa->is_equal($pb), bool(0), 'differing action');

$pa = Authorization::AccessControl::Grant->new(resource => 'User', action => 'read');
$pb = Authorization::AccessControl::Grant->new(resource => 'User', action => 'read');

is($pa->is_equal($pb), bool(1), 'same resource/action, no restrictions');

$pa = Authorization::AccessControl::Grant->new(resource => 'User', action => 'read', restrictions => {});
$pb = Authorization::AccessControl::Grant->new(resource => 'User', action => 'read', restrictions => {});

is($pa->is_equal($pb), bool(1), 'same resource/action, empty vs empty restrictions');

$pa = Authorization::AccessControl::Grant->new(resource => 'User', action => 'read', restrictions => {rep => 'small'});
$pb = Authorization::AccessControl::Grant->new(resource => 'User', action => 'read', restrictions => {});

is($pa->is_equal($pb), bool(0), 'same resource/action, unequal restrictions (l)');

$pa = Authorization::AccessControl::Grant->new(resource => 'User', action => 'read', restrictions => {});
$pb = Authorization::AccessControl::Grant->new(resource => 'User', action => 'read', restrictions => {rep => 'small'});

is($pa->is_equal($pb), bool(0), 'same resource/action, unequal restrictions (r)');

$pa = Authorization::AccessControl::Grant->new(resource => 'User', action => 'read',  restrictions => {rep => 'small'});
$pb = Authorization::AccessControl::Grant->new(resource => 'User', action => 'write', restrictions => {rep => 'small'});

is($pa->is_equal($pb), bool(0), 'same restrictions, different action');

$pa = Authorization::AccessControl::Grant->new(resource => 'User',  action => 'read', restrictions => {rep => 'small'});
$pb = Authorization::AccessControl::Grant->new(resource => 'Image', action => 'read', restrictions => {rep => 'small'});

is($pa->is_equal($pb), bool(0), 'same restrictions, different resource');

$pa = Authorization::AccessControl::Grant->new(resource => 'User', action => 'read', restrictions => {rep => 'small'});
$pb = Authorization::AccessControl::Grant->new(resource => 'User', action => 'read', restrictions => {rep => 'large'});

is($pa->is_equal($pb), bool(0), 'differing restrictions values');

$pa = Authorization::AccessControl::Grant->new(resource => 'User', action => 'read', role => 'Admin');
$pb = Authorization::AccessControl::Grant->new(resource => 'User', action => 'read');

is($pa->is_equal($pb), bool(0), 'role vs no role');

$pa = Authorization::AccessControl::Grant->new(resource => 'User', action => 'read', role => 'Admin');
$pb = Authorization::AccessControl::Grant->new(resource => 'User', action => 'read', role => 'admin');

is($pa->is_equal($pb), bool(0), 'case-sensitive role');

$pa = Authorization::AccessControl::Grant->new(resource => 'User', action => 'read', role => 'admin');
$pb = Authorization::AccessControl::Grant->new(resource => 'User', action => 'read', role => 'admin');

is($pa->is_equal($pb), bool(1), 'resource/action/role match');

$pa = Authorization::AccessControl::Grant->new(resource => 'User', action => 'read', role => 'admin', restrictions => {owned => 1});
$pb = Authorization::AccessControl::Grant->new(resource => 'User', action => 'read', role => 'admin', restrictions => {owned => 1});

is($pa->is_equal($pb), bool(1), 'resource/action/role/restrictions match');

my $pc =
  Authorization::AccessControl::Grant->new(resource => 'Image', action => 'view', restrictions => {image_id => 9, rep => 'small'});
is($pc->accepts(),                                                                                bool(0), 'undef resource');
is($pc->accepts(resource => 'Image'),                                                             bool(0), 'undef action');
is($pc->accepts(resource => 'Image', action => 'view'),                                           bool(0), 'undef restrictions');
is($pc->accepts(resource => 'Image', action => 'view', attributes => {}),                         bool(0), 'empty restrictions');
is($pc->accepts(resource => 'Image', action => 'view', attributes => {image_id => 9}),            bool(0), 'partial restrictions');
is($pc->accepts(resource => 'Image', action => 'view', attributes => {deleted => 0, owned => 1}), bool(0), 'extra restrictions');
is($pc->accepts(resource => 'Image', action => 'view', attributes => {image_id => 9, rep => 'small'}), bool(1), 'met restrictions');
is($pc->accepts(resource => 'Image', action => 'view', attributes => {image_id => 9, rep => 'small', deleted => 0, owned => 1}),
  bool(1), 'met + extra restrictions');

$pc = Authorization::AccessControl::Grant->new(
  role         => 'admin',
  resource     => 'Image',
  action       => 'view',
  restrictions => {image_id => 9, rep => 'small'}
);
is($pc->accepts(resource => 'Image', action => 'view', attributes => {image_id => 9, rep => 'small',}),
  bool(0), 'unspecified roles');
is($pc->accepts(roles => [], resource => 'Image', action => 'view', attributes => {image_id => 9, rep => 'small',}),
  bool(0), 'empty roles');
is($pc->accepts(roles => [qw(Admin)], resource => 'Image', action => 'view', attributes => {image_id => 9, rep => 'small',}),
  bool(0), 'case-sensitive roles');
is($pc->accepts(roles => [qw(admin)], resource => 'Image', action => 'view', attributes => {image_id => 9, rep => 'small',}),
  bool(1), 'match all including roles');

done_testing;
