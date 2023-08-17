use v5.26;
use Object::Pad;

package Blockchain::Ethereum::RLP 0.006;
class Blockchain::Ethereum::RLP;

=encoding utf8

=head1 NAME

Blockchain::Ethereum::RLP - Ethereum RLP encoding/decoding utility

=head1 SYNOPSIS

Allow RLP encoding and decoding

    my $rlp = Blockchain::Ethereum::RLP->new();

    my $tx_params  = ['0x9', '0x4a817c800', '0x5208', '0x3535353535353535353535353535353535353535', '0xde0b6b3a7640000', '0x', '0x1', '0x', '0x'];
    my $encoded = $rlp->encode($params); #ec098504a817c800825208943535353535353535353535353535353535353535880de0b6b3a764000080018080

    my $encoded_tx_params = 'ec098504a817c800825208943535353535353535353535353535353535353535880de0b6b3a764000080018080';
    my $decoded = $rlp->decode(pack "H*", $encoded_tx_params); #['0x9', '0x4a817c800', '0x5208', '0x3535353535353535353535353535353535353535', '0xde0b6b3a7640000', '0x', '0x1', '0x', '0x']

=cut

use Carp;

use constant {
    STRING                  => 'string',
    LIST                    => 'list',
    SINGLE_BYTE_MAX_LENGTH  => 128,
    SHORT_STRING_MAX_LENGTH => 183,
    LONG_STRING_MAX_LENGTH  => 192,
    LIST_MAX_LENGTH         => 247,
    LONG_LIST_MAX_LENGTH    => 255,
    BYTE_LENGTH_DELIMITER   => 55,
    INPUT_LENGTH_DELIMITER  => 256,
};

=head2 encode

Encodes the given input to RLP

Usage:

    encode(hex string /  hex array reference) ->  encoded bytes

=over 4

=item * C<$input> hexadecimal string or reference to an hexadecimal string array

=back

Return the encoded bytes

=cut

method encode ($input) {

    croak 'No input given' unless defined $input;

    if (ref $input eq 'ARRAY') {
        my $output = '';
        $output .= $self->encode($_) for $input->@*;

        return $self->_encode_length(length($output), LONG_STRING_MAX_LENGTH) . $output;
    }

    my $hex = $input =~ s/^0x//r;

    # zero will be considered empty as per RLP specification
    unless ($hex) {
        $hex = chr(0x80);
        return $hex;
    }

    # pack will add a null character at the end if the length is odd
    # RLP expects this to be added at the left instead.
    $hex = "0$hex" if length($hex) % 2 != 0;
    $hex = pack("H*", $hex);

    my $input_length = length $hex;

    return $hex if $input_length == 1 && ord $hex < SINGLE_BYTE_MAX_LENGTH;
    return $self->_encode_length($input_length, SINGLE_BYTE_MAX_LENGTH) . $hex;
}

method _encode_length ($length, $offset) {

    return chr($length + $offset) if $length <= BYTE_LENGTH_DELIMITER;

    if ($length < INPUT_LENGTH_DELIMITER**8) {
        my $bl = $self->_to_binary($length);
        return chr(length($bl) + $offset + BYTE_LENGTH_DELIMITER) . $bl;
    }

    croak "Input too long";
}

method _to_binary ($x) {

    return '' unless $x;
    return $self->_to_binary(int($x / INPUT_LENGTH_DELIMITER)) . chr($x % INPUT_LENGTH_DELIMITER);
}

=head2 decode

Decode the given input from RLP to the specific return type

Usage:

    decode(RLP encoded bytes) -> hexadecimal string / array reference

=over 4

=item * C<$input> RLP encoded bytes

=back

Returns an hexadecimals string or an array reference in case of multiple items

=cut

method decode ($input) {

    return [] unless length $input;

    my ($offset, $data_length, $type) = $self->_decode_length($input);

    # string
    if ($type eq STRING) {
        my $hex = unpack("H*", substr($input, $offset, $data_length));
        # same as for the encoding we do expect an prefixed 0 for
        # odd length hexadecimal values, this just removes the 0 prefix.
        $hex = substr($hex, 1) if $hex =~ /^0/ && (length($hex) - 1) % 2 != 0;
        return '0x' . $hex;
    }

    # list
    my @output;
    my $list_data   = substr($input, $offset, $data_length);
    my $list_offset = 0;
    # recursive arrays
    while ($list_offset < length($list_data)) {
        my ($item_offset, $item_length, $item_type) = $self->_decode_length(substr($list_data, $list_offset));
        my $list_item = $self->decode(substr($list_data, $list_offset, $item_offset + $item_length));
        push @output, $list_item;
        $list_offset += $item_offset + $item_length;
    }

    return \@output;
}

method _decode_length ($input) {

    my $length = length($input);
    croak "Invalid empty input" unless $length;

    my $prefix = ord(substr($input, 0, 1));

    my $short_string = $prefix - SINGLE_BYTE_MAX_LENGTH;
    my $long_string  = $prefix - SHORT_STRING_MAX_LENGTH;
    my $list         = $prefix - LONG_STRING_MAX_LENGTH;
    my $long_list    = $prefix - LIST_MAX_LENGTH;

    if ($prefix < SINGLE_BYTE_MAX_LENGTH) {
        # single byte
        return (0, 1, STRING);
    } elsif ($prefix <= SHORT_STRING_MAX_LENGTH && $length > $short_string) {
        # short string
        return (1, $short_string, STRING);
    } elsif ($prefix <= LONG_STRING_MAX_LENGTH
        && $length > $long_string
        && $length > $long_string + $self->_to_integer(substr($input, 1, $long_string)))
    {
        # long string
        my $str_length = $self->_to_integer(substr($input, 1, $long_string));
        return (1 + $long_string, $str_length, STRING);
    } elsif ($prefix < LIST_MAX_LENGTH && $length > $list) {
        # list
        return (1, $list, LIST);
    } elsif ($prefix <= LONG_LIST_MAX_LENGTH
        && $length > $long_list
        && $length > $long_list + $self->_to_integer(substr($input, 1, $long_list)))
    {
        # long list
        my $list_length = $self->_to_integer(substr($input, 1, $long_list));
        return (1 + $long_list, $list_length, LIST);
    }

    croak "Invalid RLP input";
}

method _to_integer ($b) {

    my $length = length($b);
    croak "Invalid empty input" unless $length;

    return ord($b) if $length == 1;

    return ord(substr($b, -1)) + $self->_to_integer(substr($b, 0, -1)) * INPUT_LENGTH_DELIMITER;
}

1;

__END__

=head1 AUTHOR

Reginaldo Costa, C<< <refeco at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/refeco/perl-RPL>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by REFECO.

This is free software, licensed under:

  The MIT License

=cut
