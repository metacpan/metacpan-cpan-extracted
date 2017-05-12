#!perl -T
# $Id: 11-session-gen-hmac_sha.t,v 1.2 2007/09/08 07:31:09 pauldoom Exp $

use Test::More tests => 4;

BEGIN {
	use_ok( 'Apache::AppSamurai::Session::Generate::HMAC_SHA' );
}

diag( "Testing Apache::AppSamurai::Session::Generate::HMAC_SHA $Apache::AppSamurai::Session::Generate::HMAC_SHA::VERSION, Perl $], $^X" );

$sess = { args => {
    ServerKey => '21fccb94da476b7c2a8e4ebfc88526590f14ba37410c5106a9df672fc42626f5',
    key => '94ee059335e587e501cc4bf90613e0814f00a7b08bc7c648fd865a2af6a22cc2'
    }
      };
		   
ok(Apache::AppSamurai::Session::Generate::HMAC_SHA::generate($sess) eq '2aeb1d06bec029aa54cb2b678897c5eac3051acb6d2de89b56383c872ef710c6', "generate() - Correct session local ID computed");

$sess->{data}->{_session_id} = '2aeb1d06bec029aa54cb2b678897c5eac3051acb6d2de89b56383c872ef710c6';

ok(Apache::AppSamurai::Session::Generate::HMAC_SHA::validate($sess) eq 1, "validate() - Checked good value correctly");

isnt(eval {Apache::AppSamurai::Session::Generate::HMAC_SHA::validate('Goll Dang Is this wrong!')}, 1, "validate() - Checked bad value correctly (died as expected)");



