
$main::hilite{case_rb} = 0;
$main::hilite{styl_rb} = 0;
$main::hilite{rexp_rb} = [
	'(\t)',												{ color => 0xffcccc,},
	'(\$#_)',											{ color => 0xff0000,},
	'(#.*$)',											{ color => cl::Gray,},
	'(\\\\n|\\\\t)',									{ color => 0xff00aa,},
	'(\$*[\$\@\%]\w*(::)*\w+)',							{ color => 0x880000,},
	'(\b(use|sub|my|if|else|elsif|unless|shift)\b)',	{ color => 0x0077dd, style => fs::Bold,},
	'(\{|\})',											{ color => 0x0077dd, style => fs::Bold,},
	'(0x[0-9a-f]{6})',									{ color => 0x007777,},
	'(\d+)',											{ color => 0x0000ff,},
	'(qw\([^\(\)]*\))',									{ color => 0x00aa00,},
	'(q\([^\(\)]*\))',									{ color => 0x00aa00,},
	'(\'[^\']*\')',										{ color => 0xff3300,},
	'(->\s*\w*)',										{ color => 0x00aa00,},
	'(=~\s*[ms]{0,1}\/(.*)\/[^\/]*\/[geix]*)',			{ color => 0x00aaaa, backColor => 0xffdddd,},
	'(=~\s*[ms]{0,1}\/([^\/]*|\/)*\/[geix]*)',			{ color => 0x00aaaa, backColor => 0xffdddd,},
#	'(=~\s*[ms]{0,1}\/([^\/]*|\/)*\/[^\/]*\/[geix]*)',	{ color => 0x00aaaa, backColor => 0xffdddd,},
	'(".*?")',											{ color => 0xff3300,},
];

$main::hilite{blok_rb} = [
#	'(^=pod.*$)','(^=cut.*$)',0,cl::Gray,
];
 