$main::hilite{case_php} = 0;
$main::hilite{rexp_php} = [
	'(\t)',					{ color => 0xffcccc,},
	'(#.*$)',				{ color => 0xaaaaaa,},
	'("(\\\\"|[^"])*")',	{ color => 0xff0088,},
	'(\/\/.*$)',			{ color => 0xaaaaaa,},
	'(\$(::)*\w+)',			{ color => 0x800000,},
	'(\@(::)*\w+)',			{ color => 0x800000,},
	'(\%(::)*\w+)',			{ color => 0x800000,},
	'(0x[0-9a-f]{6})',		{ color => 0x007777,},
	'(\d+)',				{ color => 0x0000ff,},
	'(\"[^\"]*\")',			{ color => 0xdd0000,},
	'(\'[^\']*\')',			{ color => 0xff4444,},
	'(qw\([^\(\)]*\))',		{ color => 0x00aa00,},
	'(q\([^\(\)]*\))',		{ color => 0x00aa00,},
	'(function)',			{ color => 0x0000aa,},
];
 