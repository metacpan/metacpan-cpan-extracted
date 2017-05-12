#!/usr/bin/perl -w

use warnings;
use strict;

use Test::More tests => 7;
use Test::LongString;
use Test::NoWarnings;

my $encoded_vcal_in = <<END_VCAL;
BEGIN:VCALENDAR
VERSION:1.0
PRODID:Data::ICal @{[$Data::ICal::VERSION]}
BEGIN:VTODO
DESCRIPTION;ENCODING=QUOTED-PRINTABLE:interesting things         =0D=0AYeah=
!!=3D =63bla=0D=0A=0D=0A=0D=0AGo team syncml!=0D=0A=0D=0A=0D=0A
END:VTODO
END:VCALENDAR
END_VCAL

my $encoded_vcal_out = <<END_VCAL;
BEGIN:VCALENDAR
VERSION:1.0
PRODID:Data::ICal @{[$Data::ICal::VERSION]}
BEGIN:VTODO
DESCRIPTION;ENCODING=QUOTED-PRINTABLE:interesting things         =0D=0AYeah!!=3D cbla=0D=0A=0D=0A=0D=0AGo team syncml!=0D=0A=0D=0A=0D=0A
END:VTODO
END:VCALENDAR
END_VCAL

my $decoded_desc = <<'END_DESC';
interesting things         
Yeah!!= cbla


Go team syncml!


END_DESC

BEGIN { use_ok('Data::ICal') }

my $cal = Data::ICal->new(data => $encoded_vcal_in, vcal10 => 1);

isa_ok($cal, 'Data::ICal');

is_string($cal->entries->[0]->property("description")->[0]->decoded_value, $decoded_desc);

$cal = Data::ICal->new;

BEGIN { use_ok 'Data::ICal::Entry::Todo' }

$cal = Data::ICal->new(vcal10 => 1);

isa_ok($cal, 'Data::ICal');

my $todo = Data::ICal::Entry::Todo->new;
$cal->add_entry($todo);

$todo->add_property(description => $decoded_desc);

$cal->entries->[0]->property('description')->[0]->encode('QUotED-PRintabLE');
is($cal->as_string( crlf => "\n"), $encoded_vcal_out);


__END__
possibly useful later
DESCRIPTION;ENCODING=QUOTED-PRINTABLE;CHARSET=UTF-8:interesting thi=
ngs         =0D=0A=
Yeah!!=3D =C3=AAtre=0D=0A=
=0D=0A=
=0D=0A=
Go team syncml!=0D=0A=
=0D=0A=
=0D=0A=
END_DESC

