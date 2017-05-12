use 5.10.1;
use strict;
use warnings;

use Test::More tests=>9;

my $vfytime = 1351057173; # time at which certificates were valid
my $invalidtime = 42; # well, certainly not valid here.

BEGIN { use_ok( 'Crypt::NSS::X509' ); }

# load list of root certificates
my $certlist = Crypt::NSS::X509::CertList->new_from_rootlist('certs/root.ca');
isa_ok($certlist, 'Crypt::NSS::X509::CertList');

{
	my $selfsigned = Crypt::NSS::X509::Certificate->new_from_pem(slurp('certs/selfsigned.crt'));
	isa_ok($selfsigned, 'Crypt::NSS::X509::Certificate');
	is($selfsigned->verify_pkix($vfytime), -8179, 'no verify');
	is($selfsigned->verify_pkix($vfytime, Crypt::NSS::X509::certUsageSSLServer, $certlist), -8179, 'no verify');
}

# these tests need fixed timestamps added...
# otherwise they will fail in a year or so.

{
	my $rapidssl = Crypt::NSS::X509::Certificate->new_from_pem(slurp('certs/rapidssl.crt'));
	isa_ok($rapidssl, 'Crypt::NSS::X509::Certificate');
	is($rapidssl->verify_pkix($vfytime), -8172, 'no verify');
	is($rapidssl->verify_pkix($vfytime, Crypt::NSS::X509::certUsageSSLServer, $certlist), 1,'verify');
	is($rapidssl->verify_pkix($invalidtime, Crypt::NSS::X509::certUsageSSLServer, $certlist), -8181, 'no verify');
}

# chain verification sadly does not work correctly with certlists.
#
#{
#	my $google = Crypt::NSS::X509::Certificate->new_from_pem(slurp('certs/google.crt'));
#	isa_ok($google, 'Crypt::NSS::X509::Certificate');
#	ok(!$google->verify, 'no verify');
#	ok(!$google->verify($certlist), 'no verify');
#
#	# but when we load the thawte intermediate cert too it verifes...
#	
#	{
#		my $thawte = Crypt::NSS::X509::Certificate->new_from_pem(slurp('certs/thawte.crt'));
#		isa_ok($thawte, 'Crypt::NSS::X509::Certificate');
#		ok(!$google->verify, 'no verify');
#		ok($google->verify($certlist), 'verify with added thawte');
#	}
#
#	# and out of scope again - no verify anymore
#	ok(!$google->verify, 'no verify');
#	ok(!$google->verify($certlist), 'no verify');
#}

sub slurp {
  local $/=undef;
  open (my $file, shift) or die "Couldn't open file: $!";
  my $string = <$file>;
  close $file;
  return $string;
}
