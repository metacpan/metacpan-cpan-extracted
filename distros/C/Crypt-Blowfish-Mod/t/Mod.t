use strict;
use warnings;
use Test::More tests => 61;

use_ok 'Crypt::Blowfish::Mod';

my $str = "You're the man now, dog";

{
	my $long_key = 'a' x 256;
	ok( my $cipher = new Crypt::Blowfish::Mod( key_raw=>$long_key ), 'long key instance' );
	my $out = $cipher->encrypt($str);
}
{
	ok( my $cipher = new Crypt::Blowfish::Mod( key_raw=>'sdoifuowerjle8784371oiojlkfjsldkfj./565719.")o832948' ), 'created' );
	my $out = $cipher->encrypt($str);
	#warn ">>>>>>>>>>$out<<<<<<<<<<<<<";
	ok( $out eq 'dE4MRDH/6/gCPGaqWCMRIeOAeLMuqB+nyI8C', 'encrypt' );
}
{
	ok( my $cipher = new Crypt::Blowfish::Mod( key=>'MTIzNDU2' ), 'created' );
	my $out = $cipher->encrypt($str);
	#warn ">>>>>>>>>>$out<<<<<<<<<<<<<";
	ok( $out eq 'qpKjrAawOJeCw2GtABI7HJYBcxobKAbv60wA', 'encrypt base64' );

	my $data = $cipher->decrypt($out);
	#warn ">>>>>>>>>>$data<<<<<<<<<<<<<";
	ok( $data eq $str, 'decrypt base64' );
}
{
	ok( my $cipher = new Crypt::Blowfish::Mod( 'MTIzNDU2' ), 'created' );
	my $out = $cipher->encrypt($str);
	my $data = $cipher->decrypt($out);
	#warn ">>>>>>>>>>$data<<<<<<<<<<<<<";
	ok( $data eq $str, 'decrypt' );
}

# Size stress tests
{
	my $cipher = new Crypt::Blowfish::Mod( 'MTIzNDU2' );

	my $str;
	for( 1..50 ) {
		$str .= ( 'x' x 1000 ) x $_;
		my $out = $cipher->encrypt($str);
		my $data = $cipher->decrypt($out);
		ok( $data eq $str, 'decrypt large str ' . $_ );
	}
}

# Raw tests
{
	ok( my $cipher = new Crypt::Blowfish::Mod( key_raw=>'lkdjflkajsldkfj03804223$=(/)/(1lkjl' ), 'raw key created' );
	my $out = $cipher->encrypt_raw($str);
	my $data = $cipher->decrypt_raw($out);
	ok( $data eq $str, 'decrypt raw' );
}

