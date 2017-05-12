
$main::hilite{case_conf} = 0;
$main::hilite{rexp_conf} = [
	'(\t)',					{ color => 0xffcccc,},
	'(#.*$)',				{ color => 0xaaaaaa,},
	'(^\w[^\s=]*)',			{ color => 0x007777,},
	'(^\s*\$\w*)',			{ color => 0x0000ff,},
	'(=~|==|=>|=|\(|\))',	{ color => 0x0099ff,},
	'(".*?")',				{ color => 0xff4400,},
	'(\'.*?\')',			{ color => 0xff44cc,},
	'(^(;|#|-).*$)',	{ color => 0xaaaaaa,},
	'(^(\t*)[^=]*=)',	{ color => 0x0066ff,},
	'(\t|\n)',			{ color => 0xffcccc,},
	'(^\[.*\])',		{ color => 0xff0000,},
	'(^\{.*\})',		{ color => 0x00dd00,},
	'([^;]*sao)',		{ color => 0x7700aa,},
	'(;\s*menu\s*;.*$)',{ color => 0x00aa44,},
	'(;\s*task\s*;)',	{ color => 0xff0000,},
	'(;\s*file\s*;)',	{ color => 0xaa00aa,},
]
