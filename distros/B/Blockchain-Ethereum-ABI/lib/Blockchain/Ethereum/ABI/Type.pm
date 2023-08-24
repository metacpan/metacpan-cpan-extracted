use v5.26;
use Object::Pad ':experimental(init_expr)';

package Blockchain::Ethereum::ABI::Type 0.012;
class Blockchain::Ethereum::ABI::Type;

=encoding utf8

=head1 NAME

Blockchain::Ethereum::ABI::Type - Interface for solidity variable types

=head1 SYNOPSIS

Allows you to define and instantiate a solidity variable type:

    my $type = Blockchain::Ethereum::ABI::Type->new(
        signature => $signature,
        data      => $value
    );

    $type->encode();

In most cases you don't want to use this directly, use instead:

=over 4

=item * B<Encoder>: L<Blockchain::Ethereum::ABI::Encoder>

=item * B<Decoder>: L<Blockchain::Ethereum::ABI::Decoder>

=back

=cut

use Carp;
use Module::Load;

field $signature :reader :writer :param = undef;
field $data :reader :writer :param      = undef;

field $_static :reader(_static)                              = [];
field $_dynamic :reader(_dynamic)                            = [];
field $_instances :reader(_instances) :writer(set_instances) = [];

ADJUST {
    if ($self->signature) {
        my $module;
        if ($self->signature =~ /\[(\d+)?\]$/gm) {
            $module = "Array";
        } elsif ($self->signature =~ /^\(.*\)/) {
            $module = "Tuple";
        } elsif ($self->signature =~ /^address$/) {
            $module = "Address";
        } elsif ($self->signature =~ /^(u)?(int|bool)(\d+)?$/) {
            $module = "Int";
        } elsif ($self->signature =~ /^(?:bytes)(\d+)?$/) {
            $module = "Bytes";
        } elsif ($self->signature =~ /^string$/) {
            $module = "String";
        } else {
            croak "Module not found for the given parameter signature $signature";
        }

        # this is just to avoid `use module` for every new type included
        my $package = "Blockchain::Ethereum::ABI::Type::$module";
        load $package;

        $self = bless $self, $package;
        $self->_configure;
    }
}

method _push_static ($data) {

    push($self->_static->@*, ref $data eq 'ARRAY' ? $data->@* : $data);
}

method _push_dynamic ($data) {

    push($self->_dynamic->@*, ref $data eq 'ARRAY' ? $data->@* : $data);
}

=head2 pad_right

Pads the given data to right 32 bytes with zeros

Usage:

    pad_right("1") -> "100000000000..0"

=over 4

=item * C<$data> data to be padded

=back

Returns the padded string

=cut

method pad_right ($data) {

    my @chunks;
    push(@chunks, $_ . '0' x (64 - length $_)) for unpack("(A64)*", $data);

    return \@chunks;
}

=head2 pad_left

Pads the given data to left 32 bytes with zeros

Usage:

    pad_left("1") -> "0000000000..1"

=over 4

=item * C<$data> data to be padded

=back

=cut

method pad_left ($data) {

    my @chunks;
    push(@chunks, sprintf("%064s", $_)) for unpack("(A64)*", $data);

    return \@chunks;

}

method _encode_length ($length) {

    return sprintf("%064s", sprintf("%x", $length));
}

method _encode_offset ($offset) {

    return sprintf("%064s", sprintf("%x", $offset * 32));
}

method _encoded {

    my @data = ($self->_static->@*, $self->_dynamic->@*);
    return scalar @data ? \@data : undef;
}

=head2 is_dynamic

Checks if the type signature is dynamic

Usage:

    is_dynamic() -> 1/0

=over 4

=back

Returns 1 for dynamic and 0 for static

=cut

method is_dynamic {

    return $self->signature =~ /(bytes|string)(?!\d+)|(\[\])/ ? 1 : 0;
}

# get the first index where data is set to the encoded value
# skipping the prefixed indexes
method _get_initial_offset {

    my $offset = 0;
    for my $param ($self->_instances->@*) {
        my $encoded = $param->encode;
        if ($param->is_dynamic) {
            $offset += 1;
        } else {
            $offset += scalar $param->_encoded->@*;
        }
    }

    return $offset;
}

=head2 fixed_length

Check if that is a length specified for the given signature

Usage:

    fixed_length() -> integer length or undef

=over 4

=back

Integer length or undef in case of no length specified

=cut

method fixed_length {

    if ($self->signature =~ /[a-z](\d+)/) {
        return $1;
    }
    return undef;
}

method _static_size {

    return 1;
}

# read the data at the encoded stack
method _read_stack_set_data {

    my @data = $self->data->@*;
    my @offsets;
    my $current_offset = 0;

    # Since at this point we don't information about the chunks of data it is_dynamic
    # needed to get all the offsets in the static header, so the dynamic values can
    # be retrieved based in between the current and the next offsets
    for my $instance ($self->_instances->@*) {
        if ($instance->is_dynamic) {
            push @offsets, hex($data[$current_offset]) / 32;
        }

        my $size = 1;
        $size = $instance->_static_size unless $instance->is_dynamic;
        $current_offset += $size;
    }

    $current_offset = 0;
    my %response;
    # Dynamic data must to be set first since the full_size method
    # will need to use the data offset related to the size of the item
    for (my $i = 0; $i < $self->_instances->@*; $i++) {
        my $instance = $self->_instances->[$i];
        next unless $instance->is_dynamic;
        my $offset_start = shift @offsets;
        my $offset_end   = $offsets[0] // scalar @data - 1;
        my @range        = @data[$offset_start .. $offset_end];
        $instance->set_data(\@range);
        $current_offset += scalar @range;
        $response{$i} = $instance->decode();
    }

    $current_offset = 0;

    for (my $i = 0; $i < $self->_instances->@*; $i++) {
        my $instance = $self->_instances->[$i];

        if ($instance->is_dynamic) {
            $current_offset++;
            next;
        }

        my $size = 1;
        $size = $instance->_static_size unless $instance->is_dynamic;
        my @range = @data[$current_offset .. $current_offset + $size - 1];
        $instance->set_data(\@range);
        $current_offset += $size;

        $response{$i} = $instance->decode();
    }

    my @array_response;
    # the given order of type signatures needs to be strict followed
    push(@array_response, $response{$_}) for 0 .. scalar $self->_instances->@* - 1;
    return \@array_response;
}

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
