# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test;
BEGIN { plan tests => 5 };

use Algorithm::Hamming::Perl  qw(hamming unhamming unhamming_err);

# 1. Test encoding
print "1. Hamming encoding test... ";
$data = "Hi";
$hamcode = hamming("$data");
$binary = unpack("B*",$hamcode);
ok($binary,"010011001000011001001101");

# 2. Test decoding
print "2. Hamming decoding test... ";
$unham = unhamming($hamcode);
ok($unham,"Hi");

# 3. Zero error value
print "3. Zero error value... ";
($unham,$err) = unhamming_err($hamcode);
ok($err,0);

# 4. Test error repair
print "4. Test error repair... ";
$errors = "011011001000011001001100";
$hamerr = pack("B*",$errors);
($unham,$err) = unhamming_err($hamerr);
ok($unham,"Hi");

# 5. Test non-zero error value
print "5. Test non-zero error value... ";
ok($err,2);

