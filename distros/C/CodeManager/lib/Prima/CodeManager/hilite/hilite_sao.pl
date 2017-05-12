
$main::hilite{case_sao} = 0;
$main::hilite{styl_sao} = 0;
$main::hilite{rexp_sao} = [
	'(#.*)',						{ color => 0xaaaaaa,	backColor => 0xffffff, last => 1,},
	'(^(REPLACE|NAME|HELP|DATA|WRITE|STARTKEY|KEY|TASK_PREFIX|TASK_SUFFIX|LOOP_PREFIX|LOOP_SUFFIX|EVENT|WHERE|RANGE|LOCATE|FIND|TASK|MODE|FRAME|SCROLL|FILL|POPUPMENU|TOOLBAR|BUTTON|RANGE)\s*=\s*\d+)',
									{ color => 0x0000ff,	style => fs::Bold,	},
	'(\t|\n)',						{ color => 0xffcccc,	style => fs::Normal,},
	'(\%REPLACE_[^\%]+\%)',			{ color => 0x770077,	style => fs::Normal,},
	'(\$*ARG(\s*=\s*)*\d+)',		{ color => 0x0088aa,	style => fs::Bold,	},
	'(\$*LINK(\s*=\s*)*\d+)',		{ color => 0x338800,	style => fs::Bold,	},
	'(^VAR\s*=\s*\d+)',				{ color => 0xcc0022,	style => fs::Normal,},
	'(\$VAR(==)?\d+)',				{ color => 0xcc0022,	style => fs::Normal,},
	'(^EXP\s*=\s*\d+)',				{ color => 0xcc00cc,	style => fs::Bold,	},
	'(\$EXP\d+)',					{ color => 0xcc00cc,	style => fs::Bold,	},
	'((\$VAR|\$CUR|\$RUC)\d+)',		{ color => 0x77cc22,	style => fs::Normal,},
	'(\$DB\d+)',					{ color => 0xaa00aa,	style => fs::Bold,	},
	'((0x[0-9a-fA-F]{6}))',			{ color => 0x007777,	style => fs::Bold,	},
	'(\d+)',						{ color => 0x0000ff,	style => fs::Normal,},
	'(sql(\w*)\(.*\))',				{ color => 0x995500,	style => fs::Normal,},
	'(\\\\.*$)',					{ color => 0xff00ff,	style => fs::Normal,},
	'((?<!#)\w*((\/\w+)+)(\.\w+)*)',{ color => 0x00aa66,	style => fs::Bold | fs::Underlined,},
	'(\b\w+\b?\.(?=\w))',			{ color => 0xdd6600,	style => fs::Normal,},
];

$main::hilite{blok_sao} = [
	'(^\/\*)',	'(^\*\/)',	cl::Gray,
];
