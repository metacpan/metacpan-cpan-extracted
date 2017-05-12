package Authen::SASL::XS;
require DynaLoader;
require Authen::SASL::XS::Security;
require Exporter;

@ISA = qw(DynaLoader);

$VERSION = "1.00";

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
