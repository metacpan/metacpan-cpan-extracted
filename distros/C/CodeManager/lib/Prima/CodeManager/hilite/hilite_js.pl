
$main::hilite{case_js} = 0;
$main::hilite{styl_js} = 0;

$main::hilite{rexp_js} = [
	'(\/{2}.*)',					{ color => 0xaaaaaa,},
	'(\b(var|new|for|function|if|else|return)\b)',	{ color => 0x000000,	style => fs::Bold,},
	'(Array|Object)',				{ color => 0x00aa00,	style => fs::Bold,},
	'(\"[^\"]*\")',					{ color => 0xdd0000,},
	'(\'.*?\')',					{ color => 0xff00aa,},
	'(\d*)',						{ color => 0x0077ff,},
	'(\.\w+)',						{ color => 0x009900,},
	'(\w+\.)',						{ color => 0x009900,},
];
$main::hilite{blok_js} = [];
