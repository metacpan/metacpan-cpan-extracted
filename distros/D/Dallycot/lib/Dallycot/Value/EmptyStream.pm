package Dallycot::Value::EmptyStream;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: A stream with no values

use strict;
use warnings;

use utf8;
use parent 'Dallycot::Value::Collection';

use Promises qw(deferred);

our $INSTANCE;

sub new {
  return $INSTANCE ||= bless [] => __PACKAGE__;
}

sub to_rdf {
  my($self, $model) = @_;

  return $model -> add_list;
}

sub prepend {
  my ( $self, @things ) = @_;

  my $stream = Dallycot::Value::Stream->new( shift @things );
  foreach my $thing (@things) {
    $stream = Dallycot::Value::Stream->new( $thing, $stream );
  }
  return $stream;
}

sub as_text { return "[ ]" }

sub is_empty { return 1 }

sub is_defined { return 1 }

sub _type { return 'Stream' }

sub calculate_length {
  my ( $self, $engine ) = @_;

  return $engine->ZERO;
}

sub calculate_reverse {
  my ( $self, $engine ) = @_;

  my $d = deferred;

  $d->resolve($self);

  return $d->promise;
}

sub apply_map {
  my ( $self, $engine, $transform ) = @_;

  return $self;
}

sub apply_filter {
  my ( $self, $engine, $transform ) = @_;

  return $self;
}

sub value_at {
  my $p = deferred;

  $p->resolve( Dallycot::Value::Undefined->new );

  return $p->promise;
}

sub head {
  my $p = deferred;

  $p->resolve( Dallycot::Value::Undefined->new );

  return $p->promise;
}

sub tail {
  my ($self) = @_;

  my $p = deferred;

  $p->resolve($self);

  return $p->promise;
}

1;
