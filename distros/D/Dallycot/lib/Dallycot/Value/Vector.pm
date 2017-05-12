package Dallycot::Value::Vector;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: A finite length, in-memory ordered set of values

use strict;
use warnings;

use utf8;
use parent 'Dallycot::Value::Collection';

use Promises qw(deferred collect);

sub new {
  my ( $class, @values ) = @_;
  $class = ref $class || $class;
  return bless \@values => $class;
}

sub values {
  @{$_[0]};
}

sub is_empty {
  my ($self) = @_;

  return @$self == 0;
}

sub to_rdf {
  my($self, $model) = @_;

  $model -> list(map { $_ -> to_rdf($model) } @$self);
}

sub is_defined { return 1 }

sub as_text {
  my ($self) = @_;

  return
      "< "
    . join( ", ", map { defined($_) ? ( ( $_ eq $self ) ? '(self)' : $_->as_text ) : '(undef)' } @$self )
    . " >";
}

sub prepend {
  my ( $self, @things ) = @_;

  return bless [ @things, @$self ] => __PACKAGE__;
}

sub calculate_length {
  my ( $self, $engine ) = @_;

  return Dallycot::Value::Numeric->new( scalar @$self );
}

sub calculate_reverse {
  my ( $self, $engine ) = @_;

  my $d = deferred;

  $d->resolve( $self->new( reverse @$self ) );

  return $d->promise;
}

sub apply_map {
  my ( $self, $engine, $transform ) = @_;

  return collect( map { $transform->apply( $engine, {}, $_ ) } @$self )->then(
    sub {
      my @values = map {@$_} @_;
      bless \@values => __PACKAGE__;
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
      return bless \@values => __PACKAGE__;
    }
  );
}

sub value_at {
  my ( $self, $engine, $index ) = @_;

  my $d = deferred;

  if ( $index > @$self || $index < 1 ) {
    $d->resolve( $engine->UNDEFINED );
  }
  else {
    $d->resolve( $self->[ $index - 1 ] );
  }

  return $d->promise;
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
    $d->resolve( Dallycot::Value::EmptyStream->new );
  }

  return $d->promise;
}

1;
