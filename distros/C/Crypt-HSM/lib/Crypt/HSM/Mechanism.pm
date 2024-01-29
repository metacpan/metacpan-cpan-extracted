package Crypt::HSM::Mechanism;
$Crypt::HSM::Mechanism::VERSION = '0.016';
use strict;
use warnings;

# Contains the actual implementation
use Crypt::HSM;

1;

#ABSTRACT: A PKCS11 mechanism

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::HSM::Mechanism - A PKCS11 mechanism

=head1 VERSION

version 0.016

=head1 SYNOPSIS

 my @signers = grep { $_->has_flags('sign', 'verify') } $slot->mechanisms;

=head1 DESCRIPTION

This represents a mechanism in a PKCS implementation.

=head1 METHODS

=head2 name()

This returns the name of the mechanism

=head2 min_key_size()

This returns the minimum key size for this mechanism.

=head2 max_key_size()

This returns the maximum key size for this mechanism.

=head2 flags()

This array lists properties of the mechanism. It may contain values like C<'encrypt'>, C<'decrypt'>, C<'sign'>, C<'verify'>, C<'generate'>, C<'wrap'> and C<'unwrap'>.

=head2 has_flags(@flags)

This returns true the flags contain all of C<@flags>.

=head2 info()

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

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
