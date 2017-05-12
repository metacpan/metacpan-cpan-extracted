#!/usr/bin/perl -w

use warnings;
use strict;

use Test::More tests => 6;
use Test::LongString;
use Test::Warn;

BEGIN { use_ok('Data::ICal') }
BEGIN { use_ok('Data::ICal::Entry::Todo') }

my $todo = Data::ICal::Entry::Todo->new;
isa_ok($todo, 'Data::ICal::Entry::Todo');

my $cal = Data::ICal->new;
isa_ok($cal, 'Data::ICal');

$cal->add_entry($todo);

# breaking the abstraction, ah well
$cal->properties->{'prodid'} = [];

my $str;

warning_is { $str = $cal->as_string( crlf => "\n") }
    {carped => "Mandatory property for Data::ICal missing: prodid"}, 
    "Got a warning for missing mandatory property";

is_string($str, <<END_VCAL, "Got the 'right' output anyway");
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VTODO
END:VTODO
END:VCALENDAR
END_VCAL
