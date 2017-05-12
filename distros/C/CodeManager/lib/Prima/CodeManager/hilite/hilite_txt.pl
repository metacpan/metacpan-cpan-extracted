
$main::hilite{case_txt} = 0;

$main::hilite{rexp_txt} = [
	'(\s\d.*)',		{ color => 0x0000cc,},
	'(^\d.*)',		{ color => 0x000000,backColor => 0xccffcc,},
];
$main::hilite{blok_txt} = [
#	'(^\d)',	'(^\d)',	0x000000, 0xccffcc,
];
