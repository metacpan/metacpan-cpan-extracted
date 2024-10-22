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

#### test optional ASN parameters
#### test with DER In and Out forms

plan tests => 45;

note("Using PEM file '$pem_in'");
note("Using DER file '$der_in'");

my $pem = Convert::PEM->new(
		Name 	=> "RSA PRIVATE KEY",
    );
isa_ok $pem, "Convert::PEM";
ok $pem->inform() eq "PEM", "Verify correct InForm of PEM";
ok $pem->outform() eq "PEM", "Verify correct OutForm of PEM";

my $derout = Convert::PEM->new(
		Name 	=> "RSA PRIVATE KEY",
		OutForm	=>	"DER",
    );
isa_ok $derout, "Convert::PEM";
ok $derout->inform() eq "PEM", "Verify correct InForm of PEM";
ok $derout->outform() eq "DER", "Verify correct OutForm of DER";

my $derin = Convert::PEM->new(
		Name 	=> "RSA PRIVATE KEY",
		InForm	=>	"DER",
    );
isa_ok $derin, "Convert::PEM";
ok $derin->inform() eq "DER", "Verify correct InForm of DER";
ok $derin->outform() eq "PEM", "Verify correct OutForm of PEM";

my $der = Convert::PEM->new(
		Name 	=> "RSA PRIVATE KEY",
		InForm	=>	"DER",
		OutForm	=>	"DER",
    );
isa_ok $der, "Convert::PEM";
ok $der->inform() eq "DER", "Verify correct InForm of DER";
ok $der->outform() eq "DER", "Verify correct OutForm of DER";

my($bin,$bin2,$fh);

lives_ok { $bin = $pem->read( Filename => $pem_in ) } "read PEM file without ASN decoding";
ok md5_hex($bin) eq $md5hash, "verify PEM file hash";

lives_ok { $pem->write( Filename => $pem_out, Content => $bin ) } "write PEM file without ASN encoding";
ok !$pem->error(), "Check for errors after writing PEM file: ".($pem->error() ? ": ".$pem->error() : "");

lives_ok { $bin2 = $pem->read( Filename => $pem_out ) } "re-read written PEM file without ASN decoding";
ok !$pem->error(), "Check for errors after re-reading PEM file".($pem->error() ? ": ".$pem->error() : "");

ok $bin eq $bin2, "Compare original read to what was written";

unlink $pem_out;
undefl $bin, $bin2;

lives_ok { $bin = $derout->read( Filename => $pem_in ) } "read PEM file without ASN decoding and with OutForm set to DER";
ok md5_hex($bin) eq $md5hash, "verify PEM file hash";

lives_ok { $derout->write( Filename => $der_out, Content => $bin ) } "write DER file without ASN encoding";
ok !$derout->error(), "Check for errors after writing PEM file: ".($derout->error() ? ": ".$derout->error() : "");

ok open($fh,'<',$der_out), "Use open to Open file written";
binmode($fh);
ok read($fh,$bin2,-s $der_out), "Read file contents into memory";
close($fh);
is $bin, $bin2, "Compare original contents ot what was written with \$derout and read back into memory";

undef $bin2;

lives_ok { $bin2 = $derin->read( Filename => $der_out ) } "re-read written DER file with \$derin without ASN decoding";
ok !$derin->error(), "Check for errors after re-reading PEM file".($derin->error() ? ": ".$derin->error() : "");

is $bin, $bin2, "Compare original contents to what was written with \$derout and re-read with \$derin";

unlink $der_out;
undefl $bin,$bin2;

lives_ok { $bin = $derin->read( Filename => $der_in ) } "read DER file without ASN decoding";
ok !$derin->error(), "Check for errors after reading in DER file".($derin->error() ? ": ".$derin->error() : "");
is md5_hex($bin), $md5hash, "verify DER file hash is \"$md5hash\": actual - \"".md5_hex($bin)."\"";

lives_ok { $derin->write( Filename => $pem_out, Content => $bin ) } "write PEM file without ASN encoding";
ok !$derin->error(), "Check for errors after writing PEM file: ".($derin->error() ? ": ".$derin->error() : "");

lives_ok { $bin2 = $pem->read( Filename => $pem_out ) } "re-read PEM file written by \$derin with \$pem without ASN decoding";
ok !$derin->error(), "Check for errors after re-reading PEM file".($derin->error() ? ": ".$derin->error() : "");

is $bin, $bin2, "Compare original contents to what was written with \$derout and re-read with \$derin";

unlink $pem_out;
undefl $bin,$bin2;

lives_ok { $bin = $der->read( Filename => $der_in ) } "read DER file without ASN decoding and with OutForm set to DER";
ok !$der->error(), "Check for errors after reading in DER file: ".$der->error();
is md5_hex($bin), $md5hash, "verify DER file hash is \"$md5hash\": actual - \"".md5_hex($bin)."\"";

lives_ok { $der->write( Filename => $der_out, Content => $bin ) } "write DER file without ASN encoding";
ok !$der->error(), "Check for errors after writing DER file: ".($der->error() ? ": ".$der->error() : "");

lives_ok { $bin2 = $der->read( Filename => $der_out ) } "re-read DER file written without ASN decoding";
ok !$der->error(), "Check for errors after re-reading DER file".($der->error() ? ": ".$der->error() : "");

is $bin, $bin2, "Compare original contents to what was written with \$der and re-read with \$der";

unlink $der_out;
undefl $bin,$bin2;

