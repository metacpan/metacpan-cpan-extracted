
$main::hilite{case_html} = 0;
$main::hilite{rexp_html} = [
#	'(\/\/.*$)',			{ color => 0xaaaaaa,},
	'(<\/*\w+>|<\w+|>)',			{ color => 0xcc0000,},
	'(\$_.+?\})',			{ color => 0xff00ff,},
	'(\$[A-Z]+\{.*?\})',	{ color => 0x0077ff,},
#	'((alt|class|href|id|name|ondblclick|onclick|onfocus|onblur|readonly|READONLY|title|src|style|type|value)="[^\$<>]*?")',	{ color => 0x00aa55,},
	'((alt|class|href|id|name|ondblclick|onclick|onblur|readonly|READONLY|title|src|style|type|value)(?=\s*=\s*"[^<>]*?"))',	{ color => 0x00aa55,},
#	'((?<=onclick)\s*=\s*"[^\$<>]*?")',	{ color => 0xff00aa,},
#	'((?<=ondblclick)\s*=\s*"[^\$<>]*?")',{ color => 0xff00aa,},
#	'((?<=onblur)\s*=\s*"[^\$<>]*?")',	{ color => 0xff00aa,},
#	'((?<=onfocus)\s*=\s*"[^\$<>]*?")',	{ color => 0xff00aa,},
#	'((alt|class|href||id|name|ondblclick|onclick|onblur|readonly|READONLY|title|src|style|type|value)="[^<>]*?")',		{ color => 0x00aa55,},
	'(\&S_.+?\))',			{ color => 0x7777ff,},
	'(http:[\/\w\.]+)',		{ color => 0xcccc00,},
	'(&[\w^;]+?;)',			{ color => 0x0000ff,},
	'(<!--output.*?-->)',	{ color => 0x0066bb,style => fs::Bold,},
	'(<!--.*?-->)',			{ color => 0xaaaaaa,},
	'(<!--perl)',			{ color => 0x007777,backColor => 0xaaffff,},
	'(perl-->)',			{ color => 0x007777,backColor => 0xaaffff,},
	'(javascript:\w+)',		{ color => 0x000077,backColor => 0xffeeee,},
];

$main::hilite{blok_html} = [
	'(<pre|<code)','(</pre>|</code>)',1,0x99ccee,
];

#	'(^<!--perl.*$)','(^perl-->)',1,0x00aaaa
