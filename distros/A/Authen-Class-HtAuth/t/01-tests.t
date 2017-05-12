#!perl

use Test::More tests => 14;

use_ok( 'Authen::Class::HtAuth' );
my $atest; eval { $atest = Authen::Class::HtAuth->new(
	htusers => "t/htusers",
	htgroups => "t/htgroups",
)};

ok($atest->can("check"), "load auth files");
ok($atest->check("ryan", "fuckface"), "valid credentials check");
ok(!$atest->check("ryan", "ilikecheese"), "invalid credentials check");
ok($atest->check(qw/ryan fuckface/, groups => [
	[One => qw/admin users/],
	qw/middleclass american/, ]),
	"valid groups check");
ok($atest->groupcheck("ryan", groups => [
	[All => qw/admin american/],
	qw/middleclass american/, ]),
	"valid groups check 2");
ok(!$atest->groupcheck("ryan", groups => [qw/admin users american/]),
	"invalid groups check");
ok(!$atest->groupcheck("ryan", groups => [
	[All => qw/admin users middleclass american/],
	]), "invalid groups check 2");
ok($atest->check(qw/ryan fuckface/, groups => [
	[One => 
		[one => qw/admn users/],
		[all => qw/middleclass american asshole/],
	]]),
	"complex group check");
ok($atest->groupcheck("ryan", groups => [
	[One => 
		[one => qw/admin users/],
		[all => qw/middleclass american ashole/],
	]]),
	"complex group check 2");
ok($atest->groupcheck("ryan", groups => [
	[All => 
		[one => qw/admin users/],
		[all => qw/middleclass american asshole/],
	]]),
	"complex group check 3");
ok($atest->groupcheck("ryan", groups => [
	[All => 
		[one => qw/admin users/],
		[all => qw/middleclass american asshole/],
		[not => qw/does not exist/],
	]]),
	"complex group check 4");
ok(!$atest->groupcheck("ryan", groups => [
	[All => 
		[one => qw/admin users/],
		[all => qw/middleclass american asshole/],
		[not => qw/one of these does exist admin/],
	]]),
	"complex group check 5");

package MyAuth;
our @ISA = qw/Authen::Class::HtAuth/;
MyAuth->htusers("t/htusers");
MyAuth->htgroups("t/htgroups");

::ok(MyAuth->check(qw/ryan fuckface/, groups => [qw/middleclass american/]),
	"class based");

