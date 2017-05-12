$main::hilite{case_log} = 0;
$main::hilite{styl_log} = 0;
$main::hilite{rexp_log} = [
	'(\t)',															{ color => 0xffcccc,},
	'(\\\\n|\\\\t)',												{ color => 0xff00aa,},
	'(\$*[\$\@\%]\w*((::)\w+)*)',									{ color => 0x880000,},
	'(\w+((::)\w+)+)',												{ color => 0x00bbbb,},
	'((?<=sub)\s+\w+)',	{ color => 0x007700,},
	'(\{|\})',														{ color => 0x0077dd,},
	'(0x[0-9a-f]{6})',												{ color => 0x007777,},
	'(\d+)',														{ color => 0x0000ff,},
	'(\&\w+)',														{ color => 0x00ffcc,},
	'((?<!#)\w*((\/\w+)+)(\.\w+)*)',		{ color => 0x00aa66,	style => fs::Bold | fs::Underlined,},
	'(->\s*\w*)',													{ color => 0x00aa00,},
];

$main::hilite{blok_log} = [
];
