# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok 1\n" unless $loaded;}
use Acme::Snark;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

my $foo;
tie $foo, 'Acme::Snark';

$foo = 0;$foo = 0;

if ($foo) {
    print "not ok 2\n";
}
else {
    print "ok 2\n";
}

$foo = 0;
if ($foo) {
    print "ok 3\n";
}
else {
    print "not 3\n";
}
my $bar = $foo + 0;
if ($bar) {
    print "not ok 4\n";
}
else {
    print "ok 4\n";
}

my $two;
tie $two, 'Acme::Snark';
$two = undef;
$two = undef;
if ($two) {
    print "not ok 5\n";
}
else {
    print "ok 5\n";
}
$two = undef;
if ($two) {
    print "ok 6\n";
}
else {
    print "not ok 6\n";
}

my $three;
tie $three, 'Acme::Snark';
$three = "";
$three = "";
if ($three) {
    print "not ok 7\n";
}
else {
    print "ok 7\n";
}
$three = "";
if ($three) {
    print "ok 8\n";
}
else {
    print "not ok 8\n";
}

# But now everything is true, even the false things...
