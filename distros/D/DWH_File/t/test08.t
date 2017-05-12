BEGIN { $| = 1; print "1..4\n" }
END { print "not ok 1\n" unless $loaded }
use Fcntl;
use DWH_File;

$loaded = 1;

eval { require 5.005 };
if ( $@ ) {
    print "1..0 # Skip This test requires at least perl 5.005\n";
    exit;
}

########################################################################
# Test array operations
#
# Checks for manipulations in former test
########################################################################

tie my %dwh, 'DWH_File', '_test_04', O_RDWR | O_CREAT, 0644;

######### 1 #########

if ( @{ $dwh{ now_later }->{ b1 } } == 10 and
     $dwh{ now_later }->{ b1 }[ 0 ] eq "jeg" and
     $dwh{ now_later }->{ b1 }[ 1 ] eq "har" and
     $dwh{ now_later }->{ b1 }[ 2 ] eq "fanget" and
     $dwh{ now_later }->{ b1 }[ 3 ] eq "mig" and
     $dwh{ now_later }->{ b1 }[ 4 ] eq "en" and
     $dwh{ now_later }->{ b1 }[ 5 ] eq "myg" and
     $dwh{ now_later }->{ b1 }[ 6 ] eq "smeltet" and
     $dwh{ now_later }->{ b1 }[ 7 ] eq "fedtet" and
     $dwh{ now_later }->{ b1 }[ 8 ] eq "af" and
     $dwh{ now_later }->{ b1 }[ 9 ] eq "den" ) {
    print "ok 1\n";
}
else { print "not ok 1\n" }

######### 2 #########

if ( @{ $dwh{ now_later }->{ b2 } } == 3 and
     $dwh{ now_later }->{ b2 }[ 0 ] eq "og" and
     $dwh{ now_later }->{ b2 }[ 1 ] eq "kylling" and
     $dwh{ now_later }->{ b2 }[ 2 ] eq "i" ) {
    print "ok 2\n";
}
else { print "not ok 2\n" }

######### 3 #########

if ( @{ $dwh{ now_later }->{ b3 } } == 6 and
     $dwh{ now_later }->{ b3 }[ 0 ] eq "under" and
     $dwh{ now_later }->{ b3 }[ 1 ] eq "protest" and
     $dwh{ now_later }->{ b3 }[ 2 ] eq "og" and
     $dwh{ now_later }->{ b3 }[ 3 ] eq "den" and
     $dwh{ now_later }->{ b3 }[ 4 ] eq "hvide" and
     $dwh{ now_later }->{ b3 }[ 5 ] eq "bro" ) {
    print "ok 3\n";
}
else { print "not ok 3\n" }

######### 4 #########

if ( @{ $dwh{ now_later }->{ b4 } } == 6 and
     $dwh{ now_later }->{ b4 }[ 0 ] eq "i" and
     $dwh{ now_later }->{ b4 }[ 1 ] eq "sne" and
     $dwh{ now_later }->{ b4 }[ 2 ] eq "staar" and
     $dwh{ now_later }->{ b4 }[ 3 ] eq "urt" and
     $dwh{ now_later }->{ b4 }[ 4 ] eq "i" and
     $dwh{ now_later }->{ b4 }[ 5 ] eq "skjul" ) {
    print "ok 4\n";
}
else { print "not ok 4\n" }

####### . #######

untie %dwh;
