package Dallycot::AST::Fetch;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Find the value associated with an identifier

use strict;
use warnings;

use utf8;
use parent 'Dallycot::AST';

use Dallycot::Util qw(maybe_promise);

use Promises       qw(deferred);
use Scalar::Util   qw(blessed);

sub new {
  my ( $class, $identifier ) = @_;

  $class = ref $class || $class;

  return bless [$identifier] => $class;
}

sub to_rdf {
  my($self, $model) = @_;

  my $label;

  if(@$self > 1) {
    # need namespace resolution
    my $uri = $model -> uri(join(":", @$self));
    return $uri if blessed $uri;
  }
  else {
    $label = $self->[0];
  }
  my $val = $model -> fetch_symbol($label);

  return $val if blessed $val;

  my $bnode = $model -> bnode;
  $model -> add_type($bnode, 'loc:BindingReference');
  $model -> add_label($bnode, $label);
  return $bnode;
}

sub identifiers {
  my ($self) = @_;

  if ( @{$self} == 1 ) {
    return $self->[0];
  }
  else {
    return [ @{$self} ];
  }
}

sub to_string {
  my ($self) = @_;

  return $self->[0];
}

sub execute {
  my ( $self, $engine ) = @_;

  my $registry = Dallycot::Registry->instance;
  if ( @$self > 1 ) {
    if ( $engine->has_namespace( $self->[0] ) ) {
      my $ns = $engine->get_namespace( $self->[0] );
      if ( $registry->has_namespace($ns) ) {
        if ( $registry->has_assignment( $ns, $self->[1] ) ) {
          return maybe_promise( $registry->get_assignment( $ns, $self->[1] ) );
        }
        else {
          my $d = deferred;
          $d->reject( join( ":", @$self ) . " is undefined." );
          return $d->promise;
        }
      }
      else {
        my $d = deferred;
        $d->reject("The namespace \"$ns\" is unregistered.");
        return $d->promise;
      }
    }
    else {
      my $d = deferred;
      $d->reject("The namespace prefix \"@{[$self->[0]]}\" is undefined.");
      return $d->promise;
    }
  }
  elsif ( $engine->has_assignment( $self->[0] ) ) {
    return maybe_promise( $engine->get_assignment( $self->[0] ) );
  }
  elsif ( $registry->has_assignment( $engine->get_namespace_search_path, $self->[0] ) ) {
    return maybe_promise( $registry->get_assignment( $engine->get_namespace_search_path, $self->[0] ) );
  }
  else {
    my $d = deferred;
    $d->reject( $self->[0] . " is undefined." );
    return $d->promise;
  }
}

1;
