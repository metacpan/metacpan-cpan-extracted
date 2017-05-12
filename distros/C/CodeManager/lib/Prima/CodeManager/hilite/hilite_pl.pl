
$main::hilite{case_pl} = 0;
$main::hilite{styl_pl} = 0;
$main::hilite{rexp_pl} = [
	'(#!.*$)',														{ color => cl::White,	backColor => 0xcc0000,	last => 1, style=>fs::Bold,	},
	'(#-.*$)',														{ color => cl::Black,	backColor => 0xccffcc,	last => 1, },
	'(#[^!]*.*$)',													{ color => cl::Gray,	backColor => 0xffffff,	last => 1, },
	'(\t)',															{ color => 0xffcccc,},
	'(\$#_)',														{ color => 0xff0000,},
	'(#\*.*$)',														{ color => cl::White,	style=>fs::Bold,	backColor => 0x555555,},
	'(#W.*$)',														{ color => cl::Red,		style=>fs::Bold,	backColor => 0xbbbbbb,},
	'(\\\\n|\\\\t)',												{ color => 0xff00aa,},
	'(\$::(MYSELF|DBH\d+)\b)',										{ color => 0x0000ff,	style=>fs::Bold,	},
	'((\$|\@)(::)*ARGV\b)',											{ color => 0xff00ff,},
	'(\$*[\$\@\%]\w*((::)\w+)*)',									{ color => 0x880000,},
	'(\w+((::)\w+)+)',												{ color => 0x00bbbb,},
	'(\buse\s+(strict|warnings)\b)',								{ color => 0x0077dd,	style=>fs::Bold | fs::Underlined,	},
	'(\b(package|use|my|sub|our|if|else|elsif|unless|shift)\b)',	{ color => 0x0077dd,},
	'((?<=sub)\s+\w+)',												{ color => 0x007700,},
	'(\{|\})',														{ color => 0x0077dd,},
	'(0x[0-9a-f]{6})',												{ color => 0x007777,},
	'(\d+)',														{ color => 0x0000ff,},
	'(\&\w+)',														{ color => 0x00ffcc,},
	'((?<!\w)qw\(.*?\))',											{ color => 0x0077ff,	style=>fs::Bold	},
	'((?<!\w)qw(\S).*?\2)',											{ color => 0x0077ff,	style=>fs::Bold	},
	'((?<!\w)q\{.*?\})',											{ color => 0x0077ff,	style=>fs::Bold	},
	'((?<!\w)q(\S).*?\2)',											{ color => 0x0077ff,	style=>fs::Bold	},
	'(->\s*\w*)',													{ color => 0x00aa00,},
	'(=~\s*[m]{0,1}\/.*?(?<!\\\\)\/[gmeisx]*)',						{ color => 0x000000,	backColor => 0xddffdd,},
	'(=~\s*[s]{0,1}\/.*?(?<!\\\\)\/.*?(?<!\\\\)\/[gmeisx]*)',		{ color => 0x000000,	backColor => 0xddffdd,},
	'(!~\s*[m]{0,1}\/.*?(?<!\\\\)\/[gmeisx]*)',						{ color => 0x000000,	backColor => 0xffdddd,},
	'(!~\s*[s]{0,1}\/.*?(?<!\\\\)\/.*?(?<!\\\\)\/[gmeisx]*)',		{ color => 0x000000,	backColor => 0xffdddd,},
	'(__END__|__DATA__)',											{ color => 0xff00ff,},
	'(return)',														{ color => 0xff00ff,},
	"('([^']*\\\\.)*[^']*')",										{ color => 0xff0066,},
	'("([^"]*\\\\.)*[^"]*")',										{ color => 0xff6600,},
#	'("([^"\\\\]++|\\\\.)*+")',										{ color => 0xff6600,},
#	"('([^'\\\\]++|\\\\.)*+')",										{ color => 0xff0066,},
];

$main::hilite{blok_pl} = [
	'(^=\w+.*$)',	'(^=cut.*$)',	cl::Gray,
];
