
$main::hilite{case_cm} = 0;

$main::hilite{rexp_cm} = [
	'(\t)',							{ color => 0xffcccc,},
	'(^(;|#|-).*$)',				{ color => cl::Gray,	backColor => 0xeeeeee,},
	'(^\[.*\])',					{ color => 0xff0000,	backColor => 0xffdddd,	style => fs::Bold,},
	'(^[^=]*=)',					{ color => 0x0066ff,},
];
