package Dallycot::Value::JSON;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Manages a memory-based JSON object

use strict;
use warnings;

use utf8;
use parent 'Dallycot::Value::Any';

use experimental qw(switch);

use Promises qw(deferred);

=head1 DESCRIPTION

A JSON value represents a collection of properties and values.

Long term, a JSON value will be a JSON-LD document that can be interpreted
as a set of triples. These triples will be stored as a triple-store.

=cut

sub new {
  my( $class, $hash ) = @_;

  $class = ref $class || $class;

  return bless [ $hash ] => $class;
}

sub calculate_length {
  my ( $self, $engine ) = @_;

  my $d = deferred;

  $d->resolve( $engine->make_numeric( $self->_object_size($self->[0]) ) );

  return $d->promise;
}

sub as_text {
  my( $self ) = @_;

  my @values;

  while(my($k, $v) = each %{$self -> [0]}) {
    push @values, "\"$k\": " . $v -> as_text;
  }

  return '{' . join(",", @values) . '}';
}

sub _object_size {
  my($self, $obj) = @_;

  my $count = keys %$obj;
  foreach my $v (values %$obj) {
    given(ref $v) {
      when('HASH') {
        $count += $self->_object_size($v);
      }
      when('ARRAY') {
        $count += @$v;
        $count += $_ for map { $self->_object_size($_) } grep { 'HASH' eq ref $_ } @$_;
      }
    }
  }
  return $count;
}

sub fetch_property {
  my ( $self, $engine, $prop ) = @_;

  my $d = deferred;

  my $value = $self->[0]->{$prop};

  given(ref $value) {
    when('HASH') {
      $d->resolve(bless [ $value ] => __PACKAGE__);
    }
    when('ARRAY') {
      $d->resolve($self->_convert_to_vector($value));
    }
    when(undef) {
      $d->resolve(Dallycot::Value::Undefined->new);
    }
    default {
      $d->resolve($value);
    }
  }

  return $d->promise;
}

sub _convert_to_vector {
  my($self, $values) = @_;

  my @converted;

  for my $v (@$values) {
    given(ref $v) {
      when('HASH') {
        push @converted, bless [ $v ] => __PACKAGE__;
      }
      when('ARRAY') {
        push @converted, $self->_convert_to_vector($v);
      }
      default {
        push @converted, $v;
      }
    }
  }

  return bless \@converted => 'Dallycot::Value::Vector';
}

1;
