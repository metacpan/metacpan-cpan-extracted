#!/usr/bin/perl

use Authen::NTLM::HTTP::Base qw(lm_hash nt_hash);
use Authen::NTLM::HTTP;
use Test;

plan tests => 17;
$my_pass = "Beeblebrox";
$nonce = "SrvNonce";
$client = new_client Authen::NTLM::HTTP(lm_hash($my_pass), nt_hash($my_pass), Authen::NTLM::HTTP::NTLMSSP_HTTP_WWW, "Zaphod", "URSA-MINOR", "URSA-MINOR", "LIGHTCITY");

$correct_negotiate_msg = "Authorization: NTLM TlRMTVNTUAABAAAAA7IAAAoACgApAAAACQAJACAAAABMSUdIVENJVFlVUlNBLU1JTk9S";

$correct_lm_resp = pack("H48", "ad87ca6defe34685b9c43c477a8c42d600667d6892e7e897");
$correct_nt_resp = pack("H48", "e0e00de3104a1bf2053f07c7dda82d3c489ae989e1b000d3");

$correct_auth_msg = "Authorization: NTLM TlRMTVNTUAADAAAAGAAYAHIAAAAYABgAigAAABQAFABAAAAADAAMAFQAAAASABIAYAAAAAAAAACiAAAAAYIAAFUAUgBTAEEALQBNAEkATgBPAFIAWgBhAHAAaABvAGQATABJAEcASABUAEMASQBUAFkArYfKbe/jRoW5xDxHeoxC1gBmfWiS5+iX4OAN4xBKG/IFPwfH3agtPEia6YnhsADT";
    $flags = $client->NTLMSSP_NEGOTIATE_ALWAYS_SIGN
	   | $client->NTLMSSP_NEGOTIATE_OEM_DOMAIN_SUPPLIED
	   | $client->NTLMSSP_NEGOTIATE_OEM_WORKSTATION_SUPPLIED
	   | $client->NTLMSSP_NEGOTIATE_NTLM
	   | $client->NTLMSSP_NEGOTIATE_UNICODE
	   | $client->NTLMSSP_NEGOTIATE_OEM;
$negotiate_msg = $client->http_negotiate($flags);
ok($correct_negotiate_msg eq $negotiate_msg);
$server = new_server Authen::NTLM::HTTP(Authen::NTLM::HTTP::NTLMSSP_HTTP_WWW, "URSA-MINOR");
@ret = $server->http_parse_negotiate($negotiate_msg);
ok($ret[0] == $flags);
ok($ret[1] eq "URSA-MINOR");
ok($ret[2] eq "LIGHTCITY");
    $flags = $client->NTLMSSP_NEGOTIATE_ALWAYS_SIGN
	   | $client->NTLMSSP_NEGOTIATE_NTLM
	   | $client->NTLMSSP_NEGOTIATE_UNICODE;
$auth_msg = $client->http_auth($nonce, $flags);
ok($auth_msg eq $correct_auth_msg);
@ret = $server->http_parse_auth($auth_msg);
ok($ret[0] == $flags);
ok($ret[1] eq $correct_lm_resp);
ok($ret[2] eq $correct_nt_resp);
ok($ret[3] eq "URSA-MINOR");
ok($ret[4] eq "Zaphod");
ok($ret[5] eq "LIGHTCITY");
$correct_challenge_msg = "WWW-Authenticate: NTLM TlRMTVNTUAACAAAAAAAAACgAAAABggAAU3J2Tm9uY2UAAAAAAAAAAA==";
    $flags = $server->NTLMSSP_NEGOTIATE_ALWAYS_SIGN
	   | $server->NTLMSSP_NEGOTIATE_NTLM
	   | $server->NTLMSSP_NEGOTIATE_UNICODE;
$challenge_msg = $server->http_challenge($flags, $nonce);
ok($correct_challenge_msg eq $challenge_msg);
@result = $client->http_parse_challenge($challenge_msg);
ok(not defined $result[0]);
ok($result[1] == unpack("V", pack("H8", "01820000")));
ok($result[2] eq "SrvNonce");
ok(not defined $result[3]);
ok(not defined $result[4]);
