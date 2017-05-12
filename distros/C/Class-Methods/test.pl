# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Class::Methods;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

print "ok 2\n";
my $var = bless [ 1, 2, 3 ], Class::Methods->new( count => sub { scalar @{+shift} } );
print "ok 3\n";
my $count = $var->count;
print $count ? "ok 4\n" : "not ok 4\n";
$var->extend( sum => sub { my $sum; $sum += $_ for @{+shift}; return $sum } );
print "ok 5\n";
print $var->sum ? "ok 6\n" : "not ok 6\n";
$var->remove('sum');
eval { $var->sum }; print $@ ? "ok 7\n" : "not ok 7\n";

eval {
    my $boo = bless {}, Class::Methods->new( far => sub { print "ok 8\n" } );
    $var->base($boo);
    $var->far;
}; $@ && print "not ok 8\n";
