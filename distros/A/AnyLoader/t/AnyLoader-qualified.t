# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)
use strict;

use vars qw($Total_tests);

my $test_num = 1;
BEGIN { $| = 1; $^W = 1; }
print "1..$Total_tests\n";
######################### End of black magic.

# Utility testing functions.
sub ok {
    my($test, $name) = @_;
    print "not " unless $test;
    print "ok $test_num";
    print " - $name" if defined $name;
    print "\n";
    $test_num++;
}

sub eqarray  {
    my($a1, $a2) = @_;
    return 0 unless @$a1 == @$a2;
    my $ok = 1;
    for (0..$#{$a1}) { 
        unless($a1->[$_] eq $a2->[$_]) {
        $ok = 0;
        last;
        }
    }
    return $ok;
}

# Change this to your # of ok() calls + 1
BEGIN { $Total_tests = 1 }

use AnyLoader qw(Data::Dumper);

eval { Text::Soundex::soundex('schwern') };
ok( $@ =~ /^Undefined subroutine &Text::Soundex::soundex called/ );
