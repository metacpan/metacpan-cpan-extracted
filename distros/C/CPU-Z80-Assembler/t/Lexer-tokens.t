#!perl

# $Id$

use warnings;
use strict;

use Test::More;

use_ok	'CPU::Z80::Assembler';
use_ok	'Iterator::Simple::Lookahead';

require_ok 't/test_utils.pl';
our $stream;

isa_ok	$stream = z80lexer("%line 1+1 DATA\n", sub {<DATA>}),
		'Iterator::Simple::Lookahead';

test_token_line( 	"a adc add af af' af' and b bc bit c call ccf cp cpd cpdr cpi cpir\n", 1, "DATA");
test_token(	"a",		"a");
test_token(	"adc", 		"adc");
test_token(	"add", 		"add");
test_token(	"af", 		"af");
test_token(	"af'", 		"af'");
test_token(	"af'", 		"af'");
test_token(	"and", 		"and");
test_token(	"b", 		"b");
test_token(	"bc", 		"bc");
test_token(	"bit", 		"bit");
test_token(	"c", 		"c");
test_token(	"call",		"call");
test_token(	"ccf", 		"ccf");
test_token(	"cp", 		"cp");
test_token(	"cpd", 		"cpd");
test_token(	"cpdr",		"cpdr");
test_token(	"cpi", 		"cpi");
test_token(	"cpir",		"cpir");
test_token(	"\n", 		"\n");

test_token_line(	"cpl d daa de dec di djnz e ei ex exx h halt hl i im\n", 2, "DATA");
test_token(	"cpl", 		"cpl");
test_token(	"d", 		"d");
test_token(	"daa", 		"daa");
test_token(	"de", 		"de");
test_token(	"dec", 		"dec");
test_token(	"di", 		"di");
test_token(	"djnz",		"djnz");
test_token(	"e", 		"e");
test_token(	"ei", 		"ei");
test_token(	"ex", 		"ex");
test_token(	"exx", 		"exx");
test_token(	"h", 		"h");
test_token(	"halt",		"halt");
test_token(	"hl", 		"hl");
test_token(	"i", 		"i");
test_token(	"im", 		"im");
test_token(	"\n", 		"\n");

test_token_line(	"in inc ind indr ini inir ix iy jp jr l ld ldd lddr ldi ldir m\n", 3, "DATA");
test_token(	"in", 		"in");
test_token(	"inc", 		"inc");
test_token(	"ind", 		"ind");
test_token(	"indr",		"indr");
test_token(	"ini", 		"ini");
test_token(	"inir",		"inir");
test_token(	"ix", 		"ix");
test_token(	"iy", 		"iy");
test_token(	"jp", 		"jp");
test_token(	"jr", 		"jr");
test_token(	"l", 		"l");
test_token(	"ld", 		"ld");
test_token(	"ldd", 		"ldd");
test_token(	"lddr",		"lddr");
test_token(	"ldi", 		"ldi");
test_token(	"ldir",		"ldir");
test_token(	"m", 		"m");
test_token(	"\n", 		"\n");

test_token_line(	"nc neg nop nz or otdr otir out outd outi p pe po pop push\n", 4, "DATA");
test_token(	"nc", 		"nc");
test_token(	"neg", 		"neg");
test_token(	"nop", 		"nop");
test_token(	"nz", 		"nz");
test_token(	"or", 		"or");
test_token(	"otdr", 	"otdr");
test_token(	"otir", 	"otir");
test_token(	"out", 		"out");
test_token(	"outd", 	"outd");
test_token(	"outi", 	"outi");
test_token(	"p", 		"p");
test_token(	"pe", 		"pe");
test_token(	"po", 		"po");
test_token(	"pop", 		"pop");
test_token(	"push", 	"push");
test_token(	"\n", 		"\n");

test_token_line(	"res ret reti retn rl rla rlc rlca rld rr rra rrc rrca rrd rst\n", 5, "DATA");
test_token(	"res", 		"res");
test_token(	"ret", 		"ret");
test_token(	"reti",		"reti");
test_token(	"retn",		"retn");
test_token(	"rl", 		"rl");
test_token(	"rla", 		"rla");
test_token(	"rlc", 		"rlc");
test_token(	"rlca",		"rlca");
test_token(	"rld", 		"rld");
test_token(	"rr", 		"rr");
test_token(	"rra", 		"rra");
test_token(	"rrc", 		"rrc");
test_token(	"rrca",		"rrca");
test_token(	"rrd", 		"rrd");
test_token(	"rst", 		"rst");
test_token(	"\n", 		"\n");

test_token_line(	"sbc scf set sla sp sra srl sub xor z\n", 6, "DATA");
test_token(	"sbc", 		"sbc");
test_token(	"scf", 		"scf");
test_token(	"set", 		"set");
test_token(	"sla", 		"sla");
test_token(	"sp", 		"sp");
test_token(	"sra", 		"sra");
test_token(	"srl", 		"srl");
test_token(	"sub", 		"sub");
test_token(	"xor", 		"xor");
test_token(	"z", 		"z");
test_token(	"\n", 		"\n");

test_token_line(	"<< >> == != >= <= < > = ! ( ) + - * / % , :\n", 7, "DATA");
test_token(	"<<", 		"<<");
test_token(	">>", 		">>");
test_token(	"==", 		"==");
test_token(	"!=", 		"!=");
test_token(	">=", 		">=");
test_token(	"<=", 		"<=");
test_token(	"<", 		"<");
test_token(	">", 		">");
test_token(	"=", 		"=");
test_token(	"!", 		"!");
test_token(	"(", 		"(");
test_token(	")", 		")");
test_token(	"+", 		"+");
test_token(	"-", 		"-");
test_token(	"*", 		"*");
test_token(	"/", 		"/");
test_token(	"%", 		"%");
test_token(	",", 		",");
test_token(	":", 		":");
test_token(	"\n", 		"\n");

test_token_line(	"ixh ixl iyh iyl f\n", 8, "DATA");
test_token(	"ixh", 		"ixh");
test_token(	"ixl", 		"ixl");
test_token(	"iyh", 		"iyh");
test_token(	"iyl", 		"iyl");
test_token(	"f", 		"f");
test_token(	"\n", 		"\n");

test_token_line(	"org stop defb defw deft defm defmz defm7\n", 9, "DATA");
test_token(	"org", 		"org");
test_token(	"stop",		"stop");
test_token(	"defb",		"defb");
test_token(	"defw",		"defw");
test_token(	"deft",		"deft");
test_token(	"defm",		"defm");
test_token(	"defmz",	"defmz");
test_token(	"defm7",	"defm7");
test_token(	"\n", 		"\n");

test_token_line(	"A ADC ADD AF AF' AF' AND B BC BIT C CALL CCF CP CPD CPDR CPI CPIR\n", 10, "DATA");
test_token(	"a", 		"a");
test_token(	"adc", 		"adc");
test_token(	"add", 		"add");
test_token(	"af", 		"af");
test_token(	"af'", 		"af'");
test_token(	"af'", 		"af'");
test_token(	"and", 		"and");
test_token(	"b", 		"b");
test_token(	"bc", 		"bc");
test_token(	"bit", 		"bit");
test_token(	"c", 		"c");
test_token(	"call",		"call");
test_token(	"ccf", 		"ccf");
test_token(	"cp", 		"cp");
test_token(	"cpd", 		"cpd");
test_token(	"cpdr",		"cpdr");
test_token(	"cpi", 		"cpi");
test_token(	"cpir",		"cpir");
test_token(	"\n", 		"\n");

test_token_line(	"CPL D DAA DE DEC DI DJNZ E EI EX EXX H HALT HL I IM\n", 11, "DATA");
test_token(	"cpl", 		"cpl");
test_token(	"d", 		"d");
test_token(	"daa", 		"daa");
test_token(	"de", 		"de");
test_token(	"dec", 		"dec");
test_token(	"di", 		"di");
test_token(	"djnz",		"djnz");
test_token(	"e", 		"e");
test_token(	"ei", 		"ei");
test_token(	"ex", 		"ex");
test_token(	"exx", 		"exx");
test_token(	"h", 		"h");
test_token(	"halt",		"halt");
test_token(	"hl", 		"hl");
test_token(	"i", 		"i");
test_token(	"im", 		"im");
test_token(	"\n", 		"\n");

test_token_line(	"IN INC IND INDR INI INIR IX IY JP JR L LD LDD LDDR LDI LDIR M\n", 12, "DATA");
test_token(	"in", 		"in");
test_token(	"inc", 		"inc");
test_token(	"ind", 		"ind");
test_token(	"indr",		"indr");
test_token(	"ini", 		"ini");
test_token(	"inir",		"inir");
test_token(	"ix", 		"ix");
test_token(	"iy", 		"iy");
test_token(	"jp", 		"jp");
test_token(	"jr", 		"jr");
test_token(	"l", 		"l");
test_token(	"ld", 		"ld");
test_token(	"ldd", 		"ldd");
test_token(	"lddr",		"lddr");
test_token(	"ldi", 		"ldi");
test_token(	"ldir",		"ldir");
test_token(	"m", 		"m");
test_token(	"\n", 		"\n");

test_token_line(	"NC NEG NOP NZ OR OTDR OTIR OUT OUTD OUTI P PE PO POP PUSH\n", 13, "DATA");
test_token(	"nc", 		"nc");
test_token(	"neg", 		"neg");
test_token(	"nop", 		"nop");
test_token(	"nz", 		"nz");
test_token(	"or", 		"or");
test_token(	"otdr",		"otdr");
test_token(	"otir",		"otir");
test_token(	"out", 		"out");
test_token(	"outd",		"outd");
test_token(	"outi",		"outi");
test_token(	"p", 		"p");
test_token(	"pe", 		"pe");
test_token(	"po", 		"po");
test_token(	"pop", 		"pop");
test_token(	"push",		"push");
test_token(	"\n", 		"\n");

test_token_line(	"RES RET RETI RETN RL RLA RLC RLCA RLD RR RRA RRC RRCA RRD RST\n", 14, "DATA");
test_token(	"res", 		"res");
test_token(	"ret", 		"ret");
test_token(	"reti",		"reti");
test_token(	"retn",		"retn");
test_token(	"rl", 		"rl");
test_token(	"rla", 		"rla");
test_token(	"rlc", 		"rlc");
test_token(	"rlca",		"rlca");
test_token(	"rld", 		"rld");
test_token(	"rr", 		"rr");
test_token(	"rra", 		"rra");
test_token(	"rrc", 		"rrc");
test_token(	"rrca",		"rrca");
test_token(	"rrd", 		"rrd");
test_token(	"rst", 		"rst");
test_token(	"\n", 		"\n");

test_token_line(	"SBC SCF SET SLA SP SRA SRL SUB XOR Z\n", 15, "DATA");
test_token(	"sbc", 		"sbc");
test_token(	"scf", 		"scf");
test_token(	"set", 		"set");
test_token(	"sla", 		"sla");
test_token(	"sp", 		"sp");
test_token(	"sra", 		"sra");
test_token(	"srl", 		"srl");
test_token(	"sub", 		"sub");
test_token(	"xor", 		"xor");
test_token(	"z", 		"z");
test_token(	"\n", 		"\n");

test_token_line(	"IXH IXL IYH IYL F\n", 16, "DATA");
test_token(	"ixh", 		"ixh");
test_token(	"ixl", 		"ixl");
test_token(	"iyh", 		"iyh");
test_token(	"iyl", 		"iyl");
test_token(	"f", 		"f");
test_token(	"\n", 		"\n");

test_token_line(	"ORG STOP DEFB DEFW DEFT DEFM DEFMZ DEFM7\n", 17, "DATA");
test_token(	"org", 		"org");
test_token(	"stop",		"stop");
test_token(	"defb",		"defb");
test_token(	"defw",		"defw");
test_token(	"deft",		"deft");
test_token(	"defm",		"defm");
test_token(	"defmz",	"defmz");
test_token(	"defm7",	"defm7");
test_token(	"\n", 		"\n");

test_token_line(	"'unclosed string ;\n", 18, "DATA");
test_token(	"'", 		"'");
test_token(	"NAME",		"unclosed");
test_token(	"NAME",		"string");
test_token(	"\n", 		"\n");

test_token_line(	"\"unclosed string ;\n", 19, "DATA");
test_token(	"\"", 		"\"");
test_token(	"NAME",		"unclosed");
test_token(	"NAME",		"string");
test_token(	"\n", 		"\n");

test_token_line(	"'clo;sed' \"string\" 'with''quote' \"and\"\"quote\" ; comment '\n", 20, "DATA");
test_token(	"STRING", 	"clo;sed");
test_token(	"STRING", 	"string");
test_token(	"STRING", 	"with");
test_token(	"STRING", 	"quote");
test_token(	"STRING", 	"and");
test_token(	"STRING", 	"quote");
test_token(	"\n", 		"\n");

test_token_line(	"Identifier INDENTIFIER indentifier \$ cplx dy daaz det _012\n", 21, "DATA");
test_token(	"NAME",		"Identifier");
test_token(	"NAME",		"INDENTIFIER");
test_token(	"NAME",		"indentifier");
test_token(	"NAME",		"\$");
test_token(	"NAME",		"cplx");
test_token(	"NAME",		"dy");
test_token(	"NAME",		"daaz");
test_token(	"NAME",		"det");
test_token(	"NAME",		"_012");
test_token(	"\n", 		"\n");

test_token_line(	"0 1 234 567 89\n", 22, "DATA");
test_token(	"NUMBER", 	0);
test_token(	"NUMBER", 	1);
test_token(	"NUMBER", 	234);
test_token(	"NUMBER", 	567);
test_token(	"NUMBER", 	89);
test_token(	"\n", 		"\n");

test_token_line(	"0xAF 0xaf 0x100 0afh 0AFH \$af #af\n", 23, "DATA");
test_token(	"NUMBER", 	0xaf);
test_token(	"NUMBER", 	0xaf);
test_token(	"NUMBER", 	0x100);
test_token(	"NUMBER", 	0xaf);
test_token(	"NUMBER", 	0xaf);
test_token(	"NUMBER", 	0xaf);
test_token(	"NUMBER", 	0xaf);
test_token(	"\n", 		"\n");

test_token_line(	"0b01 0b10 0b010 010b 010B %010\n", 24, "DATA");
test_token(	"NUMBER", 	0b01);
test_token(	"NUMBER", 	0b10);
test_token(	"NUMBER", 	0b10);
test_token(	"NUMBER", 	0b10);
test_token(	"NUMBER", 	0b10);
test_token(	"NUMBER", 	0b10);
test_token(	"\n", 		"\n");

test_eof();


done_testing();


__DATA__
a adc add af af' af' and b bc bit c call ccf cp cpd cpdr cpi cpir 
cpl d daa de dec di djnz e ei ex exx h halt hl i im 
in inc ind indr ini inir ix iy jp jr l ld ldd lddr ldi ldir m 
nc neg nop nz or otdr otir out outd outi p pe po pop push 
res ret reti retn rl rla rlc rlca rld rr rra rrc rrca rrd rst 
sbc scf set sla sp sra srl sub xor z
<< >> == != >= <= < > = ! ( ) + - * / % , :
ixh ixl iyh iyl f
org stop defb defw deft defm defmz defm7
A ADC ADD AF AF' AF' AND B BC BIT C CALL CCF CP CPD CPDR CPI CPIR 
CPL D DAA DE DEC DI DJNZ E EI EX EXX H HALT HL I IM 
IN INC IND INDR INI INIR IX IY JP JR L LD LDD LDDR LDI LDIR M 
NC NEG NOP NZ OR OTDR OTIR OUT OUTD OUTI P PE PO POP PUSH 
RES RET RETI RETN RL RLA RLC RLCA RLD RR RRA RRC RRCA RRD RST 
SBC SCF SET SLA SP SRA SRL SUB XOR Z
IXH IXL IYH IYL F
ORG STOP DEFB DEFW DEFT DEFM DEFMZ DEFM7
'unclosed string ; 
"unclosed string ; 
'clo;sed' "string" 'with''quote' "and""quote" ; comment '
Identifier INDENTIFIER indentifier $ cplx dy daaz det _012
0 1 234 567 89
0xAF 0xaf 0x100 0afh 0AFH $af #af
0b01 0b10 0b010 010b 010B %010
