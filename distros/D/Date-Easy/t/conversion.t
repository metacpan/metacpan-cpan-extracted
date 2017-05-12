use Test::Most 0.25;

use Date::Easy;

use Time::Piece;

# local test modules
use File::Spec;
use Cwd 'abs_path';
use File::Basename;
use lib File::Spec->catdir(dirname(abs_path($0)), 'lib');
use DateEasyTestUtil qw< is_true is_false >;


# test date: 3 Feb, 2001  [04:05:06]
my $d  = Date::Easy::Date    ->new(2001, 2, 3);
my $dt = Date::Easy::Datetime->new(2001, 2, 3, 4, 5, 6);
my ($class, $epoch, $tp, $d_tp, $dt_tp);


# datetime: convert to Time::Piece
$class = 'Time::Piece';
$tp = $dt->as($class);
isa_ok $tp, $class, "converted $class";

is $tp->year, 2001, "$class from datetime year is correct";
is $tp->mon,  2,    "$class from datetime month is correct";
is $tp->mday, 3,    "$class from datetime day is correct";
is $tp->hour, 4,    "$class from datetime hour is correct";
is $tp->min,  5,    "$class from datetime minute is correct";
is $tp->sec,  6,    "$class from datetime second is correct";


# datetime: convert from Time::Piece
$class = 'Time::Piece';
$epoch = 905274900;				# Tue Sep  8 10:15:00 1998, but it doesn't really matter

$tp = localtime $epoch;
isa_ok $tp, 'Time::Piece', 'sanity check (local)';
$dt_tp = Date::Easy::Datetime->new($tp);
isa_ok $dt_tp, 'Date::Easy::Datetime', "datetime converted from $class";
is_true $dt_tp->is_local, "local flag preserved after conversion from Time::Piece";
is $dt_tp->epoch, $tp->epoch, "epoch seconds correct after conversion from Time::Piece";

$tp = gmtime $epoch;
isa_ok $tp, 'Time::Piece', 'sanity check (GMT)';
is_false $tp->[Time::Piece::c_islocal], 'sanity check (local flag)';
$dt_tp = Date::Easy::Datetime->new($tp);
isa_ok $dt_tp, 'Date::Easy::Datetime', "datetime converted from $class";
is_true $dt_tp->is_gmt, "GMT flag preserved after conversion from Time::Piece";
is $dt_tp->epoch, $tp->epoch, "epoch seconds correct after conversion from Time::Piece";


# date: convert to Time::Piece
$class = 'Time::Piece';
$tp = $d->as($class);
isa_ok $tp, $class, "converted $class";

is $tp->year, 2001, "$class from date year is correct";
is $tp->mon,  2,    "$class from date month is correct";
is $tp->mday, 3,    "$class from date day is correct";
is $tp->hour, 0,    "$class from date hour is correct";
is $tp->min,  0,    "$class from date minute is correct";
is $tp->sec,  0,    "$class from date second is correct";


# date: convert from Time::Piece
$class = 'Time::Piece';
# same epoch as above, including time (which should be thrown away)

$tp = gmtime $epoch;
isa_ok $tp, 'Time::Piece', 'sanity check (date)';
$d_tp = Date::Easy::Date->new($tp);
isa_ok $d_tp, 'Date::Easy::Datetime', "datetime converted from $class";
is_true $d_tp->is_gmt, "GMT flag always on for dates";
is $d_tp->strftime("%Y/%m/%d"), "1998/09/08", "date correct after conversion from Time::Piece";
is $d_tp->hour,   0, "time zero after conversion from Time::Piece (hour)";
is $d_tp->minute, 0, "time zero after conversion from Time::Piece (min)";
is $d_tp->second, 0, "time zero after conversion from Time::Piece (sec)";


# datetime: convert to string via short spec
is $dt->as('/Ymd'), '2001/02/03', "successful short spec conversion: date with /";
is $dt->as(':HMS'), '04:05:06',   "successful short spec conversion: time with :";
is $dt->as(' wWj'), '6 05 034',   "successful short spec conversion: totally wacky";


done_testing;
