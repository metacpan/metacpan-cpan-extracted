$main::hilite{case_tdu} = 0;
$main::hilite{rexp_tdu} = [
	'(\t)',								{ color => 0xffcccc,},
	'(\\\\null)',						{ color => 0xaaaa00,},
	'(^\\\\def\\\\\\S+\{)',				{ color => 0x0066ff,},
	'(^\\})',							{ color => 0x0066ff,},
	'(^\\\\.*$)',						{ color => 0xdd0000,},
	'(^\\\\\\w+)',						{ color => 0xdd0000,},
	'(%%[\w]+\{[^,]+,[-+]{0,1}\d+\})',	{ color => 0xdd00dd,},
	'(\$\$\d+)',						{ color => 0x00aaff,},
	'(\%\#\d+)',						{ color => 0xcc0000,	style => fs::Bold,	},
	'(\#\d+)',							{ color => 0x00cc66,	style => fs::Bold,	},
	'(\\\\->)',							{ color => 0x00cccc,	style => fs::Bold,	},
];

$main::hilite{blok_tdu} = [];
