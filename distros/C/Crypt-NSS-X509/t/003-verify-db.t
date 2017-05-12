use 5.10.1;
use strict;
use warnings;

use Test::More tests=>45;

use File::Temp;

my $dbdir;
use Data::Dumper;

my $vfytime = 1351057173; # time at which certificates were valid
my $invalidtime = 42; # well, certainly not valid here.

BEGIN {
	# use a temporary directory for our database...
	$dbdir = File::Temp->newdir();

	use_ok( 'Crypt::NSS::X509', (':dbpath', $dbdir) );
}

# load root certificates to db
Crypt::NSS::X509->load_rootlist('certs/root.ca');

{
	my $selfsigned = Crypt::NSS::X509::Certificate->new_from_pem(slurp('certs/selfsigned.crt'));
	isa_ok($selfsigned, 'Crypt::NSS::X509::Certificate');
	# lol. The different verify operatins give different
	is($selfsigned->verify_pkix($vfytime), -8179, 'no verify');
	is($selfsigned->verify_cert($vfytime), -8172, 'no verify');
	is($selfsigned->verify_certificate($vfytime), -8172, 'no verify');
	is($selfsigned->verify_certificate_pkix($vfytime), -8179, 'no verify');
}

{
	my $rapidssl = Crypt::NSS::X509::Certificate->new_from_pem(slurp('certs/rapidssl.crt'));
	isa_ok($rapidssl, 'Crypt::NSS::X509::Certificate');
	is($rapidssl->verify_pkix($vfytime), 1, 'verify');
	is($rapidssl->verify_cert($vfytime), 1, 'verify');
	is($rapidssl->verify_certificate($vfytime), 1, 'verify');
	is($rapidssl->verify_certificate_pkix($vfytime), 1, 'verify');

	# but not with invalid time

	is($rapidssl->verify_pkix($invalidtime), -8181, 'no verify');
	is($rapidssl->verify_cert($invalidtime), -8181, 'no verify');
	# Fun. Those apparently try chain resolution before date checking
	my $res = $rapidssl->verify_certificate($invalidtime);
	ok($res == -8162 || $res == -8157, 'no verify'); # return code changed in later versions
	is($rapidssl->verify_certificate_pkix($invalidtime), -8179, 'no verify');
}

# chain verification

{
	my $google = Crypt::NSS::X509::Certificate->new_from_pem(slurp('certs/google.crt'));
	isa_ok($google, 'Crypt::NSS::X509::Certificate');
	# something they agree on. At last.
	is($google->verify_pkix($vfytime), -8179, 'no verify');
	is($google->verify_cert($vfytime), -8179, 'no verify');
	is($google->verify_certificate($vfytime), -8179, 'no verify');
	is($google->verify_certificate_pkix($vfytime), -8179, 'no verify');

	# but when we load the thawte intermediate cert too it verifes...

	{
		my $thawte = Crypt::NSS::X509::Certificate->new_from_pem(slurp('certs/thawte.crt'));
		isa_ok($thawte, 'Crypt::NSS::X509::Certificate');
		is($google->verify_pkix($vfytime), 1, 'verify with added thawte');
		is($google->verify_cert($vfytime), 1, 'verify with added thawte');
		is($google->verify_certificate($vfytime), 1, 'verify with added thawte');
		is($google->verify_certificate_pkix($vfytime), 1, 'verify with added thawte');

		my @want = (
			'CN=www.google.com,O=Google Inc,L=Mountain View,ST=California,C=US',
			'CN=Thawte SGC CA,O=Thawte Consulting (Pty) Ltd.,C=ZA',
			'OU=Class 3 Public Primary Certification Authority,O="VeriSign, Inc.",C=US'
	  	);

		# chain resolution test
		my @out = $google->get_cert_chain_from_cert($vfytime)->dump;
		my @subjects = map { $_->subject } @out;
		is_deeply(\@subjects, \@want, 'Chain resolution');
	}
}

# and apparently due to some magic - the intermediate is now cached, even after all certs
# have been destroyed.
# be aware of this trickery...
# I guess this is a memory-leak on my part, but I do absolutely not know where

# Dirty fix: reinit Crypt::NSS::X509
Crypt::NSS::X509::_reinit();

{
	my $google = Crypt::NSS::X509::Certificate->new_from_pem(slurp('certs/google.crt'));
	isa_ok($google, 'Crypt::NSS::X509::Certificate');
	is($google->verify_pkix($vfytime), -8179, 'no verify');
	is($google->verify_cert($vfytime), -8179, 'no verify');
	is($google->verify_certificate($vfytime), -8179, 'no verify');
	is($google->verify_certificate_pkix($vfytime), -8179, 'no verify');
}

{
	# now, let's add the thawte-cert to the db
	my $thawte = Crypt::NSS::X509::Certificate->new_from_pem(slurp('certs/thawte.crt'));
	isa_ok($thawte, 'Crypt::NSS::X509::Certificate');
	Crypt::NSS::X509::add_cert_to_db($thawte, $thawte->subject);
	is($thawte->verify_pkix($vfytime, Crypt::NSS::X509::certUsageAnyCA), 1, 'verify ca');
	is($thawte->verify_cert($vfytime, Crypt::NSS::X509::certUsageAnyCA), 1, 'verify ca');
	is($thawte->verify_certificate($vfytime, Crypt::NSS::X509::certUsageAnyCA), 1, 'verify ca');
	is($thawte->verify_certificate_pkix($vfytime, Crypt::NSS::X509::certUsageAnyCA), 1, 'verify ca');

	is($thawte->verify_pkix($vfytime), -8102, 'verify ca');
	is($thawte->verify_cert($vfytime), -8102, 'verify ca');
	is($thawte->verify_certificate($vfytime), -8102, 'verify ca');
	is($thawte->verify_certificate_pkix($vfytime), -8102, 'verify ca');
}

# kill Crypt::NSS::X509 again
#
Crypt::NSS::X509::_reinit();

# and this time it should validate
{
	my $google = Crypt::NSS::X509::Certificate->new_from_pem(slurp('certs/google.crt'));
	isa_ok($google, 'Crypt::NSS::X509::Certificate');
	is($google->verify_pkix($vfytime), 1, 'verify');
	is($google->verify_cert($vfytime), 1, 'verify');
	is($google->verify_certificate($vfytime), 1, 'verify');
	is($google->verify_certificate_pkix($vfytime), 1, 'verify');
}


sub slurp {
  local $/=undef;
  open (my $file, shift) or die "Couldn't open file: $!";
  my $string = <$file>;
  close $file;
  return $string;
}
