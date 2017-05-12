package Dallycot::Value::OpenRange;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: An open range (semi-infinite) of integers

use strict;
use warnings;

# No RDF equivalent - continuous list generation of items

use utf8;
use parent 'Dallycot::Value::Collection';

use Promises qw(deferred);

sub _type { return 'Range' }

sub as_text {
  my ($self) = @_;

  return $self->[0]->as_text . "..";
}

sub is_empty {return}

sub calculate_length {
  my ( $self, $engine ) = @_;

  return Dallycot::Value::Numeric->new( Math::BigRat->binf() );
}

sub head {
  my ($self) = @_;

  my $d = deferred;

  $d->resolve( $self->[0] );

  return $d->promise;
}

sub tail {
  my ($self) = @_;

  return $self->[0]->successor->then(
    sub {
      my ($next) = @_;

      bless [$next] => __PACKAGE__;
    }
  );
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

sub apply_map {
  my ( $self, $engine, $transform ) = @_;

  return $engine->make_map($transform)->then(
    sub {
      my ($map_t) = @_;

      return $map_t->apply( $engine, {}, $self );
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

1;
