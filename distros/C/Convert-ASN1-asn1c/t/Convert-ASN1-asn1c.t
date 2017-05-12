# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Convert-ASN1-asn1c.t'

#########################

use Test::More tests => 9;
BEGIN { use_ok('Convert::ASN1::asn1c') };

#########################

use FindBin;
use File::Which;
use Convert::ASN1::asn1c;

my $pdu = "A1 0C 02 01 01 02 02 00 D3 30 03 0A 01 02";
$pdu =~ s/ //g;
$pdu = pack('H*', $pdu);

my $conv = Convert::ASN1::asn1c->new();

ok(defined($conv), "creating a new converter");
$conv->set_templatedir($FindBin::Bin);

SKIP: {
skip "unber not found in path", 4 if (!defined which('unber'));
my $values = $conv->decode("test-pdu.xml", $pdu);
ok($values->{'integer1'} == 1, "decoding 1 byte integers");
ok($values->{'integer2'} == 211, "decoding 2 byte integers");
ok($values->{'integer2_length'} == 2, "checking if val_length is set correctly");
ok($values->{'integer2_orig'} eq "&#x00;&#xd3;", "checking if val_orig is set correctly");
}
ok($conv->encode_integer(211, 2) eq "&#x00;&#xd3;", "checking if encode_integer works");
ok($conv->decode_integer("&#x00;&#xd3;", 2) eq 211, "checking if decode_integer works");

SKIP: {
skip "enber not found in path", 1 if (!defined which('enber'));
my $newpdu = $conv->encode("test-pdu.xml", {
	integer1=>$conv->encode_integer(1, 1),
	integer2=>$conv->encode_integer(211, 2),
	enumerated1=>$conv->encode_integer(2,1),
});
$orig_pdu_hex = unpack('H*', $pdu);
$my_pdu_hex = unpack('H*', $newpdu);
ok($orig_pdu_hex eq $my_pdu_hex, "checking if encode returns expected result");
}

