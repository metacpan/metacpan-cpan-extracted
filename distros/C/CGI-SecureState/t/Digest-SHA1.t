# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Digest-SHA1.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "Load failed ... not ok 1\n" unless $loaded;}
use Digest::SHA1 qw (sha1 sha1_hex);
$loaded = 1;
$test=1;
print "ok $test\n";

@ISA=qw (CGI);
######################### End of black magic.

#test Digest::SHA1
$test++;
my $words="Blah blah blah blah blah";
my $binstring=$words;
unless (sha1($binstring) eq pack("H*",sha1_hex($binstring))) { bail() }
else { print "ok $test\n" }

sub bail {
    print "Bail out! Digest::SHA1, a required module for CGI::SecureState, does not work on your system!\n";
}
