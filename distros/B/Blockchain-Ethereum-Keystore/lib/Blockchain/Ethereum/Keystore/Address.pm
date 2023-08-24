use v5.26;
use Object::Pad;

package Blockchain::Ethereum::Keystore::Address 0.005;
class Blockchain::Ethereum::Keystore::Address;

=encoding utf8

=head1 NAME

Blockchain::Ethereum::Keystore::Address

=head1 SYNOPSIS

Address utilities

    my $address = Blockchain::Ethereum::Address->new(0x...);
    print $address;
    ...

=cut

use Carp;
use Crypt::Digest::Keccak256 qw(keccak256_hex);

field $address :reader :writer :param;

ADJUST {

    my $unprefixed = $self->address =~ s/^0x//r;

    croak 'Invalid address format' unless length($unprefixed) == 40;

    my @hashed_chars      = split //, keccak256_hex(lc $unprefixed);
    my @address_chars     = split //, $unprefixed;
    my $checksummed_chars = '';

    $checksummed_chars .= hex $hashed_chars[$_] >= 8 ? uc $address_chars[$_] : lc $address_chars[$_] for 0 .. length($unprefixed) - 1;

    $self->set_address($checksummed_chars);
}

method no_prefix {

    my $unprefixed = $self->address =~ s/^0x//r;
    return $unprefixed;
}

use overload
    fallback => 1,
    '""'     => \&to_string;

method to_string {

    return $self->address if $self->address =~ /^0x/;
    return '0x' . $self->address;
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

