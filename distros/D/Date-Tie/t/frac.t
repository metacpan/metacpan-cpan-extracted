#!/usr/bin/perl -w

use Date::Tie;

my $test = 1;
tie my %d, 'Date::Tie';

sub test {
	if ($_[0] ne $_[1]) {
		print "not ok $test # $_[0] : $_[1]\n";
	}
	else {
		print "ok $test\n";
	}
	$test++;
}

print "1..32\n";

$d{year} = 2001;
$d{month} = 10;
$d{day} = 20;
test "$d{year}$d{month}$d{day}", "20011020";

$d{hour} = 10;
$d{minute} = 11;
$d{second} = 12;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute}$d{second}", "20011020T101112";

# is fraction initialized to zero?
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute}$d{second} $d{frac}", "20011020T101112 .0";

$d{frac} = 0.123;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute}$d{second} $d{frac}", "20011020T101112 .123";
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute}" . ( $d{second} + $d{frac} ), 
     "20011020T101112.123";

$d{frac} += 0.4;  # positive
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute}$d{second} $d{frac}", "20011020T101112 .523";

$d{frac} += 0.7;  # positive overflow
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute} $d{second} $d{frac}", "20011020T1011 13 .223";

$d{frac} -= 0.7;   # negative
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute} $d{second} $d{frac}", "20011020T1011 12 .523";

$d{frac} -= 15.4;  # negative overflow
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute} $d{second} $d{frac}", "20011020T1010 57 .123";

$d{frac} -= 117.123;  # negative overflow
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute} $d{second} $d{frac}", "20011020T1009 00 .0";

$d{frac} += 3600;   # integer
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute} $d{second} $d{frac}", "20011020T1109 00 .0";

$d{frac} += 3600.00112233;   # big overflow, high precision
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute} $d{second} $d{frac}", "20011020T1209 00 .00112233";

# setting fractional seconds through {frac_second} will work
$d{frac_second} += 14.56;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute} $d{second} $d{frac}", "20011020T1209 14 .56112233";
$d{frac} += 0.1;  # test mixing frac and second
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute} $d{second} $d{frac}", "20011020T1209 14 .66112233";

# overflowing frac goes to second
$d{frac} = 1;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute} $d{second} $d{frac}", "20011020T1209 15 .0";

$d{frac} = 0.1;

# fractional day is not allowed
# $d{frac_day} += 1.3;   # 1 day, 3 * 2.4 hours = 7.2 hours = 7 hours, 12 minutes
# test "$d{year}$d{month}$d{day}T$d{hour}$d{minute} $d{second} $d{frac}", "20011021T1921 15 .1";

# fractional month and year are not allowed anymore
# $d{frac_month} += 1.3;
# test "$d{year}$d{month}$d{day}T$d{hour}$d{minute} $d{second} $d{frac}", "20011121T1209 15 .1";
# $d{frac_year} += 1.3;
# test "$d{year}$d{month}$d{day}T$d{hour}$d{minute} $d{second} $d{frac}", "20021121T1209 15 .1";

# fractional epoch is allowed
$d{frac_epoch} += 1.3;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute} $d{second} $d{frac}", "20011020T1209 16 .4";

# fractional minute, hour are allowed
$d{frac_hour} += 1.3;  # 1 hour, 18 minutes
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute} $d{second} $d{frac}", "20011020T1327 16 .4";
$d{frac_minute} += 1.3;  # 1 minute, 18 seconds
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute} $d{second} $d{frac}", "20011020T1328 34 .4";

# fractional timezone is not allowed 
# $d{tzhour} += 1.5; # 1 hour, 30 minutes
# test "$d{year}$d{month}$d{day}T$d{hour}$d{minute} $d{second} $d{frac}", "20011021T2210 34 .4";

# comma as decimal separator
$d{frac_second} = '1,3';
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute} $d{second} $d{frac}", "20011020T1328 01 .3";

# test negative frac_* 
$d{frac_second} = '-1,4';
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute} $d{second} $d{frac}", "20011020T1327 58 .6";

# test zero frac_* 
$d{frac_minute} = 0;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute} $d{second} $d{frac}", "20011020T1300 00 .0";

# test frac_* printing 
$d{frac_hour} += 1.2345678;
test "$d{frac_hour}", "14.2345678";

# minute negative overflow
$d{frac_minute} -= 3;  # -3 minutes = -0.05 hour => 14,1845678
test "$d{frac_hour}", "14.1845678";


# minute negative overflow
$d{frac_minute} -= 60;  # -1 hour
test "$d{frac_hour}", "13.1845678";

# minute negative overflow
$d{frac_minute} -= 600;  # -10 hours
test "$d{frac_hour}", "03.1845678";

# minus zero should not change it
$d{frac_hour} -= 0;
test "$d{frac_hour}", "03.1845678";

$d{frac_minute} -= 0;
test "$d{frac_hour}", "03.1845678";

# zero it
$d{frac_hour} = 0;
test "$d{frac_hour}", "00.0";

# very small value / very big value
$d{epoch} = 100000;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute} $d{second} $d{frac}", "19700102T0346 40 .0";
$d{frac_epoch} = '100000,000001';
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute} $d{second} $d{frac}", "19700102T0346 40 .000001";

# we will not test this because it is platform-dependent
# $d{frac_epoch} = 100000 + (0.000001 / 3);
# test "$d{year}$d{month}$d{day}T$d{hour}$d{minute} $d{second} $d{frac}", "19700102T0346 40 .000001";

$d{frac_epoch} -= 10.0000001;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute} $d{second} $d{frac}", "19700102T0346 30 .0000009";

# non-fatal errors:
# - non-integer values
$d{second} -= 10.0000001;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute} $d{second} $d{frac}", "19700102T0346 20 .0000009";

1;

__END__

# examples in the documentation

    $d{frac}   = 0;
    $d{hour}   = 13;
    $d{minute} = 30;        # 0.5 hour
    $d{second} = 00;       
    print $d{frac_hour};    # 13.5

    $d{frac_minute} = 17.3;
    print "$d{minute}:$d{second}";   # 17:18
    $d{frac_minute} -= 0.2;
    print "$d{minute}:$d{second}";   # 17:12

    $d{epoch} = 1234567;
    $d{frac}  = 0.7654321;
    print $d{frac_epoch};     # 1234567.7654321

1;
