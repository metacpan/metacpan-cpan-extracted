package BERT::Encoder;
use strict;
use warnings;

use 5.008;

use Carp 'croak';
use BERT::Constants;
use BERT::Types;

# stolen from Regexp::Common :-)
use constant {
    INT_RE   => qr/^(?:(?:[+-]?)(?:[0123456789]+))$/,
    FLOAT_RE => qr/^(?:(?i)(?:[+-]?)(?:(?=[.]?[0123456789])(?:[0123456789]*)(?:(?:[.])(?:[0123456789]{0,}))?)(?:(?:[E])(?:(?:[+-]?)(?:[0123456789]+))|))$/,
};

sub new {
    my $class = shift;
    return bless { }, $class;
}

sub encode {
    my ($self, $value) = @_;
    return pack('C', MAGIC_NUMBER) . $self->encode_any($value);
}

sub encode_any {
    my ($self, $value) = @_;

    return $self->encode_nil unless defined $value;

    my $type = ref $value;
    if    ($type eq 'ARRAY')          { return $self->encode_array($value)    } 
    elsif ($type eq 'HASH')           { return $self->encode_dict($value)     } 
    elsif ($type eq 'Regexp')         { return $self->encode_regex($value)    } 
    elsif ($type eq 'BERT::Atom')     { return $self->encode_atom($value)     } 
    elsif ($type eq 'BERT::Tuple')    { return $self->encode_tuple($value)    } 
    elsif ($type eq 'BERT::Boolean')  { return $self->encode_boolean($value)  } 
    elsif ($type eq 'BERT::Dict')     { return $self->encode_dict($value)     } 
    elsif ($type eq 'BERT::Time')     { return $self->encode_time($value)     } 
    elsif ($type eq 'Math::BigInt')   { return $self->encode_integer($value)  } 
    elsif ($type)                     { croak "Can't encode type $type"       } 

    # I didn't use B::svref_2object on this because by only looking at variables
    # in Perl can actually modify them
    if    ($value =~ INT_RE)          { return $self->encode_integer($value)  }
    elsif ($value =~ FLOAT_RE)        { return $self->encode_float($value)    } 
    else                              { return $self->encode_binary($value)   }
}

sub encode_nil {
    my ($self) = @_;
    my $perl = BERT::Tuple->new([BERT::Atom->new('bert'), BERT::Atom->new('nil')]);
    return $self->encode_any($perl);
}

sub is_erl_string {
    my ($self, $value) = @_;
   
    # Although it works I'm not sure it's the best way to test whether a
    # scalar is within the byte range
    foreach my $item (@{ $value }) {
        if ($item =~ /^\d+$/) {
            return 0 if 0 > $item or $item > 255;
        } else {
            return 0 if length $item != 1;
        }
    }
    return 1;
}

sub encode_array {
    my ($self, $value) = @_;
    my @value = @{ $value };
   
    return pack('C', NIL_EXT) unless @value;
    return $self->encode_bytelist(\@value) if $self->is_erl_string(\@value);

    my $array = $self->encode_list(\@value, []);
    return pack('CN', LIST_EXT, scalar @{ $array }) . join('', @{ $array }) . pack('C', NIL_EXT);
}

sub encode_list {
    my ($self, $value, $array) = @_;

    if (@{ $value }) {
        my $head = shift @{ $value };
        return $self->encode_list($value, [@{ $array }, $self->encode_any($head)]);
    } else {
        return $array;
    }
}

sub encode_dict {
    my ($self, $value) = @_;

    my @array;
    my @value = ref $value eq 'BERT::Dict' ? @{ $value->value } : %{ $value };
    while (my @key_value = splice(@value, 0, 2)) {
        push @array, BERT::Tuple->new(\@key_value);
    }

    my $perl = BERT::Tuple->new([BERT::Atom->new('bert'), BERT::Atom->new('dict'), \@array]);
    return $self->encode_any($perl);
}

sub encode_regex {
    my ($self, $value) = @_;

    for ($value) { s/^\(\?//; s/\)$// }
    my ($modifiers, $pattern) = split /:/, $value, 2;
    my ($on, $off) = split /-/, $modifiers;

    my @options;
    for ($on) {
        if    (/i/) { push @options, BERT::Atom->new('caseless')  }
        elsif (/s/) { push @options, BERT::Atom->new('dotall')    }
        elsif (/x/) { push @options, BERT::Atom->new('extended')  }
        elsif (/m/) { push @options, BERT::Atom->new('multiline') }
    }

    my $perl = BERT::Tuple->new([BERT::Atom->new('bert'), BERT::Atom->new('regex'), $pattern, \@options]);
    return $self->encode_any($perl);
}

sub encode_atom {
    my ($self, $value) = @_;
    return pack('Cna*', ATOM_EXT, length $value, $value);
}

sub encode_tuple {
    my ($self, $value) = @_;

    my @array = @{ $value->value };
    return pack('C*', SMALL_TUPLE_EXT, scalar @array) . join('', @{ $self->encode_list(\@array, []) }) if @array < 256;
    return pack('CN', LARGE_TUPLE_EXT, scalar @array) . join('', @{ $self->encode_list(\@array, []) });
}

sub encode_bytelist {
    my ($self, $value) = @_;
    return pack('CnC*', STRING_EXT, scalar @{ $value }, @{ $value });
}

sub encode_boolean {
    my ($self, $value) = @_;

    my $boolean = $value ? BERT::Atom->new('true') : BERT::Atom->new('false');
    my $perl = BERT::Tuple->new([BERT::Atom->new('bert'), $boolean]);
    return $self->encode_any($perl);
}

sub encode_time {
    my ($self, $value) = @_;

    use integer;
    my ($seconds, $microseconds) = $value->value;
    my $megaseconds = $seconds / 1_000_000;
    $seconds = $seconds % 1_000_000;
    my $perl = BERT::Tuple->new([BERT::Atom->new('bert'), BERT::Atom->new('time'), $megaseconds, $seconds, $microseconds]);
    return $self->encode_any($perl);
}

sub encode_integer {
    my ($self, $value) = @_;

    return pack('C2', SMALL_INTEGER_EXT, $value)
        if 0 <= $value and $value <= 255;

    # I think newer versions of erlang no longer have the 28bit limit,
    # so maybe I should add an option to extend the limit to max_int
    return pack('CN', INTEGER_EXT, $value)
        if ERL_MIN <= $value and $value <= ERL_MAX;

    my $sign = $value < 0 ? 1 : 0;
    $value = abs($value);

    my @bytes;
    while ($value > 0) {
        push @bytes, $value & 0xFF;
        $value >>= 8;
    }

    return pack('C*', SMALL_BIG_EXT, scalar @bytes, $sign, @bytes) if @bytes < 256;
    return pack('CNC*', LARGE_BIG_EXT, scalar @bytes, $sign, @bytes);
}

sub encode_float {
    my ($self, $value) = @_;
    return pack('CZ31', FLOAT_EXT, sprintf('%.20e', $value));
}

sub encode_binary {
    my ($self, $value) = @_;
    return pack('CNa*', BINARY_EXT, length $value, $value);
}

1;

__END__

=head1 NAME

BERT::Encoder - BERT serializer

=head1 SYNOPSIS

  use BERT::Encoder;

  my $encoder = BERT::Encoder->new;
  my $bert = $encoder->encode([ 1, 'foo', [ 2, [ 3, 4 ] ], 5 ]);

=head1 DESCRIPTION

This module encodes Perl data structures into BERT format.

See the BERT specification at L<http://bert-rpc.org/>.

=head1 METHODS

=over 4

=item $encoder = BERT::Encoder->new

Creates a new BERT::Encoder object.

=item $bert = $encoder->encode($scalar)

Returns the BERT representation for the given Perl data structure. Croaks on error.

=back

=head1 AUTHOR

Sherwin Daganato E<lt>sherwin@daganato.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<BERT> L<BERT::Atom> L<BERT::Boolean> L<BERT::Dict> L<BERT::Time> L<BERT::Tuple>

=cut
