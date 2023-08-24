use v5.26;
use Object::Pad;

package Blockchain::Ethereum::Keystore::Seed 0.005;
class Blockchain::Ethereum::Keystore::Seed;

=encoding utf8

=head1 NAME

Blockchain::Ethereum::Keystore::Seed

=head1 SYNOPSIS

If instantiated without a seed or mnemonic, this module uses L<Crypt::PRNG> for the random seed generation

    my $seed = Blockchain::Ethereum::Seed->new;
    my $key = $seed->deriv_key(2);
    print $key->address;
    ...

=cut

use Carp;
use Crypt::PRNG     qw(random_bytes);
use Bitcoin::Crypto qw(btc_extprv);

use Blockchain::Ethereum::Keystore::Key;

field $seed :reader :writer :param     //= undef;
field $mnemonic :reader :writer :param //= undef;
field $salt :reader :writer :param     //= undef;

field $_hdw_handler :reader(_hdw_handler) :writer(set_hdw_handler);

ADJUST {
    if ($self->seed) {
        $self->set_hdw_handler(btc_extprv->from_hex_seed(unpack "H*", $self->seed));
    } elsif ($self->mnemonic) {
        $self->set_hdw_handler(btc_extprv->from_mnemonic($self->mnemonic, $self->salt));
    }

    unless ($self->_hdw_handler) {
        # if the seed is not given, generate a new one
        $self->set_seed(random_bytes(64));
        $self->set_hdw_handler(btc_extprv->from_hex_seed(unpack "H*", $self->seed));
    }
}

method derive_key ($index, $account = 0, $purpose = 44, $coin_type = 60, $change = 0) {

    my $path = Bitcoin::Crypto::BIP44->new(
        index     => $index,
        purpose   => $purpose,
        coin_type => $coin_type,
        account   => $account,
        change    => $change,
    );

    return Blockchain::Ethereum::Keystore::Key->new(
        private_key => pack "H*",
        $self->_hdw_handler->derive_key($path)->get_basic_key->to_hex
    );

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

