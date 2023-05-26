package Blockchain::Ethereum::RLP;

use v5.26;
use strict;
use warnings;

use Carp;

use constant {
    STRING => 'str',
    LIST   => 'list'
};

sub new {
    my ($class, %params) = @_;

    my $self = {};
    bless $self, $class;
    return $self;
}

sub encode {
    my ($self, $input) = @_;

    if (ref $input eq 'ARRAY') {
        my $output = '';
        $output .= $self->encode($_) for $input->@*;

        return $self->_encode_length(length($output), 0xc0) . $output;
    }

    $input =~ s/^0x//g;

    # pack will add a null character at the end if the length is odd
    # RLP expects this to be added at the left instead.
    $input = "0$input" if length($input) % 2 != 0;

    $input = pack("H*", $input);

    my $input_length = length $input;

    return $input if $input_length == 1 && ord $input < 0x80;
    return $self->_encode_length($input_length, 0x80) . $input;
}

sub _encode_length {
    my ($self, $l, $offset) = @_;

    return chr($l + $offset) if $l < 56;

    if ($l < 256**8) {
        my $bl = $self->_to_binary($l);
        return chr(length($bl) + $offset + 55) . $bl;
    }

    croak "Input too long";
}

sub _to_binary {
    my ($self, $x) = @_;
    return '' if $x == 0;
    return $self->_to_binary(int($x / 256)) . chr($x % 256);
}

sub decode {
    my ($self, $input) = @_;

    return [] unless length $input;

    my @output;
    my ($offset, $data_length, $type) = $self->_decode_length($input);

    if ($type eq STRING) {
        my $hex = unpack("H*", substr($input, $offset, $data_length));
        # same as for the encoding we do expect an prefixed 0 for
        # odd length hexadecimal values, this just removes the 0 prefix.
        $hex = substr($hex, 1) if $hex =~ /^0/ && (length($hex) - 1) % 2 != 0;
        push @output, '0x' . $hex;
    } elsif ($type eq LIST) {
        push @output, @{$self->decode(substr($input, $offset, $data_length))};
    }

    push @output, @{$self->decode(substr($input, $offset + $data_length))};

    # array reference is returned for both cases, in case of an string value
    # just use the first element of the array.
    return \@output;
}

sub _decode_length {
    my ($self, $input) = @_;

    my $length = length($input);
    croak "Invalid empty input" unless $length;

    my $prefix = ord(substr($input, 0, 1));

    if ($prefix <= 0x7f) {
        # single byte
        return (0, 1, STRING);
    } elsif ($prefix <= 0xb7 && $length > $prefix - 0x80) {
        # short string
        my $str_length = $prefix - 0x80;
        return (1, $str_length, STRING);
    } elsif ($prefix <= 0xbf && $length > $prefix - 0xb7 && $length > $prefix - 0xb7 + $self->_to_integer(substr($input, 1, $prefix - 0xb7))) {
        # long string
        my $str_prefix_length = $prefix - 0xb7;
        my $str_length        = $self->_to_integer(substr($input, 1, $str_prefix_length));
        return (1 + $str_prefix_length, $str_length, STRING);
    } elsif ($prefix <= 0xf7 && $length > $prefix - 0xc0) {
        # list
        my $list_length = $prefix - 0xc0;
        return (1, $list_length, LIST);
    } elsif ($prefix <= 0xff && $length > $prefix - 0xf7 && $length > $prefix - 0xf7 + $self->_to_integer(substr($input, 1, $prefix - 0xf7))) {
        # long list
        my $list_prefix_length = $prefix - 0xf7;
        my $list_length        = $self->_to_integer(substr($input, 1, $list_prefix_length));
        return (1 + $list_prefix_length, $list_length, LIST);
    }

    croak "Invalid RLP input";
}

sub _to_integer {
    my ($self, $b) = @_;

    my $length = length($b);
    croak "Invalid empty input" unless $length;

    return ord($b) if $length == 1;

    return ord(substr($b, -1)) + $self->_to_integer(substr($b, 0, -1)) * 256;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Blockchain::Ethereum::RLP - Ethereum RLP encoding/decoding utility

=head1 VERSION

Version 0.001

=cut

our $VERSION = '0.001';

=head1 SYNOPSIS

Allow RLP encoding and decoding

This class is basically an transpilation of the RLP encode/decode python sample given at L<https://ethereum.org/en/developers/docs/data-structures-and-encoding/rlp/>

    my $rlp = Blockchain::Ethereum::RLP->new();

    my $tx_params  = ['0x9', '0x4a817c800', '0x5208', '0x3535353535353535353535353535353535353535', '0xde0b6b3a7640000', '0x', '0x1', '0x', '0x'];
    my $encoded = $rlp->encode($params); #ec098504a817c800825208943535353535353535353535353535353535353535880de0b6b3a764000080018080

    my $encoded_tx_params = 'ec098504a817c800825208943535353535353535353535353535353535353535880de0b6b3a764000080018080';
    my $decoded = $rlp->decode(pack "H*", $encoded_tx_params); #['0x9', '0x4a817c800', '0x5208', '0x3535353535353535353535353535353535353535', '0xde0b6b3a7640000', '0x', '0x1', '0x', '0x']
    ...

=head1 METHODS

=head2 encode

Encodes the given input to RLP

=over 4 

=item * C<$input> hexadecimal string or reference to an hexadecimal string array

=back

Return the encoded bytes

=cut

=head2 decode

=over 4 

=item * C<$input> RLP encoded bytes

=back

Returns an hexadecimal array reference

=cut

=head1 AUTHOR

Reginaldo Costa, C<< <refeco at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/refeco/perl-RPL>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Blockchain::Ethereum::RLP

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by REFECO.

This is free software, licensed under:

  The MIT License

=cut
