
$main::hilite{case_css} = 0;

$main::hilite{rexp_css} = [
	'(\/\/.*$)',		{ color => 0xaaaaaa,},
	'(\/\*.*?\*\/)',	{ color => 0xaaaaaa,},
	'((\}))',			{ color => 0x00bb77,},
	'(([^\{]+\{))',		{ color => 0x00bb77,},
	'(([\w\-]+:))',		{ color => 0x0000cc,},
	'(([^:;]+;))',		{ color => 0xbb0055,},
];

$main::hilite{blok_css} = [
#	'(^=[^c].*$)','(^=cut.*$)',0,cl::Gray,
];

 