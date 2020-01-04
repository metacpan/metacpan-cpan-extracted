#!/usr/bin/perl -w

use warnings;
use strict;

use Test::More tests => 20;
use Test::LongString;
use Test::NoWarnings; # this catches our warnings like setting unknown properties

BEGIN { use_ok('Data::ICal') }

my $s = Data::ICal->new();

isa_ok($s, 'Data::ICal');

can_ok($s, qw/as_string add_entry entries/);

BEGIN { use_ok('Data::ICal::Entry::Todo') }

my $todo = Data::ICal::Entry::Todo->new();
isa_ok($todo, 'Data::ICal::Entry::Todo');
isa_ok($todo, 'Data::ICal::Entry');


can_ok($todo, qw/add_property add_properties properties/);


$todo->add_properties( url => 'http://example.com/todo1',
                        summary => 'A sample todo',
                        comment => 'a first comment',
                        comment => 'a second comment',
                        summary => 'This summary trumps the first summary'
                    
                    );


is(scalar @{$s->entries},0);
ok($s->add_entry($todo));
is(scalar @{ $s->entries},1);


is_string($s->as_string(crlf => "\n"), <<END_VCAL, "Got the right output");
BEGIN:VCALENDAR
VERSION:2.0
PRODID:Data::ICal $Data::ICal::VERSION
BEGIN:VTODO
COMMENT:a first comment
COMMENT:a second comment
SUMMARY:This summary trumps the first summary
URL:http://example.com/todo1
END:VTODO
END:VCALENDAR
END_VCAL

$todo->add_property( suMMaRy => "This one trumps number two, even though weird capitalization!");

is_string($s->as_string(crlf => "\n"), <<END_VCAL, "add_property is case insensitive");
BEGIN:VCALENDAR
VERSION:2.0
PRODID:Data::ICal $Data::ICal::VERSION
BEGIN:VTODO
COMMENT:a first comment
COMMENT:a second comment
SUMMARY:This one trumps number two\\, even though weird capitalization!
URL:http://example.com/todo1
END:VTODO
END:VCALENDAR
END_VCAL

BEGIN { use_ok('Data::ICal::Entry::Event') }

my $event = Data::ICal::Entry::Event->new();
isa_ok($event, 'Data::ICal::Entry::Event');
isa_ok($event, 'Data::ICal::Entry');


can_ok($event, qw/add_property add_properties properties/);


$event->add_properties( 
                        summary => 'Awesome party',
                        description => "at my \\ place,\nOn 5th St.;",
                        geo => '123.000;-0.001',
                    );

ok($s->add_entry($event));
is(scalar @{ $s->entries},2);

is_string($s->as_string(crlf => "\n"), <<END_VCAL, "got the right output");
BEGIN:VCALENDAR
VERSION:2.0
PRODID:Data::ICal $Data::ICal::VERSION
BEGIN:VTODO
COMMENT:a first comment
COMMENT:a second comment
SUMMARY:This one trumps number two\\, even though weird capitalization!
URL:http://example.com/todo1
END:VTODO
BEGIN:VEVENT
DESCRIPTION:at my \\\\ place\\,\\nOn 5th St.\\;
GEO:123.000;-0.001
SUMMARY:Awesome party
END:VEVENT
END:VCALENDAR
END_VCAL
