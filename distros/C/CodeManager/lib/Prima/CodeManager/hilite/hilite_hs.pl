
$main::hilite{case_hs} = 0;
$main::hilite{rexp_hs} = [
	'(\t)',					{ color => 0xffcccc,},
	'(#.*$)',				{ color => 0xaaaaaa,},
	'(^\w[^\s=]*)',			{ color => 0x007777,},
	'(^\s*\$\w*)',			{ color => 0x0000ff,},
	'(=~|==|=>|=|\(|\))',	{ color => 0x7700ff,},
	'(".*?")',				{ color => 0xff4400,},
]
 