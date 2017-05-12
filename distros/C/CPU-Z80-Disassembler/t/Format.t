#!perl

use strict;
use warnings;

use Test::More;

use_ok 'CPU::Z80::Disassembler::Format';

is format_hex(1),  		"0x01";
is format_hex(0),  		"0x00";
is format_hex(-1), 		"-0x01";

is format_hex2(1),  	"0x01";
is format_hex2(0),  	"0x00";
is format_hex2(-1), 	"0xFF";

is format_hex4(1),  	"0x0001";
is format_hex4(0),  	"0x0000";
is format_hex4(-1), 	"0xFFFF";

is format_bin8(1), 		"0b00000001";
is format_bin8(255),	"0b11111111";
is format_bin8(256),	"0b100000000";
is format_bin8(0), 		"0b00000000";
is format_bin8(-1),		"-0b00000001";

is format_dis(1),  		"+0x01";
is format_dis(0),  		"";
is format_dis(-1), 		"-0x01";

is format_str(1),  		"'1'";
is format_str(''),  	"''";
is format_str("'a'"),	"'''a'''";
is format_str("\n"),	"'\n'";

done_testing;
