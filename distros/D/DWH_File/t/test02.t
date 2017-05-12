BEGIN { $| = 1; print "1..4\n" }
END { print "not ok 1\n" unless $loaded }
use Fcntl;
use DWH_File;

$loaded = 1;

########################################################################
# High level test 02
########################################################################
# Tie a hash to the existing file from test01.t and check that
# the data is restored as it was left
#
# 1: See that all values are restored correctly
# 2: See that the value deleted in first session is actually gone
# 3: Try delete another and check the returnde value
# 4: See that it doesn't exist
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

tie my %dwhb, 'DWH_File', '_test_01', O_RDWR | O_CREAT, 0644;

if ( $dwhb{ metafyt } eq "dumagraf falanks" and
     $dwhb{ aref }->[ 0 ] eq "stativ" and
     $dwhb{ aref }->[ 1 ] eq "stakit" and
     $dwhb{ aref }->[ 2 ] eq "kasket" and
     $dwhb{ href }->{ sild } eq "karrysalat" and
     $dwhb{ href }->{ ost } eq "peberfrugt" and
     $dwhb{ href }->{ roastbeef } eq "peberrod" and
     ${ $dwhb{ href }->{ samescalar } } eq "software" and
     ${ $dwhb{ sref } } eq "software" ) {
    print "ok 1\n";
}
else { print "not ok 1\n" }

########### 2 ###########

if ( exists $dwhb{ del_href1 } ) { print "not ok 2\n" }
else { print "ok 2\n" }

########### 3 ###########

my $del2 = delete $dwhb{ del_href2 };

if ( $del2->{ saa } eq "tankefuld" and
     $del2->{ og } eq "lytted" ) { print "ok 3\n" }
else { print "not ok 3\n" }

########### 5 ###########

if ( exists $dwhb{ del_href2 } ) { print "not ok 4\n" }
else { print "ok 4\n" }


########### . ###########

untie %dwhb;
