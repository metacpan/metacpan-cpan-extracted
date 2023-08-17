use v5.26;
use Object::Pad;

package Blockchain::Ethereum::ABI::TypeRole 0.011;
role Blockchain::Ethereum::ABI::TypeRole;

=head2 encode

Encodes the given data to the type of the signature

Usage:

    encode() -> encoded string

=over 4

=back

ABI encoded hex string

=cut

method encode;

=head2 decode

Decodes the given data to the type of the signature

Usage:

    decoded() -> check the child classes for return type

=over 4

=back

check the child classes for return type

=cut

method decode;

method _configure;

1;

__END__

=head1 AUTHOR

Reginaldo Costa, C<< <refeco at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/refeco/perl-ABI>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by REFECO.

This is free software, licensed under:

  The MIT License

=cut
