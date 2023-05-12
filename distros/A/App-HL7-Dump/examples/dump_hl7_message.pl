#!/usr/bin/env perl

use strict;
use warnings;

use App::HL7::Dump;
use File::Temp qw(tempfile);
use IO::Barf qw(barf);

# Test data.
my $hl7 = <<'END';
MSH|^~\&|FROM|Facility #1|TO|Facility #2|20160403211012||ORM^O01|MSGID20160403211012|P|1.0
PID|||11111||Novak^Jan^^^Ing.||19680821|M|||Olomoucká^^Brno^^61300^Czech Republic|||||||
PV1||O|OP^PAREG^||||1234^Clark^Bob|||OP|||||||||2|||||||||||||||||||||||||20160403211012|
ORC|NW|20160403211012
OBR|1|20160403211012||003038^Urinalysis^L|||20160403211012
END

# Barf to temp file.
my (undef, $file) = tempfile();
barf($file, $hl7);

# Arguments.
@ARGV = (
        $file,
);

# Run.
App::HL7::Dump->new->run;

# Output:
# MSH-1:|
# MSH-2:^~\&
# MSH-3:FROM
# MSH-4:Facility #1
# MSH-5:TO
# MSH-6:Facility #2
# MSH-7:20160403211012
# MSH-9:ORM^O01
# MSH-10:MSGID20160403211012
# MSH-11:P
# MSH-12:1.0
# PID-3:11111
# PID-5:Novak^Jan^^^Ing.
# PID-7:19680821
# PID-8:M
# PID-11:Olomoucká^^Brno^^61300^Czech Republic
# PV1-2:O
# PV1-3:OP^PAREG
# PV1-7:1234^Clark^Bob
# PV1-10:OP
# PV1-19:2
# PV1-44:20160403211012
# ORC-1:NW
# ORC-2:20160403211012
# OBR-1:1
# OBR-2:20160403211012
# OBR-4:003038^Urinalysis^L
# OBR-7:20160403211012