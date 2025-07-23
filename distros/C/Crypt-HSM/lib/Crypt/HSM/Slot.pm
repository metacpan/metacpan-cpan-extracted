package Crypt::HSM::Slot;
$Crypt::HSM::Slot::VERSION = '0.021';
use strict;
use warnings;

# Contains the actual implementation
use Crypt::HSM;

1;

#ABSTRACT: A PKCS11 slot

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::HSM::Slot - A PKCS11 slot

=head1 VERSION

version 0.021

=head1 SYNOPSIS

 my $session = $slot->open_session;

=head1 DESCRIPTION

This represents a slot on a PKCS implementation.

=head1 METHODS

=head2 open_session($flags = [])

This opens a L<Crypt::HSM::Session|Crypt::HSM::Session> to this slot. C<$flag> is an optional array that may currently contain the value C<'rw-session'> to enable writing to the token.

=head2 mechanisms()

This returns all mechanisms supported by the token in the slot as L<Crypt::HSM::Mechanism|Crypt::HSM::Mechanism> objects.

=head2 mechanism($name)

This returns the named mechanism as a L<Crypt::HSM::Mechanism|Crypt::HSM::Mechanism> object.

=head2 id()

This returns the identifier of this slot.

=head2 close_all_sessions()

This closes all sessions on this slot.

=head2 info()

This returns a hash with information about the slot.

=head2 token_info()

This returns a hash with information about the token in the slot.

=head2 init_token($pin, $label)

This initializes a token on the slot, with the associalted C<$pin> and C<$label> (max 32 characters).

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
