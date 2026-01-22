use strict;
use warnings;
package Authen::SASL::XS;
require DynaLoader;
require Authen::SASL::XS::Security;
require Exporter;

our @ISA = qw(DynaLoader);

our $VERSION = "1.02";

# ABSTRACT: XS code to glue Perl SASL to Cyrus SASL

bootstrap Authen::SASL::XS $VERSION;

#
# Take a client filehandle and tie it to the Security subclass to
# perform SASL encryption and decryption on the network traffic
#
sub tiesocket {
  my($sasl, $fh) = @_;

  new Authen::SASL::XS::Security($fh, $sasl);
}



# Create a new client filehandle and tie it to the Security subclass to
# perform SASL encryption and decryption on the network traffic
sub securesocket {
  my ($sasl, $fh) = @_;
  my $glob = \do { local *GLOB; };
  tie(*$glob, "Authen::SASL::XS::Security", $fh, $sasl);
  $glob;
}



1;
