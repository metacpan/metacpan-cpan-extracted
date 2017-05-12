# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use Algorithm::Numerical::Shuffle qw /shuffle/;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $test_num = 2;

eval {
    my @a = shuffle ();
    if (@a) {
        print "not ok ", $test_num ++, "\n";
    }
    else {
        print "ok ", $test_num ++, "\n";
    }
};

if ($@) {print "... error: $@\n";}

eval {
    my $a = [];
    shuffle $a;

    if (@$a) {
        print "not ok ", $test_num ++, "\n";
    }
    else {
        print "ok ", $test_num ++, "\n"; 
    }
};

if ($@) {print "... error: $@\n";}

eval {
    my @a  = (0 .. 9);
    my @b  = shuffle @a;
    my @c  = sort {$a <=> $b} @b;

    if (@a != @c || "@a" ne "@c") {
        print "not ok ", $test_num ++, "\n";
    }
    else {
        print "ok ", $test_num ++, "\n";
    }
};

if ($@) {print "... error: $@\n";}

eval {
    my $A  = [0 .. 9];
    my $B  = [0 .. 9];
    shuffle $B;
    my @C  = sort {$a <=> $b} @$B;

    if (@$A != @C || "@$A" ne "@C") {
        print "not ok ", $test_num ++, "\n";
    }
    else {
        print "ok ", $test_num ++, "\n";
    }
};

if ($@) {print "... error: $@\n";}

