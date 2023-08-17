use v5.26;
use Object::Pad;

package Blockchain::Ethereum::Keystore::Address 0.002;
class Blockchain::Ethereum::Keystore::Address;

use Carp;
use Digest::Keccak qw(keccak_256_hex);

field $address :reader :writer :param;

ADJUST {

    my $unprefixed = $self->address =~ s/^0x//r;

    croak 'Invalid address format' unless length($unprefixed) == 40;

    my @hashed_chars      = split //, keccak_256_hex(lc $unprefixed);
    my @address_chars     = split //, $unprefixed;
    my $checksummed_chars = '';

    $checksummed_chars .= hex $hashed_chars[$_] >= 8 ? uc $address_chars[$_] : lc $address_chars[$_] for 0 .. length($unprefixed) - 1;

    $self->set_address($checksummed_chars);
}

method unprefixed {

    my $unprefixed = $self->address =~ s/^0x//r;
    return $unprefixed;
}

method prefixed {

    return $self->address if $self->address =~ /^0x/;
    return '0x' . $self->address;
}

1;
