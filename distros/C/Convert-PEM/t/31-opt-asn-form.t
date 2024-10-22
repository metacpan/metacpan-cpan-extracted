use strict;
use Test::More;
use Test::Exception;
use Convert::PEM;
use Digest::MD5 qw(md5 md5_hex);

sub undefl { @_[0..$#_]=(); }

my $pem_in = './t/data/rsakey.pem';
my $der_in = './t/data/rsakey.der';

unless (-e $pem_in && -e $der_in) { plan skip_all => "because the necessary test files do not exist"; exit; }

my $pem_out = './t/data/rsakey.t.pem';
my $der_out = './t/data/rsakey.t.der';
my $md5hash = '45f605c6186eaea0730958b0e3da52e4';

require "./t/func.pl";

plan tests => 41;

my $pem = get_rsa();
isa_ok $pem, "Convert::PEM";
ok $pem->inform() eq "PEM", "Verify correct InForm of PEM";
ok $pem->outform() eq "PEM", "Verify correct OutForm of PEM";

my $derout = get_rsa( OutForm => 'DER' );
isa_ok $derout, "Convert::PEM";
ok $derout->inform() eq "PEM", "Verify correct InForm of PEM";
ok $derout->outform() eq "DER", "Verify correct OutForm of DER";

my $derin = get_rsa( InForm => 'DER' );
isa_ok $derin, "Convert::PEM";
ok $derin->inform() eq "DER", "Verify correct InForm of DER";
ok $derin->outform() eq "PEM", "Verify correct OutForm of PEM";

my $der = get_rsa( InForm => 'DER', OutForm => 'DER' );
isa_ok $der, "Convert::PEM";
ok $der->inform() eq "DER", "Verify correct InForm of DER";
ok $der->outform() eq "DER", "Verify correct OutForm of DER";

my($dec,$dec2,$bin,$bin2,$fh,$asn);

$asn=$pem->asn;

#### read/write PEM
lives_ok { $dec = $pem->read( Filename => $pem_in ) } "read PEM file with ASN decoding";
$bin = $asn->encode($dec);
ok md5_hex( $bin ) eq $md5hash, "verify PEM file hash. expecting: \"$md5hash\", actual: \"".md5_hex($bin)."\"";

lives_ok { $pem->write( Filename => $pem_out, Content => $dec ) } "write PEM file with ASN encoding";
ok !$pem->error(), "Check for errors after writing PEM file: ".($pem->error() ? ": ".$pem->error() : "");

lives_ok { $dec2 = $pem->read( Filename => $pem_out ) } "re-read written PEM file with ASN decoding";
ok !$pem->error(), "Check for errors after re-reading PEM file".($pem->error() ? ": ".$pem->error() : "");
$bin2 = $asn->encode($dec2);
ok defined $bin && $bin eq $bin2, "Compare original read to what was written";

unlink $pem_out;
undefl $dec,$dec2,$bin,$bin2;

#### read PEM/write DER
lives_ok { $dec = $derout->read( Filename => $pem_in ) } "read PEM file with ASN decoding and OutForm as DER";
$bin = $asn->encode($dec);
ok md5_hex( $bin ) eq $md5hash, "verify PEM file hash. expecting: \"$md5hash\", actual: \"".md5_hex($bin)."\"";

lives_ok { $derout->write( Filename => $der_out, Content => $dec ) } "write DER file with ASN encoding";
ok !$derout->error(), "Check for errors after writing DER file".($derout->error() ? ": ".$derout->error() : "");

lives_ok { $dec2 = $derin->read( Filename => $der_out ) } "re-read written DER file with ASN decoding";
ok !$derin->error(), "Check for errors in \$derin after re-reading DER file written by \$derout".($derin->error() ? ": ".$derin->error() : "");
$bin2 = $asn->encode($dec2);
is md5_hex( $bin2 ), $md5hash, "verify written DER file hash. expecting: \"$md5hash\", actual: \"".md5_hex($bin2)."\"";

ok defined $bin && $bin eq $bin2, "Compare original read to what was written and re-read";

ok open($fh,'<',$der_out), "Use open to Open the der_out file and compare the hash just to double check";
binmode($fh);
read($fh,$bin2,-s $der_out);
close($fh);
is md5_hex( $bin2 ), $md5hash, "verify written DER file hash from direct open. expecting: \"$md5hash\", actual: \"".md5_hex($bin2)."\"";

#### write with a password even though it should have no effect
lives_ok { $derout->write( Filename => $der_out, Content => $dec, Password => 'test' ) } "write DER file with ASN encoding and provide a password";
ok !$derout->error(), "Check for errors after writing DER file".($derout->error() ? ": ".$derout->error() : "");

lives_ok { $dec2 = $derin->read( Filename => $der_out ) } "re-read written DER file with ASN decoding and password";
ok !$derin->error(), "Check for errors in \$derin after re-reading DER file written by \$derout while providing a password".($derin->error() ? ": ".$derin->error() : "");
$bin2 = $asn->encode($dec2);
is md5_hex( $bin2 ), $md5hash, "verify written DER file hash. expecting: \"$md5hash\", actual: \"".md5_hex($bin2)."\"";


unlink $der_out;
undefl $bin,$bin2,$dec,$dec2;

#### read DER/write PEM
lives_ok { $dec = $derin->read( Filename => $der_in ) } "read DER file with ASN decoding and OutForm as PEM";
$bin = $asn->encode($dec);
ok md5_hex( $bin ) eq $md5hash, "verify DER file hash. expecting: \"$md5hash\", actual: \"".md5_hex($bin)."\"";

lives_ok { $derin->write( Filename => $pem_out, Content => $dec ) } "write PEM file with ASN encoding";
ok !$derin->error(), "Check for errors after writing PEM file".($derin->error() ? ": ".$derin->error() : "");

lives_ok { $dec2 = $pem->read( Filename => $pem_out ) } "re-read written DER file with ASN decoding";
ok !$pem->error(), "Check for errors in \$pem after re-reading DER file written by \$derin".($pem->error() ? ": ".$pem->error() : "");
$bin2 = $asn->encode($dec2);
ok defined $bin && $bin eq $bin2, "Compare original read to what was written and re-read";

unlink $pem_out;
undefl $bin,$bin2,$dec,$dec2;
