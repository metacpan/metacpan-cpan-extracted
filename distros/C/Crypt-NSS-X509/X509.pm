package Crypt::NSS::X509;

use strict;
use warnings;

use 5.10.1;

use vars qw($VERSION @EXPORT_OK);
use Exporter;
use Encode qw/encode/;
use base qw(Exporter);

use autodie qw(open close);
use Carp;

use Alien::NSS;

use Crypt::NSS::X509::Certificate;
use Crypt::NSS::X509::CertList;
use Crypt::NSS::X509::CRL;

our $VERSION = '0.05';

@EXPORT_OK = qw(
);



BOOT_XS: {
  require DynaLoader;

  # DynaLoader calls dl_load_flags as a static method.
  *dl_load_flags = DynaLoader->can('dl_load_flags');

  do {__PACKAGE__->can('bootstrap') || \&DynaLoader::bootstrap}->(__PACKAGE__, $VERSION);
}

sub load_rootlist {
	shift if ( defined $_[0] && $_[0] eq __PACKAGE__ );
	my $filename = shift;

	carp("No rootlist filename provided") unless defined($filename);

	my $pem;

	open (my $fh, "<", $filename);
	while ( my $line = <$fh> ) {
		if ( $line =~ /--BEGIN CERTIFICATE--/ .. $line =~ /--END CERTIFICATE--/ ) {

			$pem .= $line;

			if ( $line =~ /--END CERTIFICATE--/ ) {
				#say "|$pem|";
				my $cert = Crypt::NSS::X509::Certificate->new_from_pem($pem);
				$pem = "";
				add_trusted_cert_to_db($cert, $cert->subject);
			}
		}
	}

	close($fh);
}

sub import {
	my $pkg = shift; # us
        my @syms = (); # symbols to import. really should be empty
        my @dbpath = (); 
	my $noinit = 0;

        my $dest = \@syms;

        for (@_) {
                if ( $_ eq ':dbpath') {
                        # switch to dbpath 
                        $dest = \@dbpath;
                        next;           
                } elsif ( $_ eq ':noinit' ) {
			$noinit = 1;
			next;
		}

                push (@$dest, $_);
        }
        
        croak ("We do not export symbols") unless (scalar @syms == 0);	

	return if ( $noinit );

	if ( scalar @dbpath == 0 ) {
		_init_nodb();
	} elsif (scalar @dbpath == 1) {
		_init_db($dbpath[0]);
	} else {
		croak ("More than one database path specified");
	}
}

END {
  __PACKAGE__->__cleanup;
}

1;
