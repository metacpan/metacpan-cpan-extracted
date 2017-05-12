# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..14\n"; }
END {print "not ok 1\n" unless $loaded;}
use Data::TemporaryBag;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $t = Data::TemporaryBag->new("ABC");
print "not " if $t->substr(0) ne "ABC";
print "ok 2\n";
$t->add('DEF');
print "not " if $t->substr(1,4) ne "BCDE";
print "ok 3\n";
$t->substr(5,1,'123');
print "not " if $t->value ne "ABCDE123";
print "ok 4\n";
$t->add('4567890');
$t->add('1234567890' x 100) for (1..200);
print "not " unless $t->is_saved;
print "ok 5\n";
$t->substr(5,1,'XYZ');
print "not " if $t->substr(0, 10) ne "ABCDEXYZ23";
print "ok 7\n";
$t->substr(5,4,'abc');
$t->substr(0,4,'');
$t->substr(0,0,'def');
$t->substr(-3,5,'QWERT');
print "not " if $t->substr(0,10) ne "defEabc345" or $t->substr(-10) ne "34567QWERT";
print "ok 8\n";

$Data::TemporaryBag::MaxOpen = 2;  # keep open 2 files.
my %t = map {$_, Data::TemporaryBag->new($_ x 10)} ('A'..'C');
for (1..200) {
    $t{$_}->add(lc($_) x 50) for ('A'..'C');
    $t{$_}->add($_ x 50) for ('A'..'C');
}
print "not " if grep {$t{$_}->substr(500,10) ne $_ x 10} ('A'..'C');
print "ok 9\n";
$t->add('XYZ');
print "not " if $t->substr(-5) ne "RTXYZ" or $t{B}->substr(500,5) ne 'BBBBB';
print "ok 10\n";

my $t0 = Data::TemporaryBag->new("ABC");
my $t1 = $t0;
print "not " if $t1->substr(0) ne "ABC";
print "ok 11\n";
$t0.='DEF';
print "not " if $t0 ne "ABCDEF";
print "ok 12\n";
print "not " if $t1 ne "ABC";
print "ok 13\n";
$t0 .= ('1234567890' x 100) for (1..200);
print "not " unless $t0->is_saved;
print "ok 14\n";

