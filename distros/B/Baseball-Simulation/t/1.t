# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Baseball::Simulation;


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


#Test the 2004 Baltimore Orioles
open (OUTFILE, ">tmp_pitch");
print OUTFILE "5683:1579:309:27:198:526:121\n";
close (OUTFILE);

open (OUTFILE, ">tmp_bat");
print OUTFILE "5665:1516:277:24:152:431:89\n";
print OUTFILE "Additions:\n";
print OUTFILE "#Javy Lopez\n";
print OUTFILE "465:150:29:3:43:33:0\n";
print OUTFILE "#Miguel Tejada\n";
print OUTFILE "636:98:42:27:53:10:0\n";
print OUTFILE "Subtractions:\n";
print OUTFILE "#Brook Fordyce\n";
print OUTFILE "348:95:12:2:6:19:2\n";
print OUTFILE "#Devi Cruz\n";
print OUTFILE "548:137:24:3:14:13:1\n";
print OUTFILE "#Jeff Conine\n";
print OUTFILE "493:143:33:3:15:37:0\n";
print OUTFILE "#BJ Surhoff\n";
print OUTFILE "319:94:20:5:29:2:0\n";
close (OUTFILE);

my $obj = new Baseball::Simulation(BattingFile => "tmp_bat",
	PitchingFile => "tmp_pitch",
	Seasons => 20);

my ($Won, $Lost, $Runs, $RunsAgainst) = $obj->Simulate();
print ((($Won > 10) && ($Lost < 150)) ? "ok 1" : "not ok 1\n");
