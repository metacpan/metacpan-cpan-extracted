#!perl -T
# $Id: 05-util.t,v 1.2 2007/09/08 07:31:09 pauldoom Exp $

use Test::More tests => 9;

BEGIN {
	use_ok( 'Apache::AppSamurai::Util' );
}

diag( "Testing Apache::AppSamurai::Util $Apache::AppSamurai::Util::VERSION, Perl $], $^X" );

$hlen = $Apache::AppSamurai::Util::IDLEN;

like($hlen, qr/^\d+$/, "IDLEN defined");

cmp_ok($hlen, '>=', 16, 'IDLEN less than 16');

$hlen = $hlen * 2; 

like(Apache::AppSamurai::Util::CreateSessionAuthKey(), qr/^[a-z0-9]{$hlen}$/, "CreateSessionAuthKey() - normal looking random session returned");

# These next ones require change/extension if we change from SHA-256
ok(Apache::AppSamurai::Util::CreateSessionAuthKey('TEST') eq '94ee059335e587e501cc4bf90613e0814f00a7b08bc7c648fd865a2af6a22cc2', "CreateSessionAuthKey() - correct non-random session returned");

isnt(Apache::AppSamurai::Util::CreateSessionAuthKey('') eq 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', "CreateSessionAuthKey() - Returned random session (not the evil hash of nothing)");

ok(Apache::AppSamurai::Util::HashPass('JERRY') eq '5f5cc5dd3cf310b664fb5ee4dbe9569b243a00f95907186cb8d12828906d4c14', "HashPass() - Correct hash");

isnt(eval {Apache::AppSamurai::Util::HashPass('') eq 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855' }, "HashPass() - Must not accept empty");

# Just using ComputeSessionId for the other session related
$serverkey = Apache::AppSamurai::Util::HashPass('The password is GRAVY');
$authkey = '94ee059335e587e501cc4bf90613e0814f00a7b08bc7c648fd865a2af6a22cc2';

ok(Apache::AppSamurai::Util::ComputeSessionId($authkey,$serverkey) eq '21fccb94da476b7c2a8e4ebfc88526590f14ba37410c5106a9df672fc42626f5', "ComputeSessionId() - Correct session ID computed");

 
