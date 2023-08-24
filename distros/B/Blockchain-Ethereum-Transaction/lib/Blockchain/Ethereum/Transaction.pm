use v5.26;
use Object::Pad ':experimental(init_expr)';

package Blockchain::Ethereum::Transaction 0.008;
role Blockchain::Ethereum::Transaction;

=encoding utf8

=head1 NAME

Blockchain::Ethereum::Transaction - Ethereum transaction abstraction

=head1 SYNOPSIS

In most cases you don't want to use this directly, use instead:

=over 4

=item * B<Legacy>: L<Blockchain::Ethereum::Transaction::Legacy>

=item * B<EIP1559>: L<Blockchain::Ethereum::Transaction::EIP1559>

=back

=cut

use Carp;
use Crypt::Digest::Keccak256 qw(keccak256);

use Blockchain::Ethereum::RLP;

field $chain_id :reader :writer :param;
field $nonce :reader :writer :param;
field $gas_limit :reader :writer :param;
field $to :reader :writer :param    //= '';
field $value :reader :writer :param //= '0x0';
field $data :reader :writer :param  //= '';
field $v :reader :writer :param = undef;
field $r :reader :writer :param = undef;
field $s :reader :writer :param = undef;

field $rlp :reader = Blockchain::Ethereum::RLP->new();

=head2 serialize

To be implemented by the child classes, encodes the given transaction parameters to RLP

Usage:

    serialize() -> RLP encoded transaction bytes

=over 4

=back

Returns the RLP encoded transaction bytes

=cut

method serialize;

=head2 generate_v

Generate the transaction v field using the given y-parity

Usage:

    generate_v($y_parity) -> hexadecimal v

=over 4

=item * C<$y_parity> y-parity

=back

Returns the v hexadecimal value also sets the v fields from transaction

=cut

method generate_v;

=head2 hash

SHA3 Hash the serialized transaction object

Usage:

    hash() -> SHA3 transaction hash

=over 4

=back

Returns the SHA3 transaction hash bytes

=cut

method hash {

    return keccak256($self->serialize);
}

# In case of Math::BigInt given for any params, get the hex value
method _equalize_params ($params) {

    return [map { ref $_ eq 'Math::BigInt' ? $_->as_hex : $_ } $params->@*];
}

1;

__END__

=head1 AUTHOR

Reginaldo Costa, C<< <refeco at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/refeco/perl-ethereum-transaction>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by REFECO.

This is free software, licensed under:

  The MIT License

=cut
