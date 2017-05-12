use warnings;
use strict;

use Test::More tests => 8;

BEGIN { use_ok "Crypt::Eksblowfish"; }

my $tstr = "abcdefgh\xaa1234567";
my $ustr;
eval {
	require Encode;
	$ustr = Encode::encode_utf8($tstr);
	Encode::_utf8_on($ustr);
};
$ustr = undef unless $@ eq "";
my $bstr = "abcdefgh\x{100}1234567";

eval { Crypt::Eksblowfish->new(1, $bstr, $tstr); };
like $@, qr/\Ainput must contain only octets\b/;
eval { Crypt::Eksblowfish->new(1, $tstr, $bstr); };
like $@, qr/\Ainput must contain only octets\b/;
SKIP: {
	skip "Encode not available", 1 unless defined $ustr;
	my $ca = Crypt::Eksblowfish->new(1, $tstr, $tstr);
	my $cb = Crypt::Eksblowfish->new(1, $ustr, $ustr);
	is $ca->encrypt("ABCDEFGH"), $cb->encrypt("ABCDEFGH");
}

my $tblk = "foo\xaabar!";
my $ublk;
eval {
	require Encode;
	$ublk = Encode::encode_utf8($tblk);
	Encode::_utf8_on($ublk);
};
$ublk = undef unless $@ eq "";
my $bblk = "foo\x{100}bar!";

my $cipher = Crypt::Eksblowfish->new(1, $tstr, $tstr);
eval { $cipher->encrypt($bblk); };
like $@, qr/\Ainput must contain only octets\b/;
eval { $cipher->decrypt($bblk); };
like $@, qr/\Ainput must contain only octets\b/;
SKIP: {
	skip "Encode not available", 2 unless defined $ustr;
	is $cipher->encrypt($tblk), $cipher->encrypt($ublk);
	is $cipher->decrypt($tblk), $cipher->decrypt($ublk);
}

1;
