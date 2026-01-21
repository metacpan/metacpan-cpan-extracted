#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Date::Parse::Modern;

# All the test times are assuming PST (-0800) so we force that TZ
$Date::Parse::Modern::LOCAL_TZ_OFFSET = "-28800";

is(strtotime('foo'), undef, 'Bogus string');
is(strtotime('')   , undef, 'Empty string');
is(strtotime(undef), undef, 'Undef');
is(strtotime(12345), undef, 'Numeric string');

# This will vary based on a users timezone
is(strtotime('1970-01-01 00:00:00 UTC') , 0    , 'Epoch with time');
is(strtotime('1970-01-01 00:00:01 UTC') , 1    , 'Epoch + 1');

# General tests
is(strtotime('1979-02-24')                 , 288691200        , 'YYYY-MM-DD');
is(strtotime('1970-01-01')                 , 28800            , '1970-01-01');
is(strtotime('1970-01-01 UTC')             , 0                , '1970-01-01 UTC');
is(strtotime('1970-01-01 00:00:00')        , 28800            , '1970-01-01 00:00:00');
is(strtotime('1970-01-01 00:00:00 UTC')    , 0                , '1970-01-01 00:00:00 UTC');
is(strtotime('1970-01-01 00:00:01')        , 28801            , '1970-01-01 00:00:01');
is(strtotime('1979-2-24')                  , 288691200        , 'YYYY-M-DD');
is(strtotime('1979-2-4')                   , 286963200        , 'YYYY-M-D');
is(strtotime('1979/04/16')                 , 293097600        , 'YYYY/MM/DD');
is(strtotime('1979/4/6')                   , 292233600        , 'YYYY/M/D');
is(strtotime('12-24-1999')                 , 946022400        , 'MM-DD-YYYY');
is(strtotime('2-4-1999')                   , 923040000        , 'M-D-YYYY');
is(strtotime('10-4-1999')                  , 923731200        , 'MM-D-YYYY');
is(strtotime('Sat May  8 21:24:31 2021')   , 1620537871       , 'Human text string');
is(strtotime('2000-02-29T12:34:56')        , 951856496        , 'ISO 8601');
is(strtotime('1995-01-24T09:08:17.1823213'), 790967297.1823213, 'ISO 8601 with milliseconds');
is(strtotime('20020722T100000Z')           , 1027332000       , 'ISO 8601 all run together');
is(strtotime('January 5 2023 12:53 am')    , 1672908780       , 'Textual month name');
is(strtotime('January 9 2019 12:53 pm')    , 1547067180       , 'Textual month name with PM');
is(strtotime('21/dec/93 17:05')            , 756522300        , 'Short form 1');
is(strtotime('dec/21/93 17:05')            , 756522300        , 'Short form 2');
is(strtotime('Dec/21/1993 17:05:00')       , 756522300        , 'Short form 3');
is(strtotime('dec 21 1994 17:05')          , 788058300        , 'MMM DD YYYY');
is(strtotime('dec 21 94 17:05')            , 788058300        , 'MMM DD YY');
is(strtotime('dec 21 94 17:05 GMT')        , 788029500        , 'MMM DD YY text timezone');
is(strtotime('dec 21 94 17:05 -1700')      , 788090700        , 'MMM DD YY numeric timezone');
is(strtotime('June 1st 2020')              , 1590998400       , 'One digit day with a st/th/rd after it');
is(strtotime('June 27th 2020')             , 1593244800       , 'Two digit day with a st/th/rd after it');

# Bugs
is(strtotime('11/23/2025 08:00 PM'), 1763956800, 'Github issue #2');

cmp_ok(strtotime('May  4 01:04:16')         , '>=', 1683187456 , 'Text date WITHOUT year');
cmp_ok(strtotime('10:00:00')                , '>=', 1673632800 , 'Time only');
cmp_ok(strtotime('21/dec 17:05')            , '>=', 1703207100 , 'Short form 4 no year');
cmp_ok(strtotime('Feb  9 18:47:58')         , '>=', 1675997278 , 'Modern syslog no year');

# Zulu timezone tests
is(strtotime('1994-11-05T13:15:30Z')  , 784041330 , 'ISO 8601 T+Z');
is(strtotime('[2020-01-24T09:08:17Z]'), 1579885697, 'ISO 8601 T+Z in brackets');
is(strtotime('2002-07-22 10:00:00 Z') , 1027332000, 'ISO 8601 HH:MM Z');
is(strtotime('2002-07-22 10:00Z')     , 1027332000, 'ISO 8601 HH:MMZ');

# Timezone related tests
is(strtotime('Mon May 10 11:09:36 MDT 2021')          , 1620666576  , 'Textual timezone 1');
is(strtotime('Jul 22 10:00:00 UTC 2002')              , 1027332000  , 'UTC timezone');
is(strtotime('Wed, 16 Jun 94 07:29:35 CST')           , 771773375   , 'Textual timezone 2');
is(strtotime('Mon, 14 Nov 1994 11:34:32 -0500 (EST)') , 784830872   , 'Numeric and textual TZ offset');
is(strtotime('Thu, 13 Oct 94 10:13:13 +0700')         , 782017993   , 'Numeric timezone offset four digits');
is(strtotime('Thu, 09 Sep 96 11:12:13 -500')          , 842285533   , 'Numeric timezone offset three digits');
is(strtotime('Fri Dec 17 00:00:00 1901 GMT')          , -2147212800 , 'Textual timezone after year 1901');
is(strtotime('Tue Jan 16 23:59:59 2048 GMT')          , 2462831999  , 'Textual timezone after year 2048');
is(strtotime('25/Jan/2023:11:15:40 -0800')            , 1674674140  , 'Run together Apache format');
is(strtotime('2023-01-18T05:04:08-0500')              , 1674036248  , 'ISO 8601 with numeric TZ offset');
is(strtotime('Tue Nov 18 12:06:16 PM CST 2025')       , 1763489176  , 'PM and a Timezone');

# Check the extremes
is(strtotime('2800-06-06'), 26205840000, 'Way in the future');
is(strtotime('1800-06-06'), -5351155200, 'Way in the past');

# Not using this right now, it's just for testing
#is(sub_has_errors('good'), "", 'good');
#is(sub_has_errors('bad'),  "", 'bad');

done_testing();

# Returns any syntax error if found, or "" on success
sub sub_has_errors {
	no strict "refs";
	my $sub_name = shift();

	eval { &$sub_name(); };

	my $err = $@;
	$err =~ s/\s+$//;

	return $err;
}

sub good {
	return 1;
}

sub bad {
	bogus_sub();
	return 1;
}
