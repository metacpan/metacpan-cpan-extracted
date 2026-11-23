use strict;
use warnings;
use Test::Most;
use Test::Mojo;
use Database::BI::Util;

# The fast paths for plain numbers and ISO dates must give exactly what the
# full readings give.  One case per partition, at its boundary.

Test::Mojo->new('Database::BI');
my $KEY = \&Database::BI::Controller::Dashboard::_filter_date_key;

# parse_number: plain decimals take the fast path, everything else the old one.
my %number = (
	'0'          => 0,
	'-5.25'      => -5.25,
	'007'        => 7,
	'1.'         => undef,	# no digits after the point: not a plain decimal
	'.5'         => undef,
	'1,000'      => 1000,	# dressed up: the full path
	'(5)'        => -5,
	"1\n"        => 1,	# not plain (\z), so the full path strips the newline, as it always did
	"\x{FF11}"   => undef,	# a non-ASCII digit is not [0-9]
);
for my $text (sort keys %number) {
	my $got = Database::BI::Util::parse_number($text);
	is($got, $number{$text}, 'parse_number(' . ($text =~ s/[^\x20-\x7e]/?/gr) . ')');
}

# 300 integer digits is the fast path's edge; 301 goes the long way, and a
# number past a double's range is still refused there.
ok(defined Database::BI::Util::parse_number('1' x 300), '300 digits is a number');
ok(defined Database::BI::Util::parse_number('1' x 301), '301 digits is a number on the full path');
ok(!defined Database::BI::Util::parse_number('9' x 400), 'past the range of a double is none');

# _filter_date_key: one match, the same key as _date_key(_to_iso_date(...)).
is($KEY->('2026-01-05', 10), '2026-01-05', 'a day at day precision');
is($KEY->('2026-01-05T09:15:00Z', 19), '2026-01-05T09:15:00', 'a timestamp at second precision');
is($KEY->('2026-01-05', 19), '2026-01-05T00:00:00', 'a day at second precision starts the day');
is($KEY->('1/5/2026', 10), '2026-01-05', 'M/D/YYYY is rewritten first');
is($KEY->('13/45/2026', 10), '2026-13-45', 'the pattern checks no calendar, as before');
is($KEY->('x', 10), 'x', 'text is its own key');
is($KEY->('', 10), '', 'empty is its own key');

done_testing;
