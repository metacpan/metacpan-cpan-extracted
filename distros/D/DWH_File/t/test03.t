BEGIN { $| = 1; print "1..1\n" }
END { print "not ok 1\n" unless $loaded }
use Fcntl;
use DWH_File;

use lib "t";
use DTC_A;

$loaded = 1;

########################################################################
# High level test 03
########################################################################
# Tie a hash to the existing file from test01.t and assign a couple
# of objects. Check the values.
#
# 1: See that all values are restored correctly
########################################################################

if ( opendir TD, '.' ) {
    my $num = grep { /^_test_\d\d/ } readdir TD;
    closedir TD;
    unless( $num ) {
	warn "Can't see dbm files?";
	print "not ok 1\n";
    }
}
else { warn "Unable to check test directory for testdata" }

tie my %dwhc, 'DWH_File', '_test_01', O_RDWR | O_CREAT, 0644;

my $obj = DTC_A->new( "Julehygge og gran" );
$dwhc{ object_2 } = DTC_A->new( "doowqrO" );
$dwhc{ aref }->[ 6 ] = $obj;

if ( $dwhc{ aref }->[ 6 ]->arfgab eq "narg go eggyheluJ" and
     $dwhc{ aref }->[ 6 ]->frequency( "g" ) == 4 and
     $dwhc{ aref }->[ 6 ]->frequency( "x" ) == 0 and
     $dwhc{ aref }->[ 6 ]->frequency( "Jlgy" ) == 7 and
     $dwhc{ object_2 }->arfgab eq "Orqwood" and
     $dwhc{ object_2 }->frequency( "Oo" ) == 3 and
     $dwhc{ object_2 }->frequency( "P34" ) == 0 and
     $dwhc{ object_2 }->frequency( "d" ) == 1 ) {
    print "ok 1\n";
}
else { print "not ok 1\n" }

########### . ###########

untie %dwhc;
