#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 22;
use Test::Exception;

BEGIN { 
    use_ok('Date::Formatter')
}

# run the date formatter through a ringer

like(Date::Formatter->now()->createDateFormatter("(hh):(mm):(ss) (MM)/(DD)/(YYYY)"), 
	qr/^\d{1,2}:\d\d:\d\d \d{1,2}\/\d{1,2}\/\d\d\d\d$/,
	'... formatter matches output');

like(Date::Formatter->now()->createDateFormatter("(hh):(mm) (D), (M) (DD), (YYYY)"), 
	qr/^\d{1,2}:\d\d \w+, \w+ \d{1,2}, \d\d\d\d$/,
	'... formatter matches output');

like(Date::Formatter->now()->createDateFormatter("(hh):(mm) (DD)-(MM)-(YY)"), 
	qr/^\d{1,2}:\d\d \d{1,2}-\d{1,2}-\d\d$/,
	'... formatter matches output');

like(Date::Formatter->now()->createDateFormatter("(MM)/(DD)/(YYYY) (hh):(mm):(ss)"), 
	qr/^\d{1,2}\/\d{1,2}\/\d\d\d\d \d{1,2}:\d\d:\d\d$/,
	'... formatter matches output');

like(Date::Formatter->now()->createDateFormatter("(MM).(DD).(YYYY) (hh):(mm):(ss) (T) (O)"), 
	qr/^\d{1,2}\.\d{1,2}\.\d\d\d\d \d{1,2}:\d\d:\d\d (a|p)\.m\. \-?\d\d\d\d$/,
	'... formatter matches output');

like(Date::Formatter->now()->createDateFormatter("(D) (M)  (DD) (hh):(mm):(ss) (YYYY)"), 
	qr/^\w+ \w+  \d{1,2} \d{1,2}:\d\d:\d\d \d\d\d\d$/,
	'... formatter matches output');
	
# test sharing of date formatters between object	
# does not being the object environment across that sharing
	
my $date = Date::Formatter->now();
isa_ok($date, "Date::Formatter");

$date->createDateFormatter("(hh):(mm):(ss) (MM)/(DD)/(YYYY)");

can_ok($date, 'getDateFormatter');
my $formatter = $date->getDateFormatter();
is(ref($formatter), 'CODE', '... this is a code reference');

my $other_date = Date::Formatter->createTimeInterval(days => 2, hours => 30, minutes => 10);
isa_ok($other_date, "Date::Formatter");

can_ok($other_date, 'setDateFormatter'); 
$other_date->setDateFormatter($formatter);

like("$date", qr/^\d{1,2}:\d\d:\d\d \d{1,2}\/\d{1,2}\/\d\d\d\d$/, '... formatter matches expected output');
like("$other_date", qr/^\d{1,2}:\d\d:\d\d \d{1,2}\/\d{1,2}\/\d\d\d\d$/, '... formatter (from other object) matches expected output');
	
isnt("$date", "$other_date", '... the formats match, but the dates dont');
	
# test using other delimiters for formatters

my $date2 = Date::Formatter->now();
$date2->useShortNames();

like($date2->createDateFormatter('{D} {M}  {DD} {hh}:{mm}:{ss} {YYYY}', qr/{|}/), 
	qr/^\w{3} \w{3}  \d{1,2} \d{1,2}:\d\d:\d\d \d\d\d\d$/,
	'... formatter (with other delimiters) matches output w/ short names');
	
$date2->useLongNames();
$date2->useShortMonthNames();

like($date2->createDateFormatter('{D} {M}  {DD} {hh}:{mm}:{ss} {YYYY}', qr/{|}/), 
	qr/^\w{3,} \w{3}  \d{1,2} \d{1,2}:\d\d:\d\d \d\d\d\d$/,
	'... formatter (with other delimiters) matches output w/ short month names');		

$date2->useLongMonthNames();
$date2->useShortDayNames();	
	
like($date2->createDateFormatter('{D} {M}  {DD} {hh}:{mm}:{ss} {YYYY}', qr/{|}/), 
	qr/^\w{3} \w{3,}  \d{1,2} \d{1,2}:\d\d:\d\d \d\d\d\d$/,
	'... formatter (with other delimiters) matches output w/ short day names');	

$date2->useLongDayNames();	
	
like($date2->createDateFormatter('{D} {M}  {DD} {hh}:{mm}:{ss} {YYYY}', qr/{|}/), 
	qr/^\w{3,} \w{3,}  \d{1,2} \d{1,2}:\d\d:\d\d \d\d\d\d$/,
	'... formatter (with other delimiters) matches output w/ long names');										

	
# test some execptions	
throws_ok {
	$date->setDateFormatter()
} qr/^Insufficient Arguments/, '... this throws an exception';
	
throws_ok {
	$date->setDateFormatter("Fail")
} qr/^Insufficient Arguments/, '... this throws an exception';	
	
throws_ok {
	$date->setDateFormatter([])
} qr/^Insufficient Arguments/, '... this throws an exception';	
