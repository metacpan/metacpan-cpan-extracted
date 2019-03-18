#!perl

use strict;
use warnings;

use Test::More;

use_ok 'CPU::Z80::Disassembler::Format';

is format_hex(1),  		"\$01";
is format_hex(0),  		"\$00";
is format_hex(-1), 		"-\$01";

is format_hex2(1),  	"\$01";
is format_hex2(0),  	"\$00";
is format_hex2(-1), 	"\$FF";

is format_hex4(1),  	"\$0001";
is format_hex4(0),  	"\$0000";
is format_hex4(-1), 	"\$FFFF";

is format_bin8(1), 		"%00000001";
is format_bin8(255),	"%11111111";
is format_bin8(256),	"%100000000";
is format_bin8(0), 		"%00000000";
is format_bin8(-1),		"-%00000001";

is format_dis(1),  		"+\$01";
is format_dis(0),  		"";
is format_dis(-1), 		"-\$01";

is format_str(1),  		"'1'";
is format_str(''),  	"''";
is format_str("'a'"),	"'''a'''";
is format_str("\n"),	"'\n'";

done_testing;
