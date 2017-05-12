#!/usr/bin/perl -w

print "1..3\n";

use Date::Tie;

# example 1
    tie %date, 'Date::Tie';
	%date = ( year => 2001, month => 11, day => '09' );
	$date{year}++;
	$date{month} += 12;
print "not " if $date{year} . $date{month} . $date{day} ne '20031109';
print "ok 1\n";

# example 2
	$date = Date::Tie->new( year => 2001, month => 11, day => '09' );
	$date->{year}++;
	$date->{month} += 12;  # 2003-11-09
print "not " if $date{year} . $date{month} . $date{day} ne '20031109';
print "ok 2\n";

# example 3
    tie %a, 'Date::Tie', hour => 0, minute => 59;
	$a{minute}++;
print "not " if $a{hour} . $a{minute}  ne '0100';
print "ok 3\n";

1;