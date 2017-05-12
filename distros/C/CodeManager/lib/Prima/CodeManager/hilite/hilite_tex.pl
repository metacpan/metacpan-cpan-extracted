$main::hilite{case_tex} = 0;

$main::hilite{rexp_tex} = [
	'(%.*$)',					{ color => 0xaaaaaa,},
	'(\\\\def\\\\\\w+[^{]*)',	{ color => 0xdd0000,},
	'(\\\\[a-zA-Z]+)',			{ color => 0x0066ff,},
	'(\{|\})',					{ color => 0xdd00dd, style => fs::Bold,},
	'(\#\d+)',					{ color => 0x00cc66, style => fs::Bold,},
];
