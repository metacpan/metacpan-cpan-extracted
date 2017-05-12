#!/usr/bin/perl -w

use Date::Tie;
use Time::Local qw( timegm );

my $test = 1;
sub test {
	if ($_[0] ne $_[1]) {
		print "not ok $test # $_[0] : $_[1]\n";
	}
	else {
		print "ok $test\n";
	}
	$test++;
}

print "1..29\n";

my $timestring = '2003-05-05 15:30:40-04';

# This is May 5th, 2003 at 3:30:40 pm  EDT.
# That translates to May 5th, 2003 at 7:30:40 pm UTC
# The epoch is 1052163040 (on unix systems)

$timestring =~ /^(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)([\+\-\d]+)$/;
##                  $1        $2     $3     $4     $5     $6   $7
##                 year      month   date   hour   min   sec    tz
my $tz = $7 . '00';

tie %date, 'Date::Tie', 
    tz     => $tz,
    year   => $1,
    month  => $2,
    day    => $3,
    hour   => $4,
    minute => $5,
    second => $6,
    ;

my $correct_epoch = timegm( $6, $5, $4, $3, $2 - 1, $1 - 1900 ) ;
my $correct_utc_epoch = $correct_epoch - ($7 * 60 * 60);

test 0 + $date{year}, 2003;
test 0 + $date{month}, 5;
test 0 + $date{day}, 5;
test 0 + $date{hour}, 15;
test 0 + $date{minute}, 30;
test 0 + $date{second}, 40;
test $date{tzhour}, '-04';
test 0 + $date{epoch}, $correct_epoch;
test 0 + $date{utc_epoch}, $correct_utc_epoch;

tie %date, 'Date::Tie',
   tz      => $tz,
   epoch   => $correct_epoch,
   ;

test 0 + $date{year}, 2003;
test 0 + $date{month}, 5;
test 0 + $date{day}, 5;
test 0 + $date{hour}, 15;
test 0 + $date{minute}, 30;
test 0 + $date{second}, 40;
test $date{tzhour}, '-04';
test 0 + $date{epoch}, $correct_epoch;
test 0 + $date{utc_epoch}, $correct_utc_epoch;

tie %date, 'Date::Tie',
   tz      => $tz,
   utc_epoch   => $correct_utc_epoch,
   ;

test 0 + $date{year}, 2003;
test 0 + $date{month}, 5;
test 0 + $date{day}, 5;
test 0 + $date{hour}, 15;
test 0 + $date{minute}, 30;
test 0 + $date{second}, 40;
test $date{tzhour}, '-04';
test 0 + $date{epoch}, $correct_epoch;
test 0 + $date{utc_epoch}, $correct_utc_epoch;

## Do we do the correct thing when decrementing the day by one?
my $old_epoch = $date{epoch};
my $old_utc_epoch = $date{utc_epoch};

$date{day}--;

test $date{epoch}, $old_epoch - 86400;
test $date{utc_epoch}, $old_utc_epoch - 86400;
