
$main::hilite{styl_seal} = 1;
$main::hilite{case_seal} = 0;

$main::hilite{rexp_seal} = [
	'(^(;|#|-).*$)',	{ color => 0xaaaaaa,},
	'(^(\t*)[^=]*=)',	{ color => 0x0066ff,},
	'(\t|\n)',			{ color => 0xffcccc,},
	'(^\[.*\])',		{ color => 0xff0000,},
	'(^\{.*\})',		{ color => 0x00dd00,},
	'([^;]*sao)',		{ color => 0x7700aa,},
	'(;\s*menu\s*;.*$)',{ color => 0x00aa44,},
	'(;\s*task\s*;)',	{ color => 0xff0000,},
];

$main::hilite{blok_seal} = [
];
 