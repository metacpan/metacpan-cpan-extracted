#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use App::HL7::Send;
use File::Temp qw(tempfile);
use IO::Barf qw(barf);

# Arguments.
if (@ARGV < 1) {
        print STDERR "Usage: $0 host port\n";
        exit 1;
}
my $host = $ARGV[0];
my $port = $ARGV[1] || 2575;

# Test ORM data for dcm4chee.
my $hl7 = <<'END';
MSH|^~\&|FROM|Facility #1|TO|Facility #2|20160403211012||ORM^O01|MSGID20160403211012|P|1.0
PID|||11111||Novak^Jan^^^Ing.||19680821|M|||Olomoucká^^Brno^^61300^Czech Republic|||||||
PV1||O|OP^PAREG^||||1234^Clark^Bob|||OP|||||||||2|||||||||||||||||||||||||20160403211012|
ORC|NW|A100Z^MESA_ORDPLC|B100Z^MESA_ORDFIL||SC||1^once^^20160101121212^^S||200008161510|^ROSEWOOD^RANDOLPH||7101^ESTRADA^JAIME^P^^DR||(314)555-1212|200008161510||922229-10^IHE-RAD^IHE-CODE-231||
OBR|1|A100Z^MESA_ORDPLC|B100Z^MESA_ORDFIL|P1^Procedure 1^ERL_MESA^X1_A1^SPAction Item X1_A1^DSS_MESA|||||||||xxx||Radiology^^^^R|7101^ESTRADA^JAIME^P^^DR||XR999999|RP123456|SPS123456||||ES|||1^once^^20160101121212^^S|||WALK|||||||||||A|||RP_X1^RP Action Item RP_X1^DSS_MESA
ZDS|1.2.1^100^Application^DICOM
END

# Barf to temp file.
my (undef, $file) = tempfile();
barf($file, $hl7);

# Arguments (dcm4chee).
@ARGV = (
        $host,
        $port,
        $file,
);

# Run.
App::HL7::Send->new->run;

# Output:
# Message was send.