
$main::hilite{case_tt2} = 0;
$main::hilite{rexp_tt2} = [
	'(<\/*\w+>|<\w+|>)',			{ color => 0xcc0000,},
	'(\$_.+?\})',			{ color => 0xff00ff,},
	'(\&S_.+?\))',			{ color => 0x7777ff,},
	'(http:[\/\w\.]+)',						{ color => 0xcccc00,},
	'(&[\w^;]+?;)',							{ color => 0x0000ff,},
	'((class|src|href|style|id)="[^\$<>]*?")',		{ color => 0x00aa55,},
	'(\$[A-Z]+\{.*?\})',					{ color => 0x0077ff,},
	'(<!--output.*?-->)',					{ color => 0x0066bb,style => fs::Bold,},
	'(<!--.*?-->)',							{ color => 0xaaaaaa,},
	'(\[\%-?\s*#.*?\%\])',					{ color => 0xaaaaaa,},
	'(\[\%.*(FOREACH|META|END).*?\%\])',	{ color => 0x0055ff,style => fs::Bold,},
	'(\[\%\s*[^#].*?\%\])',					{ color => 0x008844,},
];

$main::hilite{blok_tt2} = [
#	'(^<!--perl.*$)','(^perl-->)',1,0x00aaaa
];

#	'(<\w+)',				{ color => 0xcc0000,},
#	'(>)',					{ color => 0xcc0000,},
#	'((?<=>)[^<>]*(?=<))',					{ color => 0xcc0000,	},
#	'([^<>]*(?=<))',						{ color => 0xcc0000,	},
#	'((?<=>)[^<>]*)',						{ color => 0xcc0000,	},
