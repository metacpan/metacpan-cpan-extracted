package Blockchain::Ethereum::Keystore::Address;

use v5.26;
use strict;
use warnings;

# ABSTRACT: Ethereum address abstraction
our $AUTHORITY = 'cpan:REFECO';    # AUTHORITY
our $VERSION   = '0.019';          # VERSION

use Carp;
use Crypt::Digest::Keccak256 qw(keccak256_hex);

sub new {
    my ($class, %params) = @_;

    my $address = $params{address};
    croak "Required param address not given" unless $address;

    my $self = bless {}, $class;
    $self->{address} = $address;
    $self->_checksum;

    return $self;
}

sub address {
    return shift->{address};
}

sub _checksum {
    my ($self) = shift;

    my $unprefixed = $self->no_prefix;

    croak 'Invalid address format' unless length($unprefixed) == 40;

    my @hashed_chars      = split //, keccak256_hex(lc $unprefixed);
    my @address_chars     = split //, $unprefixed;
    my $checksummed_chars = '';

    $checksummed_chars .= hex $hashed_chars[$_] >= 8 ? uc $address_chars[$_] : lc $address_chars[$_] for 0 .. length($unprefixed) - 1;

    $self->{address} = "0x$checksummed_chars";
    return $self;
}

sub no_prefix {
    my $self = shift;

    my $unprefixed = $self->address =~ s/^0x//r;
    return $unprefixed;
}

use overload
    fallback => 1,
    '""'     => \&to_string;

sub to_string {
    my $self = shift;
    return $self->address;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Blockchain::Ethereum::Keystore::Address - Ethereum address abstraction

=head1 VERSION

version 0.019

=head1 SYNOPSIS

Import an existing address:

    my $address = Blockchain::Ethereum::Address->new(0x...);
    # print checksummed address
    print $address;

Generate a new address:

    my $key = Blockchain::Ethereum::Key->new;
    my $address = $key->address;

=head1 METHODS

=head2 no_prefix

Removes the 0x prefix

=over 4

=back

Returns the address string without the 0x prefix

=head2 to_string

Returns the checksummed 0x prefixed address

This function will be called as the default stringification method

=head1 AUTHOR

REFECO <refeco@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by REFECO.

This is free software, licensed under:

  The MIT (X11) License

=cut
