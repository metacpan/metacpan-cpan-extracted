package Crypt::HSM::Mechanism::Info;
$Crypt::HSM::Mechanism::Info::VERSION = '0.023';
use strict;
use warnings;

# Contains the actual implementation
use Crypt::HSM;

1;

#ABSTRACT: PKCS11 mechanism information

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::HSM::Mechanism::Info - PKCS11 mechanism information

=head1 VERSION

version 0.023

=head1 METHODS

=head2 min_key_size()

This returns the minimum key size for this mechanism.

=head2 max_key_size()

This returns the maximum key size for this mechanism.

=head2 flags()

This hash with properties of the mechanism. It contains the following entries:

=over 4

=item * C<hw>

True if the mechanism is performed by the device; false if the mechanism is performed in software.

=item * C<encrypt>

true if the mechanism can be used with c<encrypt>.

=item * C<decrypt>

True if the mechanism can be used with C<decrypt>

=item * C<digest>

True if the mechanism can be used with C<digest>

=item * C<sign>

True if the mechanism can be used with C<sign>

=item * C<sign-recover>

True if the mechanism can be used with C<sign_recover>

=item * C<verify>

True if the mechanism can be used with C<verify>

=item * C<verify-recover>

True if the mechanism can be used with C<verify_recover>

=item * C<generate>

True if the mechanism can be used with C<generate>

=item * C<generate-key-pair>

True if the mechanism can be used with C<generate_key_pair>

=item * C<wrap>

True if the mechanism can be used with C<wrap>

=item * C<unwrap>

True if the mechanism can be used with C<unwrap>

=item * C<derive>

True if the mechanism can be used with C<derive>

=item * C<extension>

True if there is an extension to the flags; false if no extensions.

=back

=head2 has_flags(@flags)

This returns true the flags contain all of C<@flags>.

=head2 hash()

This returns a hash with information about the mechanism. This includes the following fields.

=over 4

=item * min-key-size

The minimum key size

=item * max-key-size

The maximum key size

=item * flags

This contains the flags much like the C<flags> method.

=back

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
