use Test;
BEGIN {
	plan(tests => 12);
};
use Algorithm::CheckDigits;

my $tin_ie = CheckDigits('tin_ie');

#
#	[ 'ustid_ie', '8473625E', '8473625', 'E',
#	              '8473625A' ],
#	[ 'tin_ie',   '1234567T', '1234567', 'T',
#	              '8473625A' ],
#	[ 'tin_ie',   '1234567TW', '1234567?W', 'T',
#	              '8473625AW' ],
#	[ 'tin_ie',   '1234577W', '1234577', 'W',
#	              '8473625A' ],
ok($tin_ie->is_valid("8473625E"));
ok(not $tin_ie->is_valid("8473625A"));
ok($tin_ie->is_valid("1234567T"));
ok(not $tin_ie->is_valid("1234567A"));
ok($tin_ie->is_valid("1234567TW"));
ok(not $tin_ie->is_valid("1234567AW"));
ok($tin_ie->is_valid("1234577W"));
ok(not $tin_ie->is_valid("1234577A"));
ok($tin_ie->is_valid("1234577WW"));
ok(not $tin_ie->is_valid("1234577AW"));
ok($tin_ie->is_valid("1234577IA"));
ok(not $tin_ie->is_valid("1234577AA"));
