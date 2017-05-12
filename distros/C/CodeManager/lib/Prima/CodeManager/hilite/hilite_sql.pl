
$main::hilite{styl_sql} = 0;
$main::hilite{case_sql} = 1;
$main::hilite{rexp_sql} = [
	'(\t)',						{ color => 0xffcccc,},
	'(\\*\\/)',					{ color => cl::Gray,},
	'(--.*$)',					{ color => 0xaaaaaa,},
	'(\'\s*language.*;)',		{ color => 0x0000ff,},
#	'(\'.*?\')',				{ color => 0xff0066,},
	"('([^'\\\\]++|\\\\.)*+')",	{ color => 0xaa0000,},
	'(\b(FOR\s+\w+\s+IN|WHILE|LOOP|END\s+LOOP)\b)',
								{ color => 0x7700ff,},
	'((BEGIN\s+TRANSACTION\s*;|COMMIT;|ROLLBACK;|begin|end;|declare|returns))',
								{ color => 0x0000ff,	style => fs::Underlined | fs::Bold,},
	'(\breturn\s+NULL\b)',		{ color => 0xff0000,	backColor => 0xffddbb,},
	'(\b(NULL|EXIT|return)\b)',	{ color => 0xff0000,	},
	'((end if;|not\s+found))',								{ color => 0x0000ff,},
	'(\b(and|or|when|elseif|elsif|if|found|then|else)\b)',	{ color => 0x0000ff,},
	'(\b(CONSTRAINT|PRIMARY KEY|FOREIGN KEY|REFERENCES|MATCH SIMPLE|(ON\s+(DELETE|UPDATE)\s+(CASCADE|NO ACTION)))\b)',
								{ color => 0x0066ff,},
	'(\b((CREATE\s*(OR REPLACE)*|DROP|ALTER)\s+(FUNCTION|(UNIQUE\s+)*INDEX|TABLE|SEQUENCE|TRIGGER|VIEW))\b)',
								{ color => 0x00cc00,},
	'(\b(ON|ADD|AS)\b)',		{ color => 0x00cc00,},
#	'(CREATE\s*(OR REPLACE)*|VIEW|GRANT|REVOKE|DROP|UNIQUE||CONSTRAINT|PRIMARY KEY)',
#								{ color => 0xff0000,},
	'(\b(AFTER|BEFORE|DELETE|DESC|FOR EACH ROW EXECUTE PROCEDURE|FROM|GROUP BY|INSERT|INTO|LEFT OUTER JOIN|LIMIT|OFFSET|ORDER BY|SELECT|SET|UPDATE|VALUES|WHERE)\b)',
								{ color => 0x00cc00,},
	'(\b(new)\b)',				{ color => 0x00aaaa,	style => fs::Underlined,},
	'(\b(old)\b)',				{ color => 0xff00ff,	style => fs::Underlined,},
	'(\b(varchar|trigger|character varying|bigint|integer|numeric|int|date|time|timestamp|interval|not null|default|record)\b)',{ color => 0x800000,},
	'(\$\d+)',					{ color => 0xdd0033,	style => fs::Bold,},
	'(\b\w+\b?\.(?=\w))',		{ color => 0xdd6600,},
	'(\br_\w+\b)',				{ color => 0xdd6600,},
	'(\bt_\w+\b)',				{ color => 0x000000,	style => fs::Bold,},
];

$main::hilite{blok_sql} = [
	'(\/\*)',	'(\*\/)',	cl::Gray,
];
