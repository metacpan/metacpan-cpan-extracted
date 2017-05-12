#!/usr/bin/perl -w

use warnings;
use strict;

use Test::More tests => 4;
use Test::LongString;
use Test::NoWarnings;

use Data::ICal;
use Data::ICal::Entry::Todo;
my $s = Data::ICal->new( );
my $todo = Data::ICal::Entry::Todo->new( );
$todo->add_properties(
    url => 'http://example.com/todo1',
    summary => 'A sample todo',
    comment => 'a first comment',
    comment => 'a second comment',
    summary => 'This summary trumps the first summary'
);
$s->add_entry($todo);

my $expect = <<END_VCAL;
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

is_string($s->as_string( crlf => "\n"), $expect, "crlf \\n works as expected");

$expect =~ s/\n/\r\n/g;

is_string($s->as_string( crlf => "\r\n"), $expect, "crlf \\r\\n works as expected");
is_string($s->as_string, $expect, "No arguments is \\r\\n");
