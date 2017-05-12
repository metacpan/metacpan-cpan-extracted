#!/usr/bin/perl -w

use warnings;
use strict;

use Test::More tests => 6;
use Test::LongString;
use Test::Warn;

BEGIN { use_ok('Data::ICal::Entry::Todo') }

my $todo = Data::ICal::Entry::Todo->new();
isa_ok($todo, 'Data::ICal::Entry::Todo');

warnings_are { $todo->add_property( summary => 'Sum it up.' ) } 
             [], "No warning on real property set";

warnings_are { $todo->add_property( "x-summary" => 'Experimentally sum it up.' ) } 
             [], "No warning on experimental property set";

warning_is { $todo->add_property( summmmary => 'Summmm it up.' ) }
    {carped => "Unknown property for Data::ICal::Entry::Todo: summmmary"}, 
    "Got a warning for fake property set";

is_string($todo->as_string( crlf => "\n"), <<END_VCAL, "Got the right output");
BEGIN:VTODO
SUMMARY:Sum it up.
SUMMMMARY:Summmm it up.
X-SUMMARY:Experimentally sum it up.
END:VTODO
END_VCAL
