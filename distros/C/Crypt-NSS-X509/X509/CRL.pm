package Crypt::NSS::X509::CRL;

use strict;
use warnings;

use Crypt::NSS::X509;

our $VERSION = '0.05';

sub new_from_pem {
	my $class = shift;
	my $pem = shift;

	$pem =~ s/-+BEGIN.*CRL-+// or croak("Could not find crl start");
	$pem =~ s/-+END.*CRL-+// or croak("Could not find crl end");

	my $der = MIME::Base64::decode($pem);
	if ( length($der) < 1 ) {
		croak("Could not decode crl");
	}

	return $class->new_from_der($der, @_);
}

1;
