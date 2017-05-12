#!/usr/bin/perl -w

use warnings;
use strict;

use Test::More tests => 7;
use Test::LongString;
use Test::NoWarnings; # this catches our warnings like setting unknown properties

BEGIN { use_ok('Data::ICal'); }
BEGIN { use_ok('Data::ICal::Entry::Todo'); }

my $cal = Data::ICal->new();
my $vtodo = Data::ICal::Entry::Todo->new();
$vtodo->add_properties(
    summary   => "Some summary",
    url       => "http://example.com/todo",
    status    => "INCOMPLETE",
);
$cal->add_entry($vtodo);
my $before = $cal->as_string;

$cal = Data::ICal->new( data => $before );
is($cal->as_string, $before, "Round trip works through string");

ok(open(ICS, ">t/ics/roundtrip.ics"), "Wrote t/ics/roundtrip.ics");
print ICS $before;
close ICS;

$cal = Data::ICal->new( filename => "t/ics/roundtrip.ics" );
is($cal->as_string, $before, "Round trip works through file");
ok(unlink("t/ics/roundtrip.ics"), "File t/ics/roundtrip.ics removed");
