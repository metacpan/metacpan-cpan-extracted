#!perl
use strict;
use warnings;
use Test::More;
use Date::HolidayParser::iCalendar;
use FindBin;
use Data::Dumper;
use POSIX qw(tzset);

my $tests = 106;
my @timezones = qw(GMT CET EST);
if (defined $ENV{TZ})
{
	if(not grep($ENV{TZ},@timezones))
	{
		push(@timezones,$ENV{TZ});
	}
}
plan tests => ($tests*scalar(@timezones));

sub runTests
{
	my $parser = Date::HolidayParser::iCalendar->new("$FindBin::RealBin/testholiday");

	ok(defined $parser, "->new returned something usable");
	isa_ok($parser,'Date::HolidayParser::iCalendar');
	ok(defined $parser->get_manager_version,'get_manager_version returned something');
	ok(defined $parser->get_manager_capabilities,'get_manager_capabilities returned something');
	ok(eq_set($parser->get_months(2006),[3,4,5,12]),'->get_months(2006)');
	ok(eq_set($parser->list_events(2006),[3,4,5,12]),'->list_events(2006)');
	ok(eq_set($parser->get_monthinfo(2006,3),[13,27]),'->get_monthinfo(2006,3)');
	ok(eq_set($parser->get_monthinfo(2006,4),[2,16,30]),'->get_monthinfo(2006,4)');
	ok(eq_set($parser->get_monthinfo(2006,5),[17,21]),'->get_monthinfo(2006,5)');
	ok(eq_set($parser->get_monthinfo(2006,12),[17]),'->get_monthinfo(2006,12)');
	ok(eq_set($parser->list_events(2006,3),[13,27]),'->list_events(2006,3)');
	ok(eq_set($parser->list_events(2006,4),[2,16,30]),'->get_monthinfo(2006,4)');
	ok(eq_set($parser->list_events(2006,5),[17,21]),'->get_monthinfo(2006,5)');
	ok(eq_set($parser->list_events(2006,12),[17]),'->get_monthinfo(2006,12)');
	is_deeply($parser->get_dateinfo(2006,3,13),['DAY'],'->get_dateinfo(2006,3,13)');
	is_deeply($parser->get_dateinfo(2006,3,3),[],'->get_dateinfo(2006,3,3)');
	is_deeply($parser->get_timeinfo(2006,3,3,'DAY'),[],'->get_timeinfo(2006,3,3)');
	is_deeply($parser->list_events(2006,3,3),[],'->list_events(2006,3,3)');
	ok(@{$parser->get_timeinfo(2006,5,17,'DAY')} == 3,'Number of events on 2006,5,17,DAY');
	is_deeply($parser->get_timeinfo(2006,3,13,'DAY'),['D-HP-ICS-72-106-616'],'->get_timeinfo(2006,3,13)');
	ok(@{$parser->list_events(2006,5,17)} == 3,'Number of events on 2006,5,17,DAY');
	is_deeply($parser->list_events(2006,3,13),['D-HP-ICS-72-106-616'],'->list_events(2006,3,13)');
	my $event = {
		'SUMMARY' => 'Monday',
		'UID' => 'D-HP-ICS-72-106-616',
		'DTEND' => '20060313',
		'DTSTART' => '20060313'
	};
	is_deeply($parser->get_info('D-HP-ICS-72-106-616'),$event,'D-HP-ICS-72-106-616 get_info()');

	foreach my $e (qw(D-HP-ICS-106-106-612 D-HP-ICS-120-106-1950 D-HP-ICS-137-106-1398 D-HP-ICS-137-106-1845 D-HP-ICS-137-106-954 D-HP-ICS-141-106-1258 D-HP-ICS-141-106-2359 D-HP-ICS-351-106-2846 D-HP-ICS-86-106-616 D-HP-ICS-92-106-2066 D-HP-ICS-72-106-616))
	{
		ok($parser->exists($e),'exists('.$e.')');
		ok($parser->get_info($e),'get_info('.$e.')');
		my $info = $parser->get_info($e);
		ok($info->{UID} eq $e,'get_info('.$e.')->{UID} eq '.$e);
		ok(defined $info->{SUMMARY},'get_info('.$e.')->{SUMMARY}');
		ok($info->{$_} =~ /^\d+$/, 'get_info('.$e.')->{'.$_.'} is int') foreach qw(DTEND DTSTART);
		ok(keys(%{$info}) == 4,'4 keys in get_info('.$e.')');
	}

	is_deeply($parser->get_years,[],'get_years');
	ok(eval { $parser->set_prodid('meh');1;},'set_prodid doesn\'t crash');
	is($parser->get_manager_version,'01_capable','get_manager_version sanity');
	is_deeply($parser->get_manager_capabilities,[ 'LIST_DPI' ],'get_manager_capabilities sanity');
	ok(!defined($parser->get_info('INVALID_UID')),'get_info() on invalid UID returns undef');
	ok(!defined($parser->exists('INVALID_UID')),'exists() on invalid UID returns undef');
}

foreach my $tz (@timezones)
{
	$ENV{TZ} = $tz;
	tzset();
	runTests();
}

1;
