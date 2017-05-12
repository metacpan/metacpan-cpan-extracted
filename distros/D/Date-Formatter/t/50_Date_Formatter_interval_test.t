#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;

BEGIN { 
    use_ok('Date::Formatter')
}

cmp_ok(Date::Formatter->createTimeInterval(years => 5)->pack(), '==',
       5 * 365 * 24 * 60 * 60,
       '... the correct time interval in seconds');
	   
cmp_ok(Date::Formatter->createTimeInterval(leapyears => 1)->pack(), '==',
       1 * 366 * 24 * 60 * 60,
       '... the correct time interval in seconds');	   
	   
cmp_ok(Date::Formatter->createTimeInterval(months => 10)->pack(), '==',
       10 * 30 * 24 * 60 * 60,
       '... the correct time interval in seconds');	
	   
cmp_ok(Date::Formatter->createTimeInterval(weeks => 20)->pack(), '==',
       20 * 7 * 24 * 60 * 60,
       '... the correct time interval in seconds');				   
	   
cmp_ok(Date::Formatter->createTimeInterval(days => 120)->pack(), '==',
       120 * 24 * 60 * 60,
       '... the correct time interval in seconds');						   
							   
cmp_ok(Date::Formatter->createTimeInterval(hours => 5)->pack(), '==',
       5 * 60 * 60,
       '... the correct time interval in seconds');	
	   
cmp_ok(Date::Formatter->createTimeInterval(minutes => 15)->pack(), '==',
       15 * 60,
       '... the correct time interval in seconds');	
	   
cmp_ok(Date::Formatter->createTimeInterval(seconds => 150)->pack(), '==',
       150,
       '... the correct time interval in seconds');			   	   
	
cmp_ok(Date::Formatter->createTimeInterval()->pack(), '==',
       1,
       '... the correct time interval in seconds');												   										   
													      	   
