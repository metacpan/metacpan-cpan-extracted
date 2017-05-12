
$main::hilite{styl_dic} = 1;
$main::hilite{case_dic} = 0;

$main::hilite{rexp_dic} = [
	'(\t|\n)',		{ color => 0xffcccc,},
	'(^(;|#|-).*$)',{ color => 0xaaaaaa,},
	'(^[^=]*=)',	{ color => 0xdd3300,},
];

$main::hilite{blok_dic} = [];
 