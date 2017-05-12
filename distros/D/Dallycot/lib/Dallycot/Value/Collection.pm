package Dallycot::Value::Collection;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Base class for streams, vectors, sets, etc.

use strict;
use warnings;

use utf8;
use parent 'Dallycot::Value::Any';

use Promises qw(deferred);

use Scalar::Util qw(blessed);

sub value { }

sub is_defined { return 1 }

sub calculate_length {
  my ( $self, $engine ) = @_;

  return Dallycot::Value::Numeric->new( Math::BigRat->binf() );
}

sub head {
  my ($self) = @_;
  my $p = deferred;
  $p->reject( "head is not defined for " . blessed($self) . "." );
  return $p->promise;
}

sub tail {
  my ($self) = @_;
  my $p = deferred;
  $p->reject( "tail is not defined for " . blessed($self) . "." );
  return $p->promise;
}

1;
