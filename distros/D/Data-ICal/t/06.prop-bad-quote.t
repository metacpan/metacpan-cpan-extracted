#!/usr/bin/perl -w

use warnings;
use strict;

use Test::More tests => 4;
use Test::LongString;
use Test::Warn;

BEGIN { use_ok('Data::ICal::Entry::Todo') }

my $todo = Data::ICal::Entry::Todo->new();
isa_ok($todo, 'Data::ICal::Entry::Todo');

$todo->add_property( summary => [ 'Sum it up.', { language => 'bla"bla'} ] );

my $str;

warning_like { $str = $todo->as_string( crlf => "\n") }
    {carped => qr(Invalid parameter value)}, 
    "Got a warning for fake property set";

is_string($str, <<END_VCAL, "Got the right output");
BEGIN:VTODO
SUMMARY;LANGUAGE=blabla:Sum it up.
END:VTODO
END_VCAL
