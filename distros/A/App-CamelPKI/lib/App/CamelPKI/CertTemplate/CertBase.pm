#! perl -w

package App::CamelPKI::CertTemplate::CertBase;
use strict;
use warnings;

use base "App::CamelPKI::CertTemplate";
use App::CamelPKI::Error;
use App::CamelPKI::Time;

=head1 NAME

I<App::CamelPKI::CertTemplate::CertBase> - Open templates for certificates.

=cut

=head2 fillCommon($cacert, $cert)

Fills common fields for all open templates, from $cacert. These fields
are extensions, issuer DN, creation and validation dates.

=cut

sub fillCommon {
	my ($class, $cacert, $cert) = @_;

	$cert->set_extension("basicConstraints", "CA:FALSE",
                             -critical => 1);
	$cert->set_issuer_DN($cacert->get_subject_DN);

	$cert->set_notBefore(App::CamelPKI::Time->now->zulu);
	$cert->set_notAfter($cacert->get_notAfter);

	$cert->set_extension("subjectKeyIdentifier",
                             $cert->get_public_key->get_openssl_keyid);
}

=head2 fill_subject_DN($cert, @dn)

Sets the subject DN in $cert to @dn, which is a list alternating DN
keys and values in reverse RFC4514 order, without the leading ("O",
"camel.fr") prefix which is implied.  The DN will be set
in UTF-8 in the certificate, pursuant to RFC3280 § 4.1.2.4.

=cut

sub fill_subject_DN {
    my ($class, $cert, @dn) = @_;

     my $subject=Crypt::OpenSSL::CA::X509_NAME->new_utf8
         (O => "CamelPKI.fr",
          @dn);
    $cert->set_subject_DN($subject);
}

print "1..0\n" unless caller; # Sorry surrogate for a test suite

1;
