
###
# Cz::Cstocs.pm

### no utf8;

BEGIN { $| = 1; print "1..31\n"; }
END {print "not ok 1\n" unless $loaded_cstocs;}

###

BEGIN { print "Loading module Cz::Cstocs\n"; }

use Cz::Cstocs;
$loaded_cstocs = 1;
print "ok 1\n";

###

print "Creating new Cz::Cstocs object\n";

my $il2_to_ascii = new Cz::Cstocs 'il2', 'ascii';
print "not " unless defined $il2_to_ascii;
print "ok 2\n";

###

print "Converting a string 'je¾eèek nelétá' to plain ascii\n";

my $result1 = &$il2_to_ascii('je¾eèek nelétá');
print "Got '$result1'\n";

print "not " if $result1 ne "jezecek neleta";
print "ok 3\n";

###

print "Now using a method call\n";

my $result2 = $il2_to_ascii->conv('je¾eèek nelétá');
print "Got '$result2'\n";

print "not " if $result2 ne "jezecek neleta";
print "ok 4\n";

###

print "Calling the external cstocs program\n";

use ExtUtils::testlib;
my @libs = map "-I$_", @INC;
my $TSTFILE = 'out.tst';
$TSTFILE = 't/' . $TSTFILE if -d 't';

open PROCESS, "| $^X @libs blib/script/cstocs il2 ascii > $TSTFILE";
print PROCESS "je¾eèek\n";
close PROCESS;

open READ, $TSTFILE;
my $result3 = <READ>;
close READ;
print "Got '$result3'\n";

print "not " if $result3 ne "jezecek\n";
print "ok 5\n";

###

print "And once more, for the bug that was fixed in 3.07\n";

open PROCESS, "| $^X @libs blib/script/cstocs pc2 il2 > $TSTFILE";
print PROCESS "\375\n";
close PROCESS;

open READ, $TSTFILE;
my $result4 = <READ>;
close READ;
print "Got '$result4'\n";

print "not " if $result4 ne "ø\n";
print "ok 6\n";

unlink $TSTFILE;

###

print "Converting a list 'je¾eèek', 'nelétá' to plain ascii\n";

my $result5 = join ';', &$il2_to_ascii('je¾eèek', 'nelétá');
print "Got '$result5'\n";

print "not " if $result5 ne "jezecek;neleta";
print "ok 7\n";

###

print "Converting ascii to ascii\n";

my $ascii_to_ascii = new Cz::Cstocs 'ascii', 'ascii';
print "not " if not defined $ascii_to_ascii;
print "ok 8\n";

my $result6 = $ascii_to_ascii->conv("jezecek neleta");
print "Got '$result6'\n";

print "not " if $result6 ne "jezecek neleta";
print "ok 9\n";

###

print "Converting tex to il2\n";

my $tex_to_il2 = new Cz::Cstocs 'tex', 'il2';
print "not " if not defined $tex_to_il2;
print "ok 10\n";

print "Expecting èástka; je¾eèek; píseò; ae\n";
my $result7 = $tex_to_il2->conv("\\v c\\'astka; je\\v{z}e\\v cek; p\\'{\\i}se\\v n; \\ae");
print "Got '$result7'\n";

print "not " if $result7 ne "èástka; je¾eèek; píseò; ae";
print "ok 11\n";

###

print "Converting tex to il2 (use_accent = 0; nochange)\n";

$tex_to_il2 = new Cz::Cstocs 'tex', 'il2', 'use_accent' => 0;
print "not " if not defined $tex_to_il2;
print "ok 12\n";

print "Expecting \\ae -> \\ae\n";
my $result8 = $tex_to_il2->conv("\\ae");
print "Got '$result8'\n";

print "not " if $result8 ne "\\ae";
print "ok 13\n";

###

print "Converting il2 to tex\n";


$il2_to_tex = new Cz::Cstocs 'il2', 'tex';
print "not " if not defined $il2_to_tex;
print "ok 14\n";

print "Expecting \\v z\\'\\i{}\\v zala\n";
my $result9 = $il2_to_tex->conv("¾í¾ala");
print "Got '$result9'\n";

print "not " if $result9 ne "\\v z\\'\\i{}\\v zala";
print "ok 15\n";

###

print "Testing correct behaviour of one_by_one\nFirst without it\n";

my $_1250_to_il2 = new Cz::Cstocs '1250', 'il2' or print 'not ';
print "ok 16\n";

print "Expecting -- --- (TM)\n";
my $result17 = $_1250_to_il2->conv("\226 \227 \231");
print "Got '$result17'\n";

print 'not ' if $result17 ne '-- --- (TM)';
print "ok 17\n";

###

print "And now one_by_one and also fillstring set\n";

$_1250_to_il2 = new Cz::Cstocs '1250', 'il2', 'one_by_one' => 1,
		'fillstring' => '?' or print 'not ';
print "ok 18\n";

print "Expecting '   '\n";
my $result19 = $_1250_to_il2->conv("\226\227\231");
print "Got '$result19'\n";

print 'not ' if $result19 ne '???';
print "ok 19\n";

###

print "Test use Cz::Cstocs _1250_il2; _1250_il2(\212)\n";

use Cz::Cstocs '_1250_il2';

my $result20 = _1250_il2("\212");
printf "Got %o\nnot ", ord($result20) if $result20 ne "©";
print "ok 20\n";

###

print "Test the aliases\n";

my $conv = new Cz::Cstocs 'iso-8859-2', 'US-ASCII';
if (not defined $conv) {
	print "$Cz::Cstocs::errstr\nnot ";
}
print "ok 21\n";

my $result22 = $conv->conv('malièký je¾eèek');
printf "Got $result22\n";

print 'not ' if $result22 ne 'malicky jezecek';
print "ok 22\n";

###

print "Test il2 to UTF-8 and back\n";

my $il2_to_utf8 = new Cz::Cstocs 'il2', 'utf8';
if (not defined $il2_to_utf8) {
	print "$Cz::Cstocs::errstr\nnot ";
}
print "ok 23\n";

my $result24 = $il2_to_utf8->conv('malièký je¾eèek');
printf "Got $result24\n";
print 'not ' if $result24 ne "maliÄ\x8dkÃ½ jeÅ¾eÄ\x8dek";
print "ok 24\n";

my $utf8_to_il2 = new Cz::Cstocs 'utf8', 'il2';
if (not defined $utf8_to_il2) {
	print "$Cz::Cstocs::errstr\nnot ";
}
print "ok 25\n";

my $result26 = $utf8_to_il2->conv($result24);
printf "Got $result26\n";
print 'not ' if $result26 ne 'malièký je¾eèek';
print "ok 26\n";

###

print "And now test the inplace conversion\n";

open OUT, "> $TSTFILE";
print OUT $il2_to_utf8->conv('malièký je¾eèek'), "\n";
close OUT;

print "Running: $^X @libs blib/script/cstocs -i.bak utf8 ascii $TSTFILE\n";
system "$^X @libs blib/script/cstocs -i.bak utf8 ascii $TSTFILE";

open IN, $TSTFILE;
my $result27 = <IN>;
close IN;

print 'not ' if $result27 ne "malicky jezecek\n";
print "ok 27\n";

unlink $TSTFILE;
unlink "$TSTFILE.bak";

###

eval 'use MIME::Words';
if ($@) {
	print "ok 28 #skip\n";
	print "ok 29 #skip\n";
	print "ok 30 #skip\n";
	print "ok 31 #skip\n";
} else {
	print "Will test conversion from MIME to il2:\n";

	my $mimedata = <<'EOF';
X-Hlavicka: UTF-8 =?utf-8?Q?=C4=8Desk=C3=BD?= text =?iso-8859-2?Q?+=EC=B9=E8=F8=BE=FD=E1=ED=E9?= =?iso-8859-2?Q?+=EC=B9=E8=F8=BE=FD=E1=ED=E9?= =?utf-8?Q?_=C4=8Desk=C3=BD?= =?iso-8859-2?Q?+=EC=B9=E8=F8=BE=FD=E1=ED=E9?=
EOF

	my $mime_il2 = new Cz::Cstocs 'mime', 'il2';
	if (not defined $mime_il2) {
		print "$Cz::Cstocs::errstr\nnot ";
	}
	print "ok 28\n";
	my $out = $mime_il2->conv($mimedata);
	if ($out ne "X-Hlavicka: UTF-8 èeský text +ì¹èø¾ýáíé+ì¹èø¾ýáíé èeský+ì¹èø¾ýáíé\n") {
		print "not ";
	}
	print "ok 29\n";

	my $il2_mime = new Cz::Cstocs 'il2', 'MIME';
	if (not defined $il2_mime) {
		print "$Cz::Cstocs::errstr\nnot ";
	}
	print "ok 30\n";
	my $outmime = &$il2_mime($out);
	if ($outmime ne "X-Hlavicka: UTF-8 =?ISO-8859-2?Q?=E8esk=FD?= text +=?ISO-8859-2?Q?=EC=B9=E8=F8=BE=FD=E1=ED=E9?=+=?ISO-8859-2?Q?=EC=B9=E8=F8=BE=FD=E1=ED=E9_=E8esk=FD?=+=?ISO-8859-2?Q?=EC=B9=E8=F8=BE=FD=E1=ED=E9?=\n") {
		print "not ";
	}
	print "ok 31\n";
}
