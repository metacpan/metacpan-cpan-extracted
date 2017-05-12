my $ssh_key =<<_EOT;
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD7EZn/BzP26AWk/Ts2ymjpTXuXRiEWIWnHFTilOTcuJ/P1HfOwiy4RHC1rv59Yh/E6jbTx623+OGySJWh1IS3dAEaHhcGKnJaikrBn3ccdoNVkAAuL/YD7FMG1Z0SjtcZS6MoO8Lb9pkq6R+Ok6JQjwCEsB+OaVwP9RnVA+HSYeyCVE0KakLCbBJcD1U2aHP4+IH4OaXhZacpb9Ueja6NNfGrv558xTgfZ+fLdJ7cpg6wU8UZnVM1BJiUW5KFasc+2IuZR0+g/oJXaYwvW2T6XsMgipetCEtQoMAJ4zmugzHSQuFRYHw/7S6PUI2U03glFmULvEV+qIxsVFT1ng3pj lars@tiamat.house
_EOT

use 5.010;

use MIME::Base64 qw(encode_base64 decode_base64);
use Convert::ASN1;
use Math::BigInt;

my ($type, $b64_blob, $id) = split / /, $ssh_key;
my $blob = decode_base64($b64_blob);

my @parts;
my $len = length($blob);
my $pos = 0;
while ( $pos < $len ) {
    my ($dlen) = hex(unpack "H*", substr($blob, $pos, 4));
    $pos += 4;
    warn "len: $len\tpos: $pos\tdlen: $dlen";
    push @parts, substr($blob, $pos, $dlen);
    $pos += $dlen;
}



my $t = unpack 'A*', $parts[0];
my $e = hex(unpack 'H*', $parts[1]);
my $n = Math::BigInt->new("0x" . unpack 'H*', $parts[2]);

die unless $t eq "ssh-rsa";

warn $e;

my $asn = Convert::ASN1->new(
    encoding => 'DER' 
);

$asn->prepare(q|
RSAPublicKey ::= SEQUENCE {
    modulus           INTEGER,  -- n
    publicExponent    INTEGER   -- e
}
|) or die;

$pdu = $asn->encode( 
    modulus        => $n,
    publicExponent => $e
) or die; 

say '-----BEGIN RSA PUBLIC KEY-----';
print encode_base64($pdu);
say '-----END RSA PUBLIC KEY-----';



