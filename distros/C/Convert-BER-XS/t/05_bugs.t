BEGIN { $| = 1; print "1..4\n"; }

# various bugs fixed after 1.0

use common::sense;
use Convert::BER::XS ':all';

our $test;
sub ok($;$) {
   print $_[0] ? "" : "not ", "ok ", ++$test, " # $_[1]\n";
}

my ($bin, $ber);

# length 127
$bin = ber_encode [0, ASN_OCTET_STRING,  0, "\x01" x 127];
ok ($bin =~ /^\x04\x7f\x01{127}/, unpack "H*", $bin);
$ber = ber_decode $bin;
ok (127 == length $ber->[BER_DATA]);

# internal 0-octet in length
$bin = ber_encode [0, ASN_OCTET_STRING,  0, "\x01" x 0x10013];
ok ($bin =~ /^\x04\x83\x01\x00\x13\x01.*$/s, unpack "H*", substr $bin, 0, 64);
$ber = ber_decode $bin;
ok (0x10013 == length $ber->[BER_DATA]);
