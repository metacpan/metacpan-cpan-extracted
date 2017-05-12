use Test::Most 0.25;

use Date::Easy;
use Time::Piece;


my $t = Date::Easy::Date->new;
isa_ok $t, 'Date::Easy::Date', 'ctor with no args';
isa_ok $t, 'Date::Easy::Datetime', 'inheritance test';

is $t->second, 0, "::Date truncates seconds";
is $t->minute, 0, "::Date truncates minutes";
is $t->hour,   0, "::Date truncates hours";

my @tvals = localtime;
is $t->day,   $tvals[Time::Piece::c_mday],        "default ::Date is today's day";
is $t->month, $tvals[Time::Piece::c_mon] + 1,     "default ::Date is today's month";
is $t->year,  $tvals[Time::Piece::c_year] + 1900, "default ::Date is today's year";

my $FMT = '%Y%m%d';
ok $t == today, "today function matches default ctor";
is today->strftime($FMT), localtime->strftime($FMT), "today function actually returns today"
		or diag "today returns ",today->strftime($FMT);


# with 3 args, ctor should just build that date

my @TRIPLE_ARGS = qw< 19940203 20010905 19980908 19691231 20360229 >;
foreach (@TRIPLE_ARGS)
{
	my ($y, $m, $d) = /^(\d{4})(\d{2})(\d{2})$/;
	$m =~ s/^0+//; $d =~ s/^0+//;					# more natural, and avoids any chance of octal number errors
	$t = Date::Easy::Date->new($y, $m, $d);
	is $t->strftime($FMT), $_, "successfully constructed: $_";
}


# make sure we return a proper object even in list context
my @t = Date::Easy::Date->new;
is scalar @t, 1, 'ctor not returning multiple values in list context';
isa_ok $t[0], 'Date::Easy::Date', 'ctor in list context';


done_testing;
