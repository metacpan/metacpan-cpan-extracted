# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Cisco::Conf;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

my $command = "$^X -T -Iblib/lib -Iblib/arch blib/script/cisconf -v";
my $output = `$command`;
if ($output =~ /Copyright/s) {
    print "ok 2\n";
} else {
    print "not ok 2 ($output)\n";
}

