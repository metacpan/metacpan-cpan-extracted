
$main::hilite{case_xml} = 0;
$main::hilite{rexp_xml} = [
	'(\t)',				{ color => 0xcccccc,},
	'(<\?.*\?>)',		{ color => 0x0000ff,	style => fs::Bold,},
	'(<\w+[^>]*>)',		{ color => 0x77cc77,},
	'(<\/\w+>)',		{ color => 0xcc7777,},
];
 