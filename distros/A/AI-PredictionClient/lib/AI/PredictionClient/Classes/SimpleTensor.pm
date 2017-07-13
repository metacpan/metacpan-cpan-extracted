use strict;
use warnings;
package AI::PredictionClient::Classes::SimpleTensor;
$AI::PredictionClient::Classes::SimpleTensor::VERSION = '0.01';

# ABSTRACT: A simplified version of the TensorFlow Tensor proto.

use 5.010;
use MIME::Base64 qw( encode_base64 decode_base64 );
use Moo;

around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;

  if (@_ == 1) {
    return $class->$orig(tensor_ds => $_[0]);
  } else {
    return $class->$orig(@_);
  }
};

has tensor_ds => (
  is      => 'ro',
  default => sub {
    {
      dtype       => "DT_STRING",
      tensorShape => { dim => [ { size => 1 } ] },
      stringVal   => [""] };
  },
);

sub shape {
  my ($self, $shape_aref) = @_;

  my $tensor_shape_ref = \$self->tensor_ds->{"tensorShape"}->{"dim"};
  $$tensor_shape_ref = $shape_aref if $shape_aref;

  return $$tensor_shape_ref;
}

sub dtype {
  my ($self, $dtype) = @_;
  my $tensor_dtype_ref = \$self->tensor_ds->{"dtype"};
  $$tensor_dtype_ref = $dtype if $dtype;

  return $$tensor_dtype_ref;
}

has use_base64_strings => (
  is      => 'rw',
  default => 0,
);

has dtype_values => (
  is      => 'ro',
  default => sub {
    {
      DT_HALF       => 'halfVal',
      DT_FLOAT      => 'floatVal',
      DT_DOUBLE     => 'doubleVal',
      DT_INT16      => 'intVal',
      DT_INT8       => 'intVal',
      DT_UINT8      => 'intVal',
      DT_STRING     => 'stringVal',
      DT_COMPLEX64  => 'scomplexVal',
      DT_INT64      => 'int64Val',
      DT_BOOL       => 'boolVal',
      DT_COMPLEX128 => 'dcomplexVal',
      DT_RESOURCE   => 'resourceHandleVal'
    };
  });

sub value {
  my ($self, $value_aref) = @_;

  my $decoded_aref;

  my $value_type       = $self->dtype_values->{ $self->dtype };
  my $tensor_value_ref = \$self->tensor_ds->{$value_type};

  if ($value_aref) {

    if ($self->dtype eq 'DT_STRING' && !$self->use_base64_strings) {
      @$$tensor_value_ref
        = map { encode_base64(ref($_) ? $$_ : $_, '') } @$value_aref;
    } else {
      $$tensor_value_ref = $value_aref;
      delete $self->tensor_ds->{'stringVal'}
        ;  # When not a string delete convenience placeholder.
    }

    return [];

  } else {

    if ($self->dtype eq 'DT_STRING' && !$self->use_base64_strings) {
      @$decoded_aref = map { decode_base64($_) } @$$tensor_value_ref;
      return $decoded_aref;
    } else {
      return $$tensor_value_ref;
    }

  }
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AI::PredictionClient::Classes::SimpleTensor - A simplified version of the TensorFlow Tensor proto.

=head1 VERSION

version 0.01

=head1 AUTHOR

Tom Stall <stall@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Tom Stall.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
