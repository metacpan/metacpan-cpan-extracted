package Blockchain::Ethereum::Keystore::Seed;

use v5.26;
use strict;
use warnings;

# ABSTRACT: Seed abstraction
our $AUTHORITY = 'cpan:REFECO';    # AUTHORITY
our $VERSION   = '0.019';          # VERSION

use Carp;
use Crypt::PRNG     qw(random_bytes);
use Bitcoin::Crypto qw(btc_extprv);

use Blockchain::Ethereum::Keystore::Key;

sub new {
    my ($class, %params) = @_;

    my $self = bless {}, $class;
    foreach (qw(seed mnemonic salt)) {
        $self->{$_} = $params{$_} if exists $params{$_};
    }

    if ($self->seed) {
        $self->{hdw_handler} = btc_extprv->from_seed($self->seed);
    } elsif ($self->mnemonic) {
        $self->{hdw_handler} = btc_extprv->from_mnemonic($self->mnemonic, $self->salt);
    }

    unless ($self->_hdw_handler) {
        # if the seed is not given, generate a new one
        $self->{seed}        = random_bytes(64);
        $self->{hdw_handler} = btc_extprv->from_seed($self->seed);
    }

    return $self;
}

sub seed {
    shift->{seed};
}

sub mnemonic {
    shift->{mnemonic};
}

sub salt {
    shift->{salt};
}

sub _hdw_handler {
    shift->{hdw_handler};
}

sub derive_key {
    my ($self, $index, $account, $purpose, $coin_type, $change) = @_;

    $account   = 0  unless $account;
    $purpose   = 44 unless $purpose;
    $coin_type = 60 unless $coin_type;
    $change    = 0  unless $change;

    my $path = Bitcoin::Crypto::BIP44->new(
        index     => $index,
        purpose   => $purpose,
        coin_type => $coin_type,
        account   => $account,
        change    => $change,
    );

    return Blockchain::Ethereum::Keystore::Key->new(private_key => $self->_hdw_handler->derive_key($path)->get_basic_key->to_serialized);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Blockchain::Ethereum::Keystore::Seed - Seed abstraction

=head1 VERSION

version 0.019

=head1 SYNOPSIS

Creating a new seed and derivating the key from it:

    my $seed = Blockchain::Ethereum::Seed->new;
    my $key = $seed->deriv_key(2); # Blockchain::Ethereum::Keystore::Key
    print $key->address;

Importing a mnemonic:

    my $seed = Blockchain::Ethereum::Seed->new(mnemonic => 'your mnemonic here');

Importing seed bytes:

    my $hex_seed = '...';
    my $seed = Blockchain::Ethereum::Seed->new(seed => pack("H*", $hex_seed));

=head1 OVERVIEW

If instantiated without a seed or mnemonic, this module uses L<Crypt::PRNG> for the random seed generation

=head1 METHODS

=head2 deriv_key

Derivates a L<Blockchain::Ethereum::Keystore::Key> for the given index

=over 4

=item * C<$index> key index

=item * C<$account> [optional, default 0] account index

=item * C<$purpose> [optional, default 44] improvement proposal

=item * C<$coin_type> [optional, default 60] coin type code

=back

L<Blockchain::Ethereum::Keystore::Key>

=head1 AUTHOR

REFECO <refeco@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by REFECO.

This is free software, licensed under:

  The MIT (X11) License

=cut
