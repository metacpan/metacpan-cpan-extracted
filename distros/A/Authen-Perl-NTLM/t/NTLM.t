#!/usr/bin/perl

use Authen::Perl::NTLM qw(nt_hash lm_hash);
use Test;

plan tests => 4;
$my_pass = "Beeblebrox";
$nonce = "SrvNonce";
$client = new_client Authen::Perl::NTLM(lm_hash($my_pass), nt_hash($my_pass), "USER", "USERDOM", "DOM", "WS");

$correct_negotiate_msg = pack("H74", "4e544c4d53535000" .
				"0100000007b200a00300030022000000" .
				"02000200200000005753444f4d");
$correct_lm_resp = pack("H48", "ad87ca6defe34685b9c43c477a8c42d600667d6892e7e897");
$correct_nt_resp = pack("H48", "e0e00de3104a1bf2053f07c7dda82d3c489ae989e1b000d3");
$correct_auth_msg = pack("H180", "4e544c4d5353500003000000" .
			"180018005a0000001800180072000000" .
			"0e000e0040000000080008004e000000" .
			"0400040056000000000000008a000000" .
			"05820000550053004500520044004f00" .
			"4d00550053004500520057005300") . 
			$correct_lm_resp . $correct_nt_resp;
    $flags = $client->NTLMSSP_NEGOTIATE_80000000 
	   | $client->NTLMSSP_NEGOTIATE_128
	   | $client->NTLMSSP_NEGOTIATE_ALWAYS_SIGN
	   | $client->NTLMSSP_NEGOTIATE_OEM_DOMAIN_SUPPLIED
	   | $client->NTLMSSP_NEGOTIATE_OEM_WORKSTATION_SUPPLIED
	   | $client->NTLMSSP_NEGOTIATE_NTLM
	   | $client->NTLMSSP_NEGOTIATE_UNICODE
	   | $client->NTLMSSP_NEGOTIATE_OEM
	   | $client->NTLMSSP_REQUEST_TARGET;
$negotiate_msg = $client->negotiate_msg($flags);
ok($negotiate_msg eq $correct_negotiate_msg);
   
    $flags = $client->NTLMSSP_NEGOTIATE_ALWAYS_SIGN
	   | $client->NTLMSSP_NEGOTIATE_NTLM
	   | $client->NTLMSSP_NEGOTIATE_UNICODE
	   | $client->NTLMSSP_REQUEST_TARGET;
    $auth_msg = $client->auth_msg($nonce, $flags);
ok($auth_msg eq $correct_auth_msg);
$server = new_server Authen::Perl::NTLM("DOM");
$correct_challenge_msg1 = pack("H48", "4e544c4d53535000" .
				   "0200000003000300" .
				   "3000000005820100");
$correct_challenge_msg2 = pack("H44", 
				   "0000000000000000" .
				   "000000003c000000" .
				   "44004f004d00");
    $flags = $server->NTLMSSP_NEGOTIATE_ALWAYS_SIGN
	   | $server->NTLMSSP_NEGOTIATE_NTLM
	   | $server->NTLMSSP_NEGOTIATE_UNICODE
	   | $server->NTLMSSP_TARGET_TYPE_DOMAIN
	   | $server->NTLMSSP_REQUEST_TARGET;
$challenge_msg = $server->challenge_msg($flags);
ok(substr($challenge_msg, 0, 24) eq $correct_challenge_msg1 and substr($challenge_msg, 32, 22) eq $correct_challenge_msg2);
@result = $client->parse_challenge($challenge_msg);
ok($result[0] eq "DOM" and $result[1] == unpack("V", pack("H8", "05820100")) and length($result[2]) == 8 and $result[3] == 0 and $result[4] == 0x3c);
