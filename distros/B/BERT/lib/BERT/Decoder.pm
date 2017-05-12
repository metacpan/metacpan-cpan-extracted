package BERT::Decoder;
use strict;
use warnings;

use 5.008;

use Carp 'croak';
use BERT::Constants;
use BERT::Types;

sub new {
    my $class = shift;
    return bless { }, $class;
}

sub decode {
    my ($self, $bert) = @_;

    (my $magic, $bert) = unpack('Ca*', $bert);

    croak sprintf('Bad magic number. Expected %d found %d', MAGIC_NUMBER, $magic)
        unless MAGIC_NUMBER == $magic;

    return $self->extract_any($bert);
}

sub extract_any {
    my ($self, $bert) = @_;

    (my $value, $bert) = $self->read_any($bert);

    $value = $self->extract_complex_type($value)
        if ref $value eq 'BERT::Tuple';

    return [ $value, $self->extract_any($bert) ] if $bert;
    return $value;
}

sub extract_complex_type {
    my ($self, $tuple) = @_;

    my @array = @{ $tuple->value };
    return $tuple unless $array[0] eq 'bert';

    if ($array[1] eq 'nil') {
        return undef;
    } elsif ($array[1] eq 'true') {
        return BERT::Boolean->true;
    } elsif ($array[1] eq 'false') {
        return BERT::Boolean->false;
    } elsif ($array[1] eq 'dict') {
        my @dict = map(@{ $_->value }, @{ $array[2] });

        # Someday I should add an option to allow hashref to be returned instead
        return BERT::Dict->new(\@dict);
    } elsif ($array[1] eq 'time') {
        my ($megasec, $sec, $microsec) = @array[2, 3, 4];
        return  BERT::Time->new($megasec * 1_000_000 + $sec, $microsec);
    } elsif ($array[1] eq 'regex') {
        my ($source, $options) = @array[2, 3];
        my $opt = '';
        for (@{ $options }) {
            if    ($_ eq 'caseless')  { $opt .= 'i' }
            elsif ($_ eq 'dotall')    { $opt .= 's' }
            elsif ($_ eq 'extended')  { $opt .= 'x' }
            elsif ($_ eq 'multiline') { $opt .= 'm' }
        }
        return eval "qr/$source/$opt";
    } else {
        croak "Unknown complex type $array[1]";
    }
}

sub read_any {
    my ($self, $bert) = @_;
    my $value;

    (my $type, $bert) = unpack('Ca*', $bert);

    if    (SMALL_INTEGER_EXT == $type) { return $self->read_small_integer($bert) }
    elsif (INTEGER_EXT == $type)       { return $self->read_integer($bert)       }
    elsif (FLOAT_EXT == $type)         { return $self->read_float($bert)         }
    elsif (ATOM_EXT == $type)          { return $self->read_atom($bert)          } 
    elsif (SMALL_TUPLE_EXT == $type)   { return $self->read_small_tuple($bert)   }
    elsif (LARGE_TUPLE_EXT == $type)   { return $self->read_large_tuple($bert)   }
    elsif (NIL_EXT == $type)           { return $self->read_nil($bert)           }
    elsif (STRING_EXT == $type)        { return $self->read_string($bert)        } 
    elsif (LIST_EXT == $type)          { return $self->read_list($bert)          } 
    elsif (BINARY_EXT == $type)        { return $self->read_binary($bert)        } 
    elsif (SMALL_BIG_EXT == $type)     { return $self->read_small_big($bert)     }
    elsif (LARGE_BIG_EXT == $type)     { return $self->read_large_big($bert)     }
    else                               { croak "Unknown type $type"              }
}

sub read_small_integer {
    my ($self, $bert) = @_;
    (my $value, $bert) = unpack('Ca*', $bert);
    return ($value, $bert);
}

sub read_integer {
    my ($self, $bert) = @_;

    # This should have been unpack('l>a*',...) only and not have extra unpack('l',...)
    # but I don't want to require perl >= v5.10
    (my $value, $bert) = unpack('Na*', $bert);
    $value = unpack('l', pack('L', $value));
    return ($value, $bert);
}

sub read_float {
    my ($self, $bert) = @_;
    (my $value, $bert) = unpack('Z31a*', $bert);
    return ($value, $bert);
}

sub read_atom {
    my ($self, $bert) = @_;
    (my $len, $bert) = unpack('na*', $bert);
    (my $value, $bert) = unpack("a$len a*", $bert);
    $value = BERT::Atom->new($value);
    return ($value, $bert);
}

sub read_small_tuple {
    my ($self, $bert) = @_;
    (my $len, $bert) = unpack('Ca*', $bert);
    (my $value, $bert) = $self->read_array($bert, $len, []);
    $value = BERT::Tuple->new($value);
    return ($value, $bert);
}

sub read_large_tuple {
    my ($self, $bert) = @_;
    (my $len, $bert) = unpack('Na*', $bert);
    (my $value, $bert) = $self->read_array($bert, $len, []);
    $value = BERT::Tuple->new($value);
    return ($value, $bert);
}

sub read_nil {
    my ($self, $bert) = @_;
    my $value = [];
    return ($value, $bert);
}

sub read_string {
    my ($self, $bert) = @_;
    (my $len, $bert) = unpack('na*', $bert);
    my @values = unpack("C$len a*", $bert);
    $bert = pop @values;
    my $value = \@values;
    return ($value, $bert);
}

sub read_list {
    my ($self, $bert) = @_;
    (my $len, $bert) = unpack('Na*', $bert);
    (my $value, $bert) = $self->read_array($bert, $len, []);
    (my $type, $bert) = unpack('Ca*', $bert);
    croak 'Lists with non NIL tails are not supported' 
        unless NIL_EXT == $type;
    return ($value, $bert);
}

sub read_binary {
    my ($self, $bert) = @_;
    (my $len, $bert) = unpack('Na*', $bert);
    (my $value, $bert) = unpack("a$len a*", $bert);
    return ($value, $bert);
}

sub read_small_big {
    my ($self, $bert) = @_;
    (my $len, $bert) = unpack('Ca*', $bert);
    (my $value, $bert) = $self->read_bigint($bert, $len);
    return ($value, $bert);
}

sub read_large_big {
    my ($self, $bert) = @_;
    (my $len, $bert) = unpack('Na*', $bert);
    (my $value, $bert) = $self->read_bigint($bert, $len);
    return ($value, $bert);
}

sub read_bigint {
    my $self = shift;
    my ($bert, $len) = @_;

    my($sign, @values)  = unpack("CC$len a*", $bert);
    $bert = pop @values;

    require Math::BigInt;
    my $i = Math::BigInt->new(0);
    my $value = 0;

    foreach my $item (@values) {
        $value += $item * 256 ** $i++;
    }

    $value->bneg() if $sign != 0;

    return ($value, $bert);
}

sub read_array {
    my $self = shift;
    my ($bert, $len, $array) = @_;

    if ($len > 0) {
        (my $value, $bert) = $self->read_any($bert); 
        return $self->read_array($bert, $len - 1, [@{ $array }, $value]);
    } else {
        return ($array, $bert);
    }
}

1;

__END__

=head1 NAME

BERT::Decoder - BERT deserializer

=head1 SYNOPSIS

  use BERT::Decoder;

  my $decoder = BERT::Decoder->new;
  my $data = $decoder->decode($bert);

=head1 DESCRIPTION

This module decodes BERT binaries into Perl data structures.

See the BERT specification at L<http://bert-rpc.org/>.

=head1 METHODS

=over 4

=item $decoder = BERT::Decoder->new

Creates a new BERT::Decoder object.

=item $bert = $decoder->decode($scalar)

Returns the Perl data structure for the given BERT binary. Croaks on error.

=back

=head1 AUTHOR

Sherwin Daganato E<lt>sherwin@daganato.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<BERT> L<BERT::Atom> L<BERT::Boolean> L<BERT::Dict> L<BERT::Time> L<BERT::Tuple>

=cut
