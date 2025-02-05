package Crypt::OpenSSL::PKCS10;

use 5.008000;
use strict;
use warnings;
require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Crypt::OpenSSL::PKCS10 ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our @NIDS = qw(
	NID_key_usage NID_subject_alt_name NID_netscape_cert_type NID_netscape_comment
	NID_ext_key_usage
);

our %EXPORT_TAGS = ( 
  'all'   => [ @NIDS ],
  'const' => [ @NIDS ],
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

#our @EXPORT = qw(
	
#);

our $VERSION = '0.35';

require XSLoader;
XSLoader::load('Crypt::OpenSSL::PKCS10', $VERSION);

# Preloaded methods go here.

sub new_from_rsa {
    my $self = shift;
    my $rsa = shift;
    my ($options)   = shift || ();

    my $priv = $rsa->get_private_key_string();
    $self->_new_from_rsa($rsa, $priv, \%{$options});

}

sub new {
    my $self = shift;

    my $keylen;
    my $options;

    my $args = scalar @_;

    if ($args eq 0) {
        $keylen = 1024;
    } elsif ($args eq 1) {
        if (ref ($_[0]) eq 'HASH') { 
            $keylen = 1024;
            ($options) = $_[0];
        } else {
            $keylen = $_[0];
        }
    } elsif ($args eq 2) {
        if (ref $_[0] eq 'HASH') {
            die('Wrong order for arguements: [$keysize], [%options]');
        }
        $keylen = $_[0];
        ($options) = $_[1];
    } else {
        die ('Maximum 2 optional arguements [$keysize], [%options]');  
    }

    $self->_new($keylen, \%{$options});
}

1;
__END__

# ABSTRACT: Perl extension to OpenSSL's PKCS10 API.

=head1 NAME

Crypt::OpenSSL::PKCS10 - Perl extension to OpenSSL's PKCS10 API.

=head1 SYNOPSIS

  use Crypt::OpenSSL::PKCS10 qw( :const );
  
  my $req = Crypt::OpenSSL::PKCS10->new;
  $req->set_subject("/C=RO/O=UTI/OU=ssi");
  $req->add_ext(Crypt::OpenSSL::PKCS10::NID_key_usage,"critical,digitalSignature,keyEncipherment");
  $req->add_ext(Crypt::OpenSSL::PKCS10::NID_ext_key_usage,"serverAuth, nsSGC, msSGC, 1.3.4");
  $req->add_ext(Crypt::OpenSSL::PKCS10::NID_subject_alt_name,"email:steve@openssl.org");
  $req->add_custom_ext('1.2.3.3',"My new extension");
  $req->add_ext_final();
  $req->sign();
  $req->write_pem_req('request.pem');
  $req->write_pem_pk('pk.pem');
  print $req->get_pem_pubkey();
  print $req->pubkey_type();
  print $req->get_pem_req();

  Crypt::OpenSSL::PKCS10->new()     # Defaults to a 1024-bit RSA private key

  Crypt::OpenSSL::PKCS10->new(2048) # Specify a 2048-bit RSA private key

  # With 2 arguements the keysize must be first
  Crypt::OpenSSL::PKCS10->new(
                                2048,   # 2048-bit RSA keysize 
                                {
                                    type    => 'rsa',      # Private key type ('rsa' or 'ec')
                                    hash    => 'SHA256',   # Hash Algorithm name 
                                });

  Crypt::OpenSSL::PKCS10->new(
                                {
                                    type    => 'ec',        # Private key type ('rsa' or 'ec')
                                    curve   => 'secp384r1', # Eliptic Curve type (secp384r1 default)
                                    hash    => 'SHA256',    # Hash Algorithm name   
                                });

=head1 ABSTRACT

  Crypt::OpenSSL::PKCS10 - Perl extension to OpenSSL's PKCS10 API.

=head1 DESCRIPTION

Crypt::OpenSSL::PKCS10 provides the ability to create PKCS10 certificate requests using RSA key pairs.

=head1 Class Methods

=over

=item new

Create a new Crypt::OpenSSL::PKCS10 object by generating a new key pair. There
are two optional arguments, the key size which defaults to 1024, and a hash of
options which can be used to customize options.

  Crypt::OpenSSL::PKCS10->new()     # Defaults to a 1024-bit RSA private key

  Crypt::OpenSSL::PKCS10->new(2048) # Specify a 2048-bit RSA private key

  # With 2 arguements the keysize must be first
  Crypt::OpenSSL::PKCS10->new(
                                2048,   # 2048-bit RSA keysize 
                                {
                                    type    => 'rsa',      # Private key type ('rsa' or 'ec')
                                    hash    => 'SHA256',   # Hash Algorithm name 
                                });

  Crypt::OpenSSL::PKCS10->new(
                                {
                                    type    => 'ec',        # Private key type ('rsa' or 'ec')
                                    curve   => 'secp384r1', # Eliptic Curve type (secp384r1 default)
                                    hash    => 'SHA256',    # Hash Algorithm name   
                                });

=item new_from_rsa( $rsa_object )

Create a new Crypt::OpenSSL::PKCS10 object by using key information from a Crypt::OpenSSL::RSA object. Here is an example:

  my $rsa = Crypt::OpenSSL::RSA->generate_key(512);
  my $req = Crypt::OpenSSL::PKCS10->new_from_rsa($rsa);

  my $rsa = Crypt::OpenSSL::RSA->generate_key(1024);
  my $req = Crypt::OpenSSL::PKCS10->new_from_rsa($rsa, {type => 'rsa', hash => 'SHA384'});

OpenSSL 3.0 has deprecated the RSA object which Crypt::OpenSSL::RSA creates.  new_from_rsa() is now a perl sub which obtains the private key as a string that is also passed to the _new_from_rsa() XS function.

=item new_from_file( $filename )

Create a new Crypt::OpenSSL::PKCS10 object by reading the request and key information from a PEM formatted file. Here is an example:

  my $req = Crypt::OpenSSL::PKCS10->new_from_file("CSR.csr");

You can also specify the format of the PKCS10 file, either DER or PEM format.  Here are some examples:

  my $req = Crypt::OpenSSL::PKCS10->new_from_file("CSR.csr", Crypt::OpenSSL::PKCS10::FORMAT_PEM());

  my $req = Crypt::OpenSSL::PKCS10->new_from_file("CSR.der", Crypt::OpenSSL::PKCS10::FORMAT_ASN1());

=back

=head1 Instance Methods

=over 2

=item set_subject($subject, [ $utf8 ])

Sets the subject DN of the request.
Note: $subject is expected to be in the format /type0=value0/type1=value1/type2=... where characters may be escaped by \.
If $utf8 is non-zero integer, $subject is interpreted as UTF-8 string.

=item add_ext($nid, $extension)

Adds a new extension to the request. The first argument $nid is one of the exported constants (see below).
The second one $extension is a string (for more info read C<openssl(3)>).

  $req->add_ext(Crypt::OpenSSL::PKCS10::NID_key_usage,"critical,digitalSignature,keyEncipherment");
  $req->add_ext(Crypt::OpenSSL::PKCS10::NID_ext_key_usage,"serverAuth, nsSGC, msSGC, 1.3.4");
  $req->add_ext(Crypt::OpenSSL::PKCS10::NID_subject_alt_name,"email:steve@openssl.org");

=item add_custom_ext($oid, $desc)

Adds a new custom extension to the request. The value is added as a text string, using ASN.1 encoding rules inherited from the Netscape Comment OID. 

  $req->add_custom_ext('1.2.3.3',"My new extension");

=item add_custom_ext_raw($oid, $bytes)

Adds a new custom extension to the request. The value is added as a raw DER octet string. Use this if you are packing your own ASN.1 structures and need to set the extension value directly.

  $req->add_custom_ext_raw($oid, pack('H*','1E06006100620063')) # BMPString 'abc'

=item add_ext_final()

This must be called after all extensions has been added. It actually copies the extension stack to request structure.

  $req->add_ext(Crypt::OpenSSL::PKCS10::NID_subject_alt_name,"email:my@email.org");
  $req->add_ext_final();

=item sign()

This adds the signature to the PKCS10 request.

  $req->sign();

  $req->sign("SHA256");     # Set the hash to use for the signature

=item pubkey_type()

Returns the type of the PKCS10 public key - one of (rsa|dsa|ec).

  $req->pubkey_type();

=item get_pubkey()

Returns the PEM encoding of the PKCS10 public key.

  $req->get_pubkey();

=item get_pem_req()

Returns the PEM encoding of the PKCS10 request.

  $req->get_pem_req();

=item write_pem_req($filename)

Writes the PEM encoding of the PKCS10 request to a given file.

  $req->write_pem_req('request.pem');

=item get_pem_pk()

Returns the PEM encoding of the private key.

  $req->get_pem_pk();

=item write_pem_pk($filename)

Writes the PEM encoding of the private key to a given file.

  $req->write_pem_pk('request.pem');

=item subject()

returns the subject of the PKCS10 request

  $subject = $req->subject();

=item keyinfo()

returns the human readable info about the key of the PKCS10 request

  $keyinfo = $req->keyinfo();

=back

=head2 EXPORT

None by default.

On request:

	NID_key_usage NID_subject_alt_name NID_netscape_cert_type NID_netscape_comment
	NID_ext_key_usage

=head1 BUGS

If you destroy $req object that is linked to a Crypt::OpenSSL::RSA object, the RSA private key is also freed, 
thus you can't use latter object anymore. Avoid this:
  
  my $rsa = Crypt::OpenSSL::RSA->generate_key(512);
  my $req = Crypt::OpenSSL::PKCS10->new_from_rsa($rsa);
  undef $req;
  print $rsa->get_private_key_string();

=head1 SEE ALSO

C<Crypt::OpenSSL::RSA>, C<Crypt::OpenSSL::X509>.

=head1 AUTHOR

JoNO, E<lt>jonozzz@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by JoNO

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
