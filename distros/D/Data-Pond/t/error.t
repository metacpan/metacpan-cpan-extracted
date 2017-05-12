use warnings;
use strict;

use Test::More tests => 43;

BEGIN { use_ok "Data::Pond", qw(pond_read_datum pond_write_datum); }

foreach(
	undef,
	[],
	{},
) {
	eval { pond_read_datum(undef); };
	like $@, qr/\APond data error: /;
}

foreach(
	*STDOUT,
	\"",
	sub{},
	bless({},"main"),
	bless({},"ARRAY"),
	bless([],"main"),
	bless([],"HASH"),
	[ sub{} ],
) {
	eval { pond_write_datum($_, {}); };
	like $@, qr/\APond data error: /;
	eval { pond_read_datum($_); };
	like $@, qr/\APond data error: /;
}

foreach(
	"",
	" ",
	"foo",
	"undef",
	"foo=>",
	"1,",
	"[,]",
	"[,1]",
	"[1,,]",
	"[1,,2]",
	"'\x00'",
	"\"\x00\"",
	"'\t'",
	"\"\t\"",
	"'\n'",
	"\"\n\"",
	"'\x7f'",
	"\"\x7f\"",
	"'\x80'",
	"\"\x80\"",
	"'\xa0'",
	"\"\xa0\"",
	"\"\\c\"",
) {
	eval { pond_read_datum($_); };
	like $@, qr/\APond syntax error\b/;
}

1;
