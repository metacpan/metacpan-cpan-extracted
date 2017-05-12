BEGIN { $| = 1; print "1..2\n" }
END { print "not ok 1\n" unless $loaded }
use Fcntl;
use DWH_File;

use lib "t";
use DTC_A;

$loaded = 1;

########################################################################
# High level test 05
########################################################################
# Establish connections to data in a couple of different files
#
# 1-2: See that things work during assignment session
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

tie my %dwh01, 'DWH_File', '_test_01', O_RDWR | O_CREAT, 0644;
tie my %dwh02, 'DWH_File', '_test_02', O_RDWR | O_CREAT, 0644;
tie my %dwh03, 'DWH_File', '_test_03', O_RDWR | O_CREAT, 0644;

$dwh02{ inner } = {};
$dwh02{ inner }->{ foreign1 } = $dwh01{ aref };
$dwh03{ mine } = [ qw( nul et to tre ) ];
$dwh01{ aref }->[ 5 ] = $dwh03{ mine };

####### 1 ######

if ( $dwh02{ inner }->{ foreign1 }[ 5 ][ 0 ] eq "nul" and
     $dwh02{ inner }->{ foreign1 }[ 5 ][ 3 ] eq "tre" and
     $dwh02{ inner }->{ foreign1 }[ 5 ][ 1 ] eq "et" ) {
    print "ok 1\n";
}
else { print "not ok 1\n" }

######## 2 #######

$dwh02{ inner }->{ foreign1 }[ 5 ][ 3 ] = "i stedet for tre";
if ( $dwh03{ mine }->[ 3 ] eq "i stedet for tre" ) { print "ok 2\n" }
else { print "not ok 2\n" }

untie %dwh01;
untie %dwh02;
untie %dwh03;
