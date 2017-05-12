#!/usr/bin/perl

use strict;
use warnings;
use boolean qw(true false);

use DateTime::Format::Natural;
use Test::More tests => 16;

{
    # Assert for prefixed dates that an extracted unit which is
    # partially invalid is not being passed to a DateTime wrapper.
    local $@;
    eval {
        my $parser = DateTime::Format::Natural->new;
        $parser->parse_datetime('+1XXXday');
        $parser->parse_datetime('-1dayXXX');
    };
    ok(!$@, 'prefixed date');
}

{
    # Assert that parse_datetime_duration() shrinks the date strings
    # and fails.
    my $parser = DateTime::Format::Natural->new;
    my @dt = $parser->parse_datetime_duration('mon to fri to sun');
    ok(!$parser->success, 'duration with substrings exceeding limit failed');
    is(@dt, 2, 'count of objects returned for shrinked duration');
}

{
    my ($parser, $warnings);

    local $SIG{__WARN__} = sub { $warnings = true };

    # Assert that a malformed formatted date with mixed separators previously
    # wrongly recognized as "m/d" format is rejected without warnings emitted.

    $warnings = false;
    $parser = DateTime::Format::Natural->new;
    $parser->parse_datetime('2011/04-12');
    ok(!$parser->success && !$warnings, 'checking of formatted date string end');

    $warnings = false;
    $parser = DateTime::Format::Natural->new;
    $parser->parse_datetime('2011/04-12 15:00');
    ok(!$parser->success && !$warnings, 'checking of formatted date word boundary');

    # Assert that a formatted date with an invalid month name which
    # contains non-letters is rejected without warnings emitted.

    $warnings = false;
    $parser = DateTime::Format::Natural->new;
    $parser->parse_datetime('2011-j6n-04');
    ok(!$parser->success && !$warnings, 'formatted date with non-letter in month name');
}

{
    # Assert that extract_datetime() returns expressions depending on context.
    my $parser = DateTime::Format::Natural->new;
    my $string = 'monday until friday';
    my $expression = $parser->extract_datetime($string);
    is($expression, 'monday', 'extract_datetime scalar');
    my @expressions = $parser->extract_datetime($string);
    is_deeply(\@expressions, [qw(monday friday)], 'extract_datetime list');
}

{
    # Assert that extract_datetime() looping through a grammar entry does not
    # match in more than one subentry for all tokens (previously broken for
    # this input string with the weekday_time grammar entry, at least).
    my $parser = DateTime::Format::Natural->new;
    my @expressions = $parser->extract_datetime('8am 4pm');
    is_deeply(\@expressions, [qw(8am 4pm)], 'extract with single grammar subentry');
}

{
    # Assert that regexes match only at word boundary when extracting relative durations.
    my $parser = DateTime::Format::Natural->new;

    my @expressions = $parser->extract_datetime('123first to last day of nov');
    ok(@expressions == 1 && $expressions[0] eq 'last day of nov', 'first to last duration word boundary begin');

    @expressions = $parser->extract_datetime('first to last day of nov456');
    ok(@expressions == 1 && $expressions[0] eq 'last day', 'first to last duration word boundary end');

    @expressions = $parser->extract_datetime('abc2012-11-01 18:00 to 20:00');
    ok(@expressions == 1 && $expressions[0] eq '18:00 to 20:00', 'from count to count duration word boundary begin');

    @expressions = $parser->extract_datetime('nov 1 to 2ndxyz');
    ok(@expressions == 1 && $expressions[0] eq 'nov 1', 'from count to count duration word boundary end');
}

{
    # Assert that date/grammar expressions do not overlap with duration ones.
    my $parser = DateTime::Format::Natural->new;

    my @expressions = $parser->extract_datetime('2012-12-31 to first to last day of 2013');
    is_deeply(\@expressions, ['2012-12-31', 'first to last day of 2013'], 'date overlapping duration');

    @expressions = $parser->extract_datetime('last day of 2012 to jan 1st to 31st');
    is_deeply(\@expressions, ['last day of 2012', 'jan 1st to 31st'], 'grammar overlapping duration');
}

{
    # Assert that rightmost matching token on left side of duration is used to determine the type.
    my $parser = DateTime::Format::Natural->new;
    my @expressions = $parser->extract_datetime('23:30 some text jan 19th to 20th');
    is_deeply(\@expressions, ['23:30', 'jan 19th to 20th'], 'last matching token in left duration substring');
}
