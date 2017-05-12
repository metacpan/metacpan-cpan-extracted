
$main::hilite{case_bat} = 0;
$main::hilite{styl_bat} = 0;
$main::hilite{rexp_bat} = [
	'(".*")',	{ color => 0xff0000,},
	'(\s)',		{ color => 0xff0000,	backColor => 0xffddbb,},
	'(^rem.*)',	{ color => cl::Gray,	backColor => 0xffffff,},
];

$main::hilite{blok_bat} = [];
