use 5.10.1;
use strict;
use warnings;

use Test::More tests=>11;

use File::Temp;

my $dbdir;
use Data::Dumper;

BEGIN { 
	# use a temporary directory for our database...
	$dbdir = File::Temp->newdir();

	use_ok( 'Crypt::NSS::X509', (':dbpath', $dbdir) );
}

# first - load and add certificates to db
{
	my $selfsigned = Crypt::NSS::X509::Certificate->new_from_pem(slurp('certs/selfsigned.crt'));
	isa_ok($selfsigned, 'Crypt::NSS::X509::Certificate');
	Crypt::NSS::X509::add_cert_to_db($selfsigned, "cert1");
	
	my $rapidssl = Crypt::NSS::X509::Certificate->new_from_pem(slurp('certs/rapidssl.crt'));
	isa_ok($rapidssl, 'Crypt::NSS::X509::Certificate');
	Crypt::NSS::X509::add_cert_to_db($rapidssl, "cert2");
	
	my $google = Crypt::NSS::X509::Certificate->new_from_pem(slurp('certs/google.crt'));
	isa_ok($google, 'Crypt::NSS::X509::Certificate');
	Crypt::NSS::X509::add_cert_to_db($google, "cert3");
}


# Dirty fix: reinit Crypt::NSS::X509
Crypt::NSS::X509::_reinit();

{
	my $selfsigned = Crypt::NSS::X509::Certificate->new_from_nick("cert1");
	isa_ok($selfsigned, 'Crypt::NSS::X509::Certificate');
	
	my $rapidssl = Crypt::NSS::X509::Certificate->new_from_nick("cert2");
	isa_ok($rapidssl, 'Crypt::NSS::X509::Certificate');
	
	my $google = Crypt::NSS::X509::Certificate->new_from_nick("cert3");
	isa_ok($google, 'Crypt::NSS::X509::Certificate');

	is($selfsigned->fingerprint_sha256, 'c9f7b2becca219fb8a170e507d7722064e454a3b569e3677694f64cdf01ca602', 'sha256');
	is($rapidssl->fingerprint_sha256, '033b31b83fcec0a51090751852a1aadb0f4d34928c3aefd9e537d312c1c1107b', 'sha256');	
	is($google->fingerprint_sha256, 'ec6a6b156b3062fa99499d1e1515cf6c5048af17945748396bd2ecf12b8de22c', 'sha256');	

	
	my $unknown = Crypt::NSS::X509::Certificate->new_from_nick("cert4");
	ok(!defined($unknown), 'undef');

}

sub slurp {
  local $/=undef;
  open (my $file, shift) or die "Couldn't open file: $!";
  my $string = <$file>;
  close $file;
  return $string;
}
