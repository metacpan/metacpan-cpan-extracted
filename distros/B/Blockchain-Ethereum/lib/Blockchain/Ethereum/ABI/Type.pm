package Blockchain::Ethereum::ABI::Type;

use v5.26;
use strict;
use warnings;

# ABSTRACT: Type interface
our $AUTHORITY = 'cpan:REFECO';    # AUTHORITY
our $VERSION   = '0.019';          # VERSION

use Carp;
use Module::Load;

sub new {
    my ($class, %params) = @_;

    my $signature = $params{signature};
    my $data      = $params{data};

    my $self = {
        signature => $signature,
        data      => $data,
        static    => [],
        dynamic   => [],
        instances => [],
    };

    if ($signature) {
        my $module;
        if ($signature =~ /\[(\d+)?\]$/gm) {
            $module = "Array";
        } elsif ($signature =~ /^\(.*\)/) {
            $module = "Tuple";
        } elsif ($signature =~ /^address$/) {
            $module = "Address";
        } elsif ($signature =~ /^(u)?(int|bool)(\d+)?$/) {
            $module = "Int";
        } elsif ($signature =~ /^(?:bytes)(\d+)?$/) {
            $module = "Bytes";
        } elsif ($signature =~ /^string$/) {
            $module = "String";
        } else {
            croak "Module not found for the given parameter signature $signature";
        }

        # this is just to avoid `use module` for every new type included
        my $package = "Blockchain::Ethereum::ABI::Type::$module";
        load $package;

        $self = bless $self, $package;
        $self->_configure;
    } else {
        $self = bless $self, $class;
    }

    return $self;
}

sub _configure {
    croak 'method _configure not implemented';
}

sub encode {
    croak 'method encode not implemented';
}

sub decode {
    croak 'method decode not implemented';
}

sub _push_static {
    my ($self, $data) = @_;

    push($self->{static}->@*, ref $data eq 'ARRAY' ? $data->@* : $data);
}

sub _push_dynamic {
    my ($self, $data) = @_;

    push($self->{dynamic}->@*, ref $data eq 'ARRAY' ? $data->@* : $data);
}

sub pad_right {
    my ($self, $data) = @_;

    my @chunks;
    push(@chunks, $_ . '0' x (64 - length $_)) for unpack("(A64)*", $data);

    return \@chunks;
}

sub pad_left {
    my ($self, $data) = @_;

    my @chunks;
    push(@chunks, sprintf("%064s", $_)) for unpack("(A64)*", $data);

    return \@chunks;

}

sub _encode_length {
    my ($self, $length) = @_;

    return sprintf("%064s", sprintf("%x", $length));
}

sub _encode_offset {
    my ($self, $offset) = @_;

    return sprintf("%064s", sprintf("%x", $offset * 32));
}

sub _encoded {
    my ($self, $offset) = @_;

    my @data = ($self->{static}->@*, $self->{dynamic}->@*);
    return scalar @data ? \@data : undef;
}

sub is_dynamic {
    my $self = shift;

    return $self->{signature} =~ /(bytes|string)(?!\d+)|(\[\])/ ? 1 : 0;
}

# get the first index where data is set to the encoded value
# skipping the prefixed indexes
sub _get_initial_offset {
    my $self = shift;

    my $offset = 0;
    for my $param ($self->{instances}->@*) {
        my $encoded = $param->encode;
        if ($param->is_dynamic) {
            $offset += 1;
        } else {
            $offset += scalar $param->_encoded->@*;
        }
    }

    return $offset;
}

sub fixed_length {
    my $self = shift;

    if ($self->{signature} =~ /[a-z](\d+)/) {
        return $1;
    }
    return undef;
}

sub _static_size {
    return 1;
}

# read the data at the encoded stack
sub _read_stack_set_data {
    my $self = shift;

    my @data = $self->{data}->@*;
    my @offsets;
    my $current_offset = 0;

    # Since at this point we don't information about the chunks of data it is_dynamic
    # needed to get all the offsets in the static header, so the dynamic values can
    # be retrieved based in between the current and the next offsets
    for my $instance ($self->{instances}->@*) {
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
    for (my $i = 0; $i < $self->{instances}->@*; $i++) {
        my $instance = $self->{instances}->[$i];
        next unless $instance->is_dynamic;
        my $offset_start = shift @offsets;
        my $offset_end   = $offsets[0] // scalar @data - 1;
        my @range        = @data[$offset_start .. $offset_end];
        $instance->{data} = \@range;
        $current_offset += scalar @range;
        $response{$i} = $instance->decode();
    }

    $current_offset = 0;

    for (my $i = 0; $i < $self->{instances}->@*; $i++) {
        my $instance = $self->{instances}->[$i];

        if ($instance->is_dynamic) {
            $current_offset++;
            next;
        }

        my $size = 1;
        $size = $instance->_static_size unless $instance->is_dynamic;
        my @range = @data[$current_offset .. $current_offset + $size - 1];
        $instance->{data} = \@range;
        $current_offset += $size;

        $response{$i} = $instance->decode();
    }

    my @array_response;
    # the given order of type signatures needs to be strict followed
    push(@array_response, $response{$_}) for 0 .. scalar $self->{instances}->@* - 1;
    return \@array_response;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Blockchain::Ethereum::ABI::Type - Type interface

=head1 VERSION

version 0.019

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

=head1 METHODS

=head2 pad_right

Pads the given data to right 32 bytes with zeros

=over 4

=item * C<$data> data to be padded

=back

Returns the padded string

=head2 pad_left

Pads the given data to left 32 bytes with zeros

=over 4

=item * C<$data> data to be padded

=back

=head2 is_dynamic

Checks if the type signature is dynamic

=over 4

=back

Returns 1 for dynamic and 0 for static

=head2 fixed_length

Check if that is a length specified for the given signature

=over 4

=back

Integer length or undef in case of no length specified

=head1 AUTHOR

REFECO <refeco@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by REFECO.

This is free software, licensed under:

  The MIT (X11) License

=cut
