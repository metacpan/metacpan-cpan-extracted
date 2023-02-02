package Blockchain::Contract::Solidity::ABI::Type::Array;

use v5.26;
use strict;
use warnings;
no indirect;

use Carp;
use parent qw(Blockchain::Contract::Solidity::ABI::Type);

sub configure {
    my $self = shift;
    return unless $self->data;

    for my $item ($self->data->@*) {
        push $self->instances->@*,
            Blockchain::Contract::Solidity::ABI::Type::new_type(
            signature => $self->remove_parent,
            data      => $item
            );
    }
}

sub encode {
    my $self = shift;
    return $self->encoded if $self->encoded;

    my $length = scalar $self->data->@*;
    # for dynamic length arrays the length must be included
    $self->push_static($self->encode_length($length))
        unless $self->fixed_length;

    croak "Invalid array size, signature @{[$self->fixed_length]}, data: $length"
        if $self->fixed_length && $length > $self->fixed_length;

    my $offset = $self->get_initial_offset();

    for my $instance ($self->instances->@*) {
        $self->push_static($self->encode_offset($offset))
            if $instance->is_dynamic;

        $self->push_dynamic($instance->encode);
        $offset += scalar $instance->encode()->@*;
    }

    return $self->encoded;
}

sub decode {
    my $self = shift;
    my @data = $self->data->@*;

    my $size = $self->fixed_length // shift $self->data->@*;
    push $self->instances->@*, Blockchain::Contract::Solidity::ABI::Type::new_type(signature => $self->remove_parent) for 0 .. $size - 1;

    return $self->read_stack_set_data;
}

sub remove_parent {
    my $self = shift;
    $self->signature =~ /(\[(\d+)?\]$)/;
    return substr $self->signature, 0, length($self->signature) - length($1 // '');
}

sub fixed_length {
    my $self = shift;
    if ($self->signature =~ /\[(\d+)?\]$/) {
        return $1;
    }
    return undef;
}

sub static_size {
    my $self = shift;
    return 1 if $self->is_dynamic;

    my $size = $self->fixed_length;

    my $instance_size = 1;
    for my $instance ($self->instances->@*) {
        $instance_size += $instance->static_size;
    }

    return $size * $instance_size;
}

1;

