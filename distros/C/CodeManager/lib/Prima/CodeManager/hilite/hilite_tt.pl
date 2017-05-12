
$main::hilite{case_html} = 0;
$main::hilite{rexp_html} = [
#	'(\/\/.*$)',			{ color => 0xaaaaaa,},
	'(<\/*\w+>)',			{ color => 0xcc0000,},
	'(<\w+)',				{ color => 0xcc0000,},
	'(>)',					{ color => 0xcc0000,},
	'(\$_.+?\})',			{ color => 0xff00ff,},
	'(\&S_.+?\))',			{ color => 0x7777ff,},
	'(http:[\/\w\.]+)',		{ color => 0xcccc00,},
	'(&[\w^;]+?;)',			{ color => 0x0000ff,},
	'(="[^\$<>]*?")',		{ color => 0x00aa33,},
	'(\$[A-Z]+\{.*?\})',	{ color => 0x0077ff,},
	'(<!--output.*?-->)',	{ color => 0x0066bb,style => fs::Bold,},
	'(<!--.*?-->)',			{ color => 0xaaaaaa,},
	'(<!--perl)',			{ color => 0x007777,backColor => 0xaaffff,},
	'(perl-->)',			{ color => 0x007777,backColor => 0xaaffff,},
];

$main::hilite{blok_html} = [
#	'(^<!--perl.*$)','(^perl-->)',1,0x00aaaa
];

 