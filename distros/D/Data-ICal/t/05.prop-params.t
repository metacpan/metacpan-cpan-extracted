#!/usr/bin/perl -w

use warnings;
use strict;

use Test::More tests => 8;
use Test::LongString;
use Test::NoWarnings;

BEGIN { use_ok('Data::ICal::Entry::Todo') }

my $todo = Data::ICal::Entry::Todo->new();
isa_ok($todo, 'Data::ICal::Entry::Todo');

my $todo_prop = $todo->add_property( summary => [ 'Sum it up.', { language => "en-US", value => "TEXT" } ] ); 
isa_ok($todo_prop, 'Data::ICal::Entry::Todo', "Check if chaining is possible");

# example from RFC 2445 4.2.11
my $todo_props = $todo->add_properties( attendee => [ 'MAILTO:janedoe@host.com', 
    { member => [ 'MAILTO:projectA@host.com', 'MAILTO:projectB@host.com' ] } ]);
isa_ok($todo_props, 'Data::ICal::Entry::Todo', "Check if chaining is possible");

my $expect = <<'END_VCAL';
BEGIN:VTODO
ATTENDEE;MEMBER="MAILTO:projectA@host.com","MAILTO:projectB@host.com":MAILT
 O:janedoe@host.com
SUMMARY;LANGUAGE=en-US;VALUE=TEXT:Sum it up.
END:VTODO
END_VCAL

is_string($todo->as_string( crlf => "\n"), $expect, "Got the right output");

$todo = Data::ICal::Entry::Todo->new({
    summary  => [ 'Sum it up.', { language => "en-US", value => "TEXT" } ],
    attendee => [ 'MAILTO:janedoe@host.com', {
	member => [ 'MAILTO:projectA@host.com', 'MAILTO:projectB@host.com' ] } ],
});
isa_ok($todo, 'Data::ICal::Entry::Todo');
is_string($todo->as_string( crlf => "\n"), $expect, "Got the right output at once");
