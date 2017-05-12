use warnings;
use strict;

use Test::More tests => 7;

BEGIN { use_ok "Data::Pond", qw(pond_write_datum); }

foreach(
	undef,
	[ undef ],
	{ a => undef },
) {
	eval { pond_write_datum($_, {}); };
	like $@, qr/\APond data error: /;
}

is pond_write_datum(undef, {undef_is_empty=>1}), '""';
is pond_write_datum([ undef ], {undef_is_empty=>1}), '[""]';
is pond_write_datum({ a => undef }, {undef_is_empty=>1}), '{a=>""}';

1;
