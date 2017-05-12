package Crypt::NSS::Certificate;

use strict;
use warnings;

# Method aliases
*get_issuer = \&issuer;
*issuer_name = \&issuer;
*get_subject = \&subject;
*subject_name = \&subject;
*get_email_address = \&email_address;
*get_public_key = \&public_key;

sub is_valid_now {
    my $self = shift;
    my ($sec, $min, $hour, $mday, $month, $year) = (localtime(time))[0..5];
    return $self->get_validity_for_datetime($year + 1900, $month, $mday, $hour, $min, $sec) == 0;
}


1;
__END__

=head1 NAME

Crypt::NSS::Certificate - X.509 certificate and related fuctions

=head1 INTERFACE

=head2 CLASS METHODS

=over 4

=item from_base64_DER ( $data : string ) : Crypt::NSS::Certificate

Creates a new certificate from a Base64 encoded DER string.

=back

=head2 INSTANCE METHODS

=head3 Getting information about the certificate

=over 4

=item issuer ( ) : string

=item get_issuer ( ) : string

=item issuer_name ( ) : string

Returns the DN of the issuer of the certificate.

=item subject ( ) : string

=item get_subject ( ) : string

=item subject_name ( ) : string

Returns the certificates DN.

=item email_address ( ) : string

=item get_email_address ( ) : string

Returns the email address of the certificate if any.

=item public_key ( ) : Crypt::NSS::PublicKey

=item get_public_key ( ) : Crypt::NSS::PublicKey

Returns the certificates public key.

=back

=head3 Verifying the certificate

=over 4

=item verify_hostname ( $pattern : string ) : boolean

Verifies that the hostname in the certificate matches the given hostname pattern.

=item get_validity_for_datetime( $year : integer, $month : integer, $day : integer [, $hour : integer, $minute : integer, $second : integer, $usec : integer ]) : integer

Checks if the certificate is valid for the given date and optional time. Returns -1 if the certificate has expired, 
0 if it's still valid or 1 if it's not valid yet but will be in the future.

=item is_valid_now ( ) : boolean

Checks if the certificate is valid now (localtime).

=back

=head3 Miscellaneous methods

=over 4

=item clone ( ) : Crypt::NSS::Certificate

Returns a copy of the certificate.

=back

=cut

