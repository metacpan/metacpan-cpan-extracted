use Convert::ASN1;
use Test::More tests => 2;

my $asn = Convert::ASN1->new;
$asn->prepare(q<
  [APPLICATION 7] SEQUENCE {
    int INTEGER
  }
>);
my $out;
$out = $asn->decode( pack("H*", "dfccd3fde3") );
ok($out == "");
$out = $asn->decode( pack("H*", "b0805f92cb") );
ok($out == "");
