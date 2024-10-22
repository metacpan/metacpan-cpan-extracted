use strict;
use Test::More;
use Test::Exception;
use Convert::PEM;

require "./t/func.pl";

plan tests => 3;

my $pem = get_rsa();
isa_ok $pem, "Convert::PEM", '$pem';

my $bad = "t/data/rsakey-bad.pem";
my $obj;
lives_ok { $obj = $pem->read( Filename => $bad, Password => "test") } "read bad file";

ok $pem->errstr() =~ m/Decryption failed:/, "Decryption failed for bad file";
