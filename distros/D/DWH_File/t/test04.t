BEGIN { $| = 1; print "1..2\n" }
END { print "not ok 1\n" unless $loaded }
use Fcntl;
use DWH_File;

use lib "t";
use DTC_A;

$loaded = 1;

########################################################################
# High level test 04
########################################################################
# Check that the objects stored in test03.t are revived OK
#
# 1: See that first object is restored correctly
# 2: See that other object is restored correctly
########################################################################

if ( opendir TD, '.' ) {
    my $num = grep { /^_test_\d\d/ } readdir TD;
    closedir TD;
    unless( $num ) {
	warn "Can't see dbm files?";
	print "not ok 1\n";
	print "not ok 2\n";
    }
}
else { warn "Unable to check test directory for testdata" }

tie my %dwhc, 'DWH_File', '_test_01', O_RDWR | O_CREAT, 0644;

if ( $dwhc{ aref }->[ 6 ]->arfgab eq "narg go eggyheluJ" and
     $dwhc{ aref }->[ 6 ]->frequency( "g" ) == 4 and
     $dwhc{ aref }->[ 6 ]->frequency( "x" ) == 0 and
     $dwhc{ aref }->[ 6 ]->frequency( "Jlgy" ) == 7 ) {
    print "ok 1\n";
}
else { print "not ok 1\n" }

########## 2 ###########

if ( $dwhc{ object_2 }->arfgab eq "Orqwood" and
     $dwhc{ object_2 }->frequency( "Oo" ) == 3 and
     $dwhc{ object_2 }->frequency( "P34" ) == 0 and
     $dwhc{ object_2 }->frequency( "d" ) == 1 ) {
    print "ok 2\n";
}
else { print "not ok 2\n" }

########### . ###########

untie %dwhc;
