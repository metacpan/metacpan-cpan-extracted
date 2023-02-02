package Blockchain::Contract::Solidity::ABI::Type;

use v5.26;
use strict;
use warnings;
no indirect;

use Carp;
use Module::Load;
use constant NOT_IMPLEMENTED => 'Method not implemented';

sub new {
    my ($class, %params) = @_;

    my $self = bless {}, $class;
    $self->{signature} = $params{signature};
    $self->{data}      = $params{data};

    $self->configure();

    return $self;
}

sub configure { }

sub encode {
    croak NOT_IMPLEMENTED;
}

sub decode {
    croak NOT_IMPLEMENTED;
}

sub static {
    return shift->{static} //= [];
}

sub push_static {
    my ($self, $data) = @_;
    push($self->static->@*, ref $data eq 'ARRAY' ? $data->@* : $data);
}

sub dynamic {
    return shift->{dynamic} //= [];
}

sub push_dynamic {
    my ($self, $data) = @_;
    push($self->dynamic->@*, ref $data eq 'ARRAY' ? $data->@* : $data);
}

sub signature {
    return shift->{signature};
}

sub data {
    return shift->{data};
}

sub fixed_length {
    my $self = shift;
    if ($self->signature =~ /[a-z](\d+)/) {
        return $1;
    }
    return undef;
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

sub encode_length {
    my ($self, $length) = @_;
    return sprintf("%064s", sprintf("%x", $length));
}

sub encode_offset {
    my ($self, $offset) = @_;
    return sprintf("%064s", sprintf("%x", $offset * 32));
}

sub encoded {
    my $self = shift;
    my @data = ($self->static->@*, $self->dynamic->@*);
    return scalar @data ? \@data : undef;
}

sub is_dynamic {
    return shift->signature =~ /(bytes|string)(?!\d+)|(\[\])/ ? 1 : 0;
}

sub new_type {
    my (%params) = @_;

    my $signature = $params{signature};

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
    my $_package = __PACKAGE__;
    my $package  = sprintf("%s::%s", $_package, $module);
    load $package;
    return $package->new(
        signature => $signature,
        data      => $params{data});
}

sub instances {
    return shift->{instances} //= [];
}

sub get_initial_offset {
    my $self   = shift;
    my $offset = 0;
    for my $param ($self->instances->@*) {
        my $encoded = $param->encode;
        if ($param->is_dynamic) {
            $offset += 1;
        } else {
            $offset += scalar $param->encoded->@*;
        }
    }

    return $offset;
}

sub static_size {
    return 1;
}

sub read_stack_set_data {
    my $self = shift;

    my @data = $self->data->@*;
    my @offsets;
    my $current_offset = 0;

    # Since at this point we don't information about the chunks of data it is_dynamic
    # needed to get all the offsets in the static header, so the dynamic values can
    # be retrieved based in between the current and the next offsets
    for my $instance ($self->instances->@*) {
        if ($instance->is_dynamic) {
            push @offsets, hex($data[$current_offset]) / 32;
        }

        my $size = 1;
        $size = $instance->static_size unless $instance->is_dynamic;
        $current_offset += $size;
    }

    $current_offset = 0;
    my %response;
    # Dynamic data must to be set first since the full_size method
    # will need to use the data offset related to the size of the item
    for (my $i = 0; $i < $self->instances->@*; $i++) {
        my $instance = $self->instances->[$i];
        next unless $instance->is_dynamic;
        my $offset_start = shift @offsets;
        my $offset_end   = $offsets[0] // scalar @data - 1;
        my @range        = @data[$offset_start .. $offset_end];
        $instance->{data} = \@range;
        $current_offset += scalar @range;
        $response{$i} = $instance->decode();
    }

    $current_offset = 0;

    for (my $i = 0; $i < $self->instances->@*; $i++) {
        my $instance = $self->instances->[$i];

        if ($instance->is_dynamic) {
            $current_offset++;
            next;
        }

        my $size = 1;
        $size = $instance->static_size unless $instance->is_dynamic;
        my @range = @data[$current_offset .. $current_offset + $size - 1];
        $instance->{data} = \@range;
        $current_offset += $size;

        $response{$i} = $instance->decode();
    }

    my @array_response;
    # the given order of type signatures needs to be strict followed
    push(@array_response, $response{$_}) for 0 .. scalar $self->instances->@* - 1;
    return \@array_response;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Blockchain::Contract::Solidity::ABI::Type - Interface for solidity variable types

=head1 SYNOPSIS

Allows you to define and instantiate a solidity variable type:

    my $type = Blockchain::Contract::Solidity::ABI::Type::new_type(
        signature => $signature,
        data      => $value
    );

    $type->encode();
    ...

In most cases you don't want to use this directly, use instead:

=over 4

=item * B<Encoder>: L<Blockchain::Contract::Solidity::ABI::Encoder>

=item * B<Decoder>: L<Blockchain::Contract::Solidity::ABI::Decoder>

=back

=head1 METHODS

=head2 new_type

Create a new L<Blockchain::Contract::Solidity::ABI::Type> instance based
in the given signature.

Usage:

    new_type(signature => signature, data => value) -> L<Blockchain::Contract::Solidity::ABI::Type::*>

=over 4

=item * C<%params> signature and data key values

=back

Returns an new instance of one of the sub modules for L<Blockchain::Contract::Solidity::ABI::Type>

=head1 AUTHOR

Reginaldo Costa, C<< <refeco at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/refeco/perl-ABI>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Blockchain::Contract::Solidity::ABI::Type

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by Reginaldo Costa.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

