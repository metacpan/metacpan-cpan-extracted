package Dallycot::Value::Stream;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: A linked list of values with a possible generator

use strict;
use warnings;

# RDF List
use utf8;
use Readonly;

Readonly my $HEAD         => 0;
Readonly my $TAIL         => 1;
Readonly my $TAIL_PROMISE => 2;

use parent 'Dallycot::Value::Collection';

use experimental qw(switch);

use Promises qw(deferred);

sub new {
  my ( $class, $head, $tail, $promise ) = @_;
  $class = ref $class || $class;
  return bless [ $head, $tail, $promise ] => $class;
}

sub is_defined { return 1 }

sub is_empty {return}

sub to_rdf {
  my($self, $model) = @_;

  my @things;
  my $root = $self;
  push @things, $root -> [0]->to_rdf($model);
  while($root -> [1]) {
    $root = $root->[1];
    push @things, $root->[0]->to_rdf($model);
  }
  if($root -> [2]) {
    return $model -> list_with_promise(@things, $root->[2]);
  }
  else {
    return $model -> list(@things);
  }
}

sub prepend {
  my ( $self, @things ) = @_;

  my $stream = $self;

  foreach my $thing (@things) {
    $stream = __PACKAGE__->new( $thing, $stream );
  }
  return $stream;
}

sub as_text {
  my ($self) = @_;

  my $text  = "[ ";
  my $point = $self;
  $text .= $point->[$HEAD]->as_text;
  while ( defined $point->[$TAIL] ) {
    $point = $point->[$TAIL];
    if ( defined $point->[$HEAD] ) {
      $text .= ", ";
      $text .= $point->[$HEAD]->as_text;
    }
  }
  if ( defined $point->[$TAIL_PROMISE] ) {
    $text .= ", ...";
  }
  return $text . " ]";
}

sub calculate_length {
  my ( $self, $engine ) = @_;

  my $d = deferred;

  my $ptr = $self;

  my $count = 1;

  while ( $ptr->[$TAIL] ) {
    $count++;
    $ptr = $ptr->[$TAIL];
  }

  if ( $ptr->[$TAIL_PROMISE] ) {
    $d->resolve( Dallycot::Value::Numeric->new( Math::BigRat->binf() ) );
  }
  else {
    $d->resolve( Dallycot::Value::Numeric->new($count) );
  }

  return $d->promise;
}

sub _resolve_tail_promise {
  my ( $self, $engine ) = @_;

  return $self->[$TAIL_PROMISE]->apply( $engine, {} )->then(
    sub {
      my ($list_tail) = @_;
      given ( ref $list_tail ) {
        when (__PACKAGE__) {
          $self->[$TAIL]         = $list_tail;
          $self->[$TAIL_PROMISE] = undef;
        }
        when ('Dallycot::Value::Vector') {

          # convert finite vector into linked list
          my @values = @$list_tail;
          my $point  = $self;
          while (@values) {
            $point->[$TAIL] = $self->new( shift @values );
            $point = $point->[$TAIL];
          }
        }
        default {
          $self->[$TAIL]         = $list_tail;
          $self->[$TAIL_PROMISE] = undef;
        }
      }
    }
  );
}

sub apply_map {
  my ( $self, $engine, $transform ) = @_;

  return $engine->make_map($transform)->then(
    sub {
      my ($map_t) = @_;

      $map_t->apply( $engine, {}, $self );
    }
  );
}

sub apply_filter {
  my ( $self, $engine, $filter ) = @_;

  return $engine->make_filter($filter)->then(
    sub {
      my ($filter_t) = @_;

      $filter_t->apply( $engine, {}, $self );
    }
  );
}

sub drop {
  my ( $self, $engine ) = @_;

  return;
}

sub value_at {
  my ( $self, $engine, $index ) = @_;

  if ( $index == 1 ) {
    return $self->head($engine);
  }

  my $d = deferred;

  if ( $index < 1 ) {
    $d->resolve( $engine->UNDEFINED );
  }
  else {
    # we want to keep resolving tails until we get somewhere
    $self->_walk_tail( $engine, $d, $index - 1 );
  }

  return $d->promise;
}

sub _walk_tail {
  my ( $self, $engine, $d, $count ) = @_;

  if ( $count > 0 ) {
    $self->tail($engine)->done(
      sub {
        my ($tail) = @_;
        $tail->_walk_tail( $engine, $d, $count - 1 );
      },
      sub {
        $d->reject(@_);
      }
    );
  }
  else {
    $self->head($engine)->done(
      sub {
        $d -> resolve(@_);
      },
      sub {
        $d -> reject(@_);
      }
    );
  }
}

sub head {
  my ( $self, $engine ) = @_;

  my $p = deferred;

  if ( defined $self->[$HEAD] ) {
    $p->resolve( $self->[0] );
  }
  else {
    $p->resolve( bless [] => 'Dallycot::Value::Undefined' );
  }

  return $p->promise;
}

sub tail {
  my ( $self, $engine ) = @_;

  my $p = deferred;

  if ( defined $self->[$TAIL] ) {
    $p->resolve( $self->[$TAIL] );
  }
  elsif ( defined $self->[$TAIL_PROMISE] ) {
    $self->_resolve_tail_promise($engine)->done(
      sub {
        if ( defined $self->[$TAIL] ) {
          $p->resolve( $self->[$TAIL] );
        }
        else {
          $p->reject('The tail operator expects a stream-like object.');
        }
      },
      sub {
        $p->reject(@_);
      }
    );
  }
  else {
    $p->resolve( bless [] => 'Dallycot::Value::EmptyStream' );
  }

  return $p->promise;
}

1;
