package Crypt::HSM::Key;
$Crypt::HSM::Key::VERSION = '0.017';
use strict;
use warnings;

# Contains the actual implementation
use Crypt::HSM;

1;

#ABSTRACT: A PKCS11 key object

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::HSM::Key - A PKCS11 key object

=head1 VERSION

version 0.017

=head1 SYNOPSIS

=head1 DESCRIPTION

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
