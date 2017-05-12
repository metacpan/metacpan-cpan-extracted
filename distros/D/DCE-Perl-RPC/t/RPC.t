#!/usr/bin/perl

use DCE::Perl::RPC;
use Test;
use constant DCOM_IREMOTEACTIVATION => pack("H32", "B84A9F4D1C7DCF11861E0020AF6E7C57");
use constant DCOM_IF_VERSION => pack("V", 0);
use constant DCOM_XFER_SYNTAX => pack("H32", "045D888AEB1CC9119FE808002B104860");
use constant DCOM_XFER_SYNTAX_VERSION => pack("V", 2);

plan tests => 4;
$rpc = new DCE::Perl::RPC;

#################
# Test rpc_bind #
#################

$correct_bind_msg = pack("H152", "05000b0310000000" .
				"7500250000000000" .
				"d016d01600000000" .
				"0100000001000100" .
				"b84a9f4d1c7dcf11" .
				"861e0020af6e7c57" .
				"00000000045d888a" .
				"eb1cc9119fe80800" .
				"2b10486002000000" .
				"0a020000");
$ntlm_negotiate_msg = pack("H74", "4e544c4d53535000" .
				"0100000007b200a00300030022000000" .
				"02000200200000005753444f4d");
$bind_msg = $rpc->rpc_bind(1, DCOM_IREMOTEACTIVATION . DCOM_IF_VERSION,
	(DCOM_XFER_SYNTAX . DCOM_XFER_SYNTAX_VERSION), $ntlm_negotiate_msg);
ok(substr($bind_msg, 0, 76) eq $correct_bind_msg and substr($bind_msg, 80) eq $ntlm_negotiate_msg);

######################
# Test rpc_bind_resp #
######################

$correct_bind_resp_msg = pack("H48", "0500100310000000" .
				"76005a0000000000" .
				"d016d0160a020000");
				
$ntlm_auth_msg = pack("H180", "4e544c4d5353500003000000" .
			"180018005a0000001800180072000000" .
			"0e000e0040000000080008004e000000" .
			"0400040056000000000000008a000000" .
			"05820000550053004500520044004f00" .
			"4d00550053004500520057005300");
$bind_resp_msg = $rpc->rpc_bind_resp($ntlm_auth_msg);
ok(substr($bind_resp_msg, 0, 24) eq $correct_bind_resp_msg and substr($bind_resp_msg, 28) eq $ntlm_auth_msg);

####################
# Test rpc_request #
####################

$correct_request_msg = pack("H112", "0500008310000000" .
				"4c00100000000000" .
				"0a00000001000e00" .
				"b84a9f4d1c7dcf11" .
				"861e0020af6e7c57" .
				"48692c2074686572" .
				"652100000a020200");

$request_msg = $rpc->rpc_co_request("Hi, there!", 1, 0x0e, DCOM_IREMOTEACTIVATION, pack("V4", 1, 0, 0, 0));
ok(substr($request_msg, 0, 56) eq $correct_request_msg and substr($request_msg, 60) eq pack("V4", 1, 0, 0, 0));

####################
# Test alt_context #
####################

$correct_alt_ctx_msg = pack("H144", "05000e0310000000" .
				"4800000000000000" .
				"d016d01600000000" .
				"0100000001000100" .
				"b84a9f4d1c7dcf11" .
				"861e0020af6e7c57" .
				"00000000045d888a" .
				"eb1cc9119fe80800" .
				"2b10486002000000"); 
$alt_ctx_msg = $rpc->rpc_alt_ctx(1, DCOM_IREMOTEACTIVATION . DCOM_IF_VERSION,
	(DCOM_XFER_SYNTAX . DCOM_XFER_SYNTAX_VERSION));
ok($alt_ctx_msg eq $correct_alt_ctx_msg);

exit;
