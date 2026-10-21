#!perl -T

use Test::More tests => 19;

BEGIN {
	use_ok( 'Date::Holidays::BY' );
}

for my $f (qw( is_holiday is_business_day is_short_business_day )) {
	no strict 'refs';
	my $sub = \&{"Date::Holidays::BY::$f"};
	eval { $sub->( 2024, 2, 31 ) };
	like $@, qr/^Bad date: 2024-2-31/, "$f: 31 Feb";
	eval { $sub->( 2023, 2, 29 ) };
	like $@, qr/^Bad date: 2023-2-29/, "$f: 29 Feb, not leap year";
	eval { $sub->( 2024, 13, 1 ) };
	like $@, qr/^Bad date: 2024-13-1/, "$f: month 13";
	eval { $sub->( 2024, 4, 31 ) };
	like $@, qr/^Bad date: 2024-4-31/, "$f: 31 Apr";
	ok eval { $sub->( 2024, 2, 29 ); 1 }, "$f: 29 Feb, leap year";
	ok eval { $sub->( 2024, '02', '03' ); 1 }, "$f: zero-padded strings";
}
