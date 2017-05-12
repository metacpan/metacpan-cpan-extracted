
$main::hilite{styl_ini} = 1;
$main::hilite{case_ini} = 0;

$main::hilite{rexp_ini} = [
	'(^(;|#|-).*$)',		{ color => 0xaaaaaa,},
	'(^line.*=.*)',			{ color => 0xaa7777,},
	'(^(\t*)[^=]*=)',		{ color => 0x0066ff,},
	'(\t|\n)',				{ color => 0xffcccc,},
	'(^\[.*\])',			{ color => 0xff0000,},
	'(^\{.*\})',			{ color => 0x00dd00,},
	'([^;][\w\/]+\.sao)',	{ color => 0x7700aa,},
	'(;\s*menu\s*;.*$)',	{ color => 0x00aa44,},
	'(;\s*task\s*;)',		{ color => 0xff0000,},
	'(;\s*file\s*;)',		{ color => 0xaa00aa,},
];

$main::hilite{blok_ini} = [
];
