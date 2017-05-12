package Dallycot::Value::ClosedRange;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: A finite range of integers

use strict;
use warnings;

# No RDF equivalent - finite list of items

use utf8;
use parent 'Dallycot::Value::Collection';

use Promises qw(deferred);

use Readonly;

Readonly my $FIRST     => 0;
Readonly my $LAST      => 1;
Readonly my $DIRECTION => 2;

sub as_text {
  my ($self) = @_;

  return $self->[$FIRST]->as_text . ".." . $self->[$LAST]->as_text;
}

sub calculate_length {
  my ( $self, $engine ) = @_;

  my $diff = $self->[$LAST]->value - $self->[$FIRST]->value;

  return Dallycot::Value::Numeric->new( $diff->babs + 1 );
}

sub is_defined { return 1 }

sub is_empty {return}

sub calculate_reverse {
  my ($self) = @_;

  my $d = deferred;

  $d->resolve( bless [ $self->[$LAST], $self->[$FIRST], -$self->[$DIRECTION] ] => __PACKAGE__ );

  return $d->promise;
}

sub _type { return 'Range' }

sub head {
  my ($self) = @_;

  my $d = deferred;

  $d->resolve( $self->[$FIRST] );

  return $d->promise;
}

sub tail {
  my ( $self, $engine ) = @_;

  return $self->[$FIRST]->is_equal( $engine, $self->[$LAST] )->then(
    sub {
      my ($f) = @_;

      if ($f) {
        return Dallycot::Value::EmptyStream->new();
      }
      else {
        my $next_p;
        if ( $self->[$DIRECTION] > 0 ) {
          $next_p = $self->[$FIRST]->successor;
        }
        else {
          $next_p = $self->[$FIRST]->predecessor;
        }
        $next_p->then(
          sub {
            my ($next) = @_;
            return bless [ $next, $self->[$LAST], $self->[$DIRECTION] ] => __PACKAGE__;
          }
        );
      }
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

      return $filter_t->apply( $engine, {}, $self );
    }
  );
}

1;
