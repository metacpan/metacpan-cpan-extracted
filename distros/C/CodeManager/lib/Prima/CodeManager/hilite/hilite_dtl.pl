
$main::hilite{case_dtl} = 0;
$main::hilite{rexp_dtl} = [
	'(\t)',				{ color => 0xffccff,},
#	'(\/\/.*$)',		{ color => 0xaaaaaa,},
	'(<\/*\w+>)',		{ color => 0xcc0000,},
	'(<\w+)',			{ color => 0xcc0000,},
	'(>)',				{ color => 0xcc0000,},
	'()',				{ color => 0x0000cc,},
	'("(.*?)")',		{ color => 0x00aa33,},
	'(http:[\/\w\.]+)',	{ color => 0xcc00cc,},
	'(&[^;]+?;)',		{ color => 0xcc00cc,},
];
 