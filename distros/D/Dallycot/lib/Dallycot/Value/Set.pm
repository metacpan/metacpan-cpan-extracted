package Dallycot::Value::Set;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: An in-memory set of unique values

use strict;
use warnings;

# RDF Bag

use utf8;
use parent 'Dallycot::Value::Collection';

use Promises qw(deferred collect);

use Scalar::Util qw(blessed);

sub new {
  my ( $class, @values ) = @_;

  @values = values %{ +{ map { $_->id => $_ } @values } };

  return bless \@values => __PACKAGE__;
}

sub id {
  my ($self) = @_;

  return "<|" . join("|", map { $_->id } @$self ) . "|>";
}

sub as_text {
  my ($self) = @_;

  return "<|" . join( " | ", map { $_->as_text } @$self ) . "|>";
}

sub is_defined { return 1 }

sub is_empty {
  my ($self) = @_;

  return @$self != 0;
}

sub calculate_length {
  my ( $self, $engine ) = @_;

  return Dallycot::Value::Numeric->new( scalar @$self );
}

sub head {
  my ( $self, $engine ) = @_;

  my $d = deferred;

  if (@$self) {
    $d->resolve( $self->[0] );
  }
  else {
    $d->resolve( $engine->UNDEFINED );
  }

  return $d->promise;
}

sub tail {
  my ( $self, $engine ) = @_;

  my $d = deferred;

  if (@$self) {
    $d->resolve( bless [ @$self[ 1 .. $#$self ] ] => __PACKAGE__ );
  }
  else {
    $d->resolve( Dallycot::Value::EmptyStream->new() );
  }

  return $d->promise;
}

sub apply_map {
  my ( $self, $engine, $transform ) = @_;

  return collect( map { $transform->apply( $engine, {}, $_ ) } @$self )->then(
    sub {
      return $self->new( map {@$_} @_ );
    }
  );
}

sub apply_filter {
  my ( $self, $engine, $filter ) = @_;

  return collect( map { $filter->apply( $engine, {}, $_ ) } @$self )->then(
    sub {
      my (@hits) = map { $_->value } map {@$_} @_;
      my @values;
      for ( my $i = 0; $i < @hits; $i++ ) {
        push @values, $self->[$i] if $hits[$i];
      }
      bless \@values => __PACKAGE__;
    }
  );
}

sub prepend {
  my ( $self, @things ) = @_;

  return $self->new( @things, @$self );
}

sub union {
  my ( $self, $other ) = @_;

  return Dallycot::Processor->UNDEFINED unless $other->isa(__PACKAGE__);

  return $self->new( @{$self}, @{$other} );
}

sub intersection {
  my ( $self, $other ) = @_;

  return Dallycot::Processor->UNDEFINED unless $other->isa(__PACKAGE__);

  my $own_values = { map { $_->id => $_ } @$self };

  my $other_values = { map { $_->id => $_ } @$other };

  my @new_values;

  @new_values = @{$own_values}{ grep { $other_values->{$_} } keys %$own_values };

  return bless \@new_values => __PACKAGE__;
}

sub fetch_property {
  my ( $self, $engine, $prop ) = @_;

  return collect( map { $_->fetch_property( $engine, $prop ) } @$self )->then(
    sub {
      my (@values) = map {@$_} @_;

      return grep { blessed($_) && !$_->isa('Dallycot::Value::Undefined') } @values;
    }
  );
}

1;
