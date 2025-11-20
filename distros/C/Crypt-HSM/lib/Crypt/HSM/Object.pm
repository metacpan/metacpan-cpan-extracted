package Crypt::HSM::Object;
$Crypt::HSM::Object::VERSION = '0.023';
use strict;
use warnings;

# Contains the actual implementation
use Crypt::HSM;

1;

#ABSTRACT: A PKCS11 object

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::HSM::Object - A PKCS11 object

=head1 VERSION

version 0.023

=head1 SYNOPSIS

 my ($key) = $session->find_objects({ label => $label, encrypt => 1 });
 if (not $key) {
	$key = $session->generate_key('aes-key-gen', { label => $label, sensitive => 1, "value-len" => 32 });
 }
 $session->encrypt('aes-gcm', $key, $plaintext, $nonce);

=head1 DESCRIPTION

This class represents an object (usually a key) in the HSM's database. The type of the object us stored in the C<class> attribute, and can be one of C<data>, C<certificate>, C<public-key>, C<private-key>, C<secret-key>, C<hw-feature>, C<domain-parameters>, C<mechanism>, C<otp-key>, C<profile>, or C<vendor-defined>; this type will define what other attributes are available for it.

It's returned by L<Crypt::HSM::Session|Crypt::HSM::Session> methods like C<find_object> and C<generate_key>, and used in methods such as C<encrypt>, C<decrypt>, C<sign> and C<verify>.

=head1 METHODS

=head2 copy_object($attributes)

Copy the object, optionally adding/modifying the given attributes.

=head2 destroy_object()

This deletes this object from the slot.

=head2 get_attribute($attribute_name)

This returns the value of the named attribute of the object.

=head2 get_attributes(\@attribute_list)

This returns a hash with the attributes of the object that are asked for.

=head2 object_size()

This returns the size of this object.

=head2 set_attributes($attributes)

This sets the C<$attributes> on this object.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
