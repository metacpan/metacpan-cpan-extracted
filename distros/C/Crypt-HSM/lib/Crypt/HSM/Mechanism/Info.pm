package Crypt::HSM::Mechanism::Info;
$Crypt::HSM::Mechanism::Info::VERSION = '0.021';
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

version 0.021

=head1 METHODS

=head2 min_key_size()

This returns the minimum key size for this mechanism.

=head2 max_key_size()

This returns the maximum key size for this mechanism.

=head2 flags()

This array lists properties of the mechanism. It may contain values like C<'encrypt'>, C<'decrypt'>, C<'sign'>, C<'verify'>, C<'generate'>, C<'wrap'> and C<'unwrap'>.

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
