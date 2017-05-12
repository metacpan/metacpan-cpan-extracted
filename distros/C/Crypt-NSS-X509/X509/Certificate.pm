package Crypt::NSS::X509::Certificate;

use strict;
use warnings;

use Crypt::NSS::X509;
use Carp;

use MIME::Base64 ();

our $VERSION = '0.05';

sub new_from_pem {
	my $class = shift;
	my $pem = shift;

	$pem =~ s/-----BEGIN CERTIFICATE-----// or croak("Did not found certificate start");
	$pem =~ s/-----END CERTIFICATE-----// or croak ("Did not found certificate end");

	my $der = MIME::Base64::decode($pem);
	if ( length($der) < 1 ) {
		croak("Could not decode certificate");
	}

	return $class->new($der, @_);
}

1;

