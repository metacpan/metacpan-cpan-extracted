package Crypt::NSS::X509::CertList;

use strict;
use warnings;
use autodie;

use Crypt::NSS::X509;

our $VERSION = '0.05';

sub new_from_rootlist {
	my ($class, $filename) = @_;

	my $certlist = Crypt::NSS::X509::CertList->new();

	my $pem;

	open (my $fh, "<", $filename);
	while ( my $line = <$fh> ) {
		if ( $line =~ /--BEGIN CERTIFICATE--/ .. $line =~ /--END CERTIFICATE--/ ) {

			$pem .= $line;

			if ( $line =~ /--END CERTIFICATE--/ ) {
				#say "|$pem|";
				my $cert = Crypt::NSS::X509::Certificate->new_from_pem($pem);
				$pem = "";
				$certlist->add($cert);
			}
		}
	}
	close($fh);

	return $certlist;
}

1;
