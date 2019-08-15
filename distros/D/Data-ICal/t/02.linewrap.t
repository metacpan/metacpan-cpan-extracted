#!/usr/bin/perl -w

use warnings;
use strict;

use Test::More tests => 8;
use Test::LongString;

BEGIN { use_ok('Data::ICal::Entry::Todo') }

my $todo = Data::ICal::Entry::Todo->new;
isa_ok($todo, 'Data::ICal::Entry::Todo');

my $hundreds_of_characters = "X" x 300;

is(length $hundreds_of_characters, 300);
cmp_ok(length $hundreds_of_characters, '>', 75, "the summary is bigger than the suggested line-wrap");

$todo->add_property(summary => $hundreds_of_characters);

lacks_string($todo->as_string, $hundreds_of_characters, "the long string isn't there");
unlike_string($todo->as_string, qr/[^\r\n]{76}/, "no lines are too long");

my $want = <<'END';
BEGIN:VTODO
SUMMARY:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
 XXXXXXXXXXX
END:VTODO
END

$want =~ s/\n/\r\n/g;

is($todo->as_string, $want, "expectations: met");

like_string($todo->as_string(fold => 0), qr/.{300}/, "no lines are too long".$todo->as_string(fold=>0));
