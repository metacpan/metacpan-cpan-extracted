use v5.26;
use Object::Pad;

package Blockchain::Ethereum::Keystore::Key::PKUtil 0.005;
class Blockchain::Ethereum::Keystore::Key::PKUtil
    :isa(Crypt::Perl::ECDSA::PrivateKey);

=encoding utf8

=head1 SYNOPSIS

This is a child for L<Crypt::Perl::ECDSA::PrivateKey> to overwrite
the function _sign that on the parent module returns only C<$r> and C<$s>,
this version returns the C<$y_parity> as well, what simplifies signing
the transaction.

You don't want to use this directly, use instead L<Blockchain::Ethereum::Keystore::Key>

=cut;

use Carp;

=head2 _sign

Overwrites L<Crypt::Perl::ECDSA::PrivateKey> adding the y-parity to the response

Usage:

    _sign($rlp_encoded_transaction) -> (Math::BigInt $r, Math::BigInt $s, $v)

=over 4

=item * C<message> - Message to be signed

=back

L<Crypt::Perl::BigInt> r, L<Crypt::Perl::BigInt> s, uint y_parity

=cut

method _sign ($message) {

    my $dgst = Crypt::Perl::BigInt->from_bytes($message);

    my $priv_num = $self->{'private'};    # Math::BigInt->from_hex( $priv_hex );

    my $n = $self->_curve()->{'n'};

    my $key_len  = $self->max_sign_bits();
    my $dgst_len = $dgst->bit_length();
    if ($dgst_len > $key_len) {
        croak Crypt::Perl::X::create('TooLongToSign', $key_len, $dgst_len);
    }

    #isa ECPoint
    my $G = $self->_G();
    my ($k, $r, $Q);

    do {
        require Crypt::Perl::ECDSA::Deterministic;
        $k = Crypt::Perl::ECDSA::Deterministic::generate_k($n, $priv_num, $message, 'sha256');

        # making it external so I can calculate the y parity
        $Q = $G->multiply($k);    #$Q isa ECPoint

        $r = $Q->get_x()->to_bigint()->copy()->bmod($n);
    } while (!$r->is_positive());

    my $s = $k->bmodinv($n);

    #$s *= ( $dgst + ( $priv_num * $r ) );
    $s->bmul($priv_num->copy()->bmuladd($r, $dgst));

    $s->bmod($n);

    # y parity calculation
    # most of the changes unrelated to the parent module are bellow
    my $y_parity = ($Q->get_y->to_bigint->is_odd() ? 1 : 0) | ($Q->get_x->to_bigint->bcmp($r) != 0 ? 2 : 0);

    my $nb2;
    ($nb2, $_) = $n->copy->bdiv(2);

    if ($s->bcmp($nb2) > 0) {
        $s = $n->copy->bsub($s);
        $y_parity ^= 1;
    }

    return ($r, $s, $y_parity);
}

1;

__END__

=head1 AUTHOR

Reginaldo Costa, C<< <refeco at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/refeco/perl-ethereum-keystore>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by REFECO.

This is free software, licensed under:

  The MIT License

=cut
