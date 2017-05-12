
$main::hilite{styl_rep} = 1;
$main::hilite{case_rep} = 0;

$main::hilite{rexp_rep} = [
	'(\t|\n)',				{ color => 0xffcccc,},
	'(^(;|#|-).*$)',		{ color => 0xaaaaaa,},
	'(^[^=]*=)',			{ color => 0xdd3300,},
	'(-\w+=>)',				{ color => 0x0077cc,},
	'((0x[0-9a-fA-F]{6}))',	{ color => 0x007777,	style => fs::Bold,	},
	'(,)',					{ color => 0xff0000,	style => fs::Bold,	},
];

$main::hilite{blok_rep} = [];
