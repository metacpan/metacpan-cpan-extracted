# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use Crypt::SmbHash qw(ntlmgen lmhash nthash);
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

my ( $lm, $nt );

# Test Empty Password
ntlmgen "",$lm,$nt;
ok($lm,"AAD3B435B51404EEAAD3B435B51404EE");
ok($nt,"31D6CFE0D16AE931B73C59D7E0C089C0");

# Test password "0"
ntlmgen "0",$lm,$nt;
ok($lm,"25AD3B83FA6627C7AAD3B435B51404EE");
ok($nt,"7BC26760A19FC23E0996DAA99744CA80");

# Test simple password
ntlmgen "abcdef",$lm,$nt;
ok($lm,"13D855FC4841C7B1AAD3B435B51404EE");
ok($nt,"B5FE2DB507CC5AC540493D48FBD5FE33");

# Test long password
ntlmgen "abcdefghijklmnopqrstuvwxyabcdefghijklmnopqrstuvwxyabcdefghijklmnopqrstuvwxyabcdefghijklmnopqrstuvwxyabcdefghijklmnopqrstuvwxyabcdefghijklmnopqrstuvwxyabcdefghijklmnopqrstuvwxyabcdefghijklmnopqrstuvwxyabcdefghijklmnopqrstuvwxyzzzzzzzzz",$lm,$nt;
ok($lm,"E0C510199CC66ABD8C51EC214BEBDEA1");
ok($nt,"D71B61697C939BE27C14A7D7E23948EE");

# the next tests will fail if perl version <= 5.8
if ($] >= 5.008) {
	require Encode;
	import Encode;

	# Test password with special chars (encoding here: utf8)
	ntlmgen decode('utf8',"\303\266\303\244\303\274"),$lm,$nt;
	ok($lm,"9983511F41C7B4C1AAD3B435B51404EE");
	ok($nt,"4848BCB81CF018C3B70EA1479BD1374D");

	# Test password with special chars (encoding here: latin1)
	$lm = lmhash(decode('latin1', "\366\344\374"), "latin1");
	$nt = nthash(decode('latin1', "\366\344\374"));
	ok($lm,"9983511F41C7B4C1AAD3B435B51404EE");
	ok($nt,"4848BCB81CF018C3B70EA1479BD1374D");
}
