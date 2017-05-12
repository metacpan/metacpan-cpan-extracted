BEGIN { $| = 1; print "1..5\n" }
END { print "not ok 1\n" unless $loaded }
use Fcntl;
use DWH_File;

$loaded = 1;

########################################################################
# High level test 01
#######################################################################
# First tests: We try to tie a hash and check that
# basic updates and fetches seem to work alright
# with the hash tied.
#
# 1: Tie and assign some entries. OK if fetches match assignments
# 2: Add an extra reference to the scalar from 1 and check deref
# 3: Change the original scalar and check that the references follow
# 4: delete an entry and test the value returned
# 5: test that the entry does not exist any more
#######################################################################

if ( opendir TD, '.' ) {
    for ( grep { /^_test_\d\d/ } readdir TD ) {
	unlink $_ or warn "Unable to delete stale testfile";
    }
    closedir TD;
}
else { warn "Unable to check test directory for stale testdata" }

tie my %dwh, 'DWH_File', '_test_01', O_RDWR | O_CREAT, 0644;

$dwh{ metafyt } = "dumagraf falanks";
$dwh{ aref } = [ qw( stativ stakit kasket ) ];
$dwh{ href } = { sild => "karrysalat",
		 ost => "peberfrugt",
		 roastbeef => "peberrod",
		 };
$dwh{ del_href1 } = { der => "sad",
                      en  => "fisker",
                    };
$dwh{ del_href2 } = { saa => "tankefuld",
                      og  => "lytted",
                    };
my $scalar = "orqwood";
$dwh{ sref } = \$scalar;

if ( $dwh{ metafyt } eq "dumagraf falanks" and
     $dwh{ aref }->[ 0 ] eq "stativ" and
     $dwh{ aref }->[ 1 ] eq "stakit" and
     $dwh{ aref }->[ 2 ] eq "kasket" and
     $dwh{ href }->{ sild } eq "karrysalat" and
     $dwh{ href }->{ ost } eq "peberfrugt" and
     $dwh{ href }->{ roastbeef } eq "peberrod" and
     $dwh{ del_href1 }->{ der } eq "sad" and
     $dwh{ del_href1 }->{ en } eq "fisker" and
     $dwh{ del_href2 }->{ saa } eq "tankefuld" and
     $dwh{ del_href2 }->{ og } eq "lytted" and
     ${ $dwh{ sref } } eq "orqwood" ) {
    print "ok 1\n";
}
else { print "not ok 1\n" }

########### 2 ###########

$dwh{ href }->{ samescalar } = $dwh{ sref };

if ( ${ $dwh{ href }->{ samescalar } } eq "orqwood" ) {
    print "ok 2\n";
}
else { print "not ok 2\n" }

########### 3 ###########

$scalar = "software";

if ( ${ $dwh{ href }->{ samescalar } } eq "software" ) {
    print "ok 3\n";
}
else { print "not ok 3\n" }

########### 4 ###########

my $del1 = delete $dwh{ del_href1 };

if ( $del1->{ der } eq "sad" and
     $del1->{ en } eq "fisker" ) { print "ok 4\n" }
else { print "not ok 4\n" }

########### 5 ###########

if ( exists $dwh{ del_href1 } ) { print "not ok 5\n" }
else { print "ok 5\n" }

########### . ###########

untie %dwh;
