package Dallycot::Value::URI;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: A URI value that can be dereferenced

use strict;
use warnings;

use utf8;
use parent 'Dallycot::Value::Any';

use Dallycot::Registry;
use Promises qw(deferred);
use Scalar::Util qw(blessed);
use URI;

use experimental qw(switch);

sub new {
  my ( $class, $uri ) = @_;

  $class = ref $class || $class;

  $uri = URI->new($uri)->canonical;

  return bless [$uri] => $class;
}

sub to_rdf {
  my( $self, $model ) = @_;

  return RDF::Trine::Node::Resource->new($self->[0]->as_string);
}

sub calculate_length {
  my ( $self, $engine ) = @_;

  return Dallycot::Value::Numeric->new( length $self->[0]->as_string );
}

sub value_at {
  my ( $self, $engine, $index ) = @_;

  my $d = deferred;

  if($index > length($self -> [0] -> as_string)) {
    $d -> resolve($engine -> UNDEFINED);
  }
  else {
    $d->resolve(
      bless [ substr( $self->[0]->as_string, $index - 1, 1 ), 'en' ] => 'Dallycot::Value::String' );
  }

  return $d->promise;
}

sub id {
  my ($self) = @_;

  return "<" . $self->[0]->as_string . ">";
}

sub as_text {
  my ($self) = @_;

  return $self->id;
}

sub is_lambda {
  my ($self) = @_;

  my ( $lib, $method ) = $self->_get_library_and_method;

  return unless defined $lib;
  return $lib->get_assignment($method)->then(
    sub {
      my ($def) = @_;

      return unless blessed($def);
      return 1 if $def->isa(__PACKAGE__);
      return $def->is_lambda;
    }
  );
}

sub is_defined { return 1 }

sub is_empty {return}

sub min_arity {
  my ($self) = @_;

  my ( $lib, $method ) = $self->_get_library_and_method;
  if ($lib) {
    return $lib->min_arity($method);
  }
  else {
    return 0;    # TODO: fix once we fetch remote libraries
  }
}

my $registry = Dallycot::Registry->instance;

sub _get_library_and_method {
  my ($self) = @_;

  my $uri = $self->[0]->as_string;

  my ( $namespace, $method ) = split( /#/, $uri, 2 );
  if ( !defined $method ) {
    if ( $self->[0] =~ m{^(.*/)(.+?)$}x ) {
      $namespace = $1;
      $method    = $2;
    }
    else {
      $namespace = $self->[0];
      $method    = '';
    }
  }
  else {
    $namespace .= '#';
  }

  if ( $registry->has_namespace($namespace) ) {
    return ( $registry->namespaces->{$namespace}, $method );
  }
  return;
}

sub apply {
  my ( $self, $engine, $options, @bindings ) = @_;

  my ( $lib, $method ) = $self->_get_library_and_method;

  if ($lib) {
    return $lib->apply( $method, $engine, $options, @bindings );
  }
  else {    # TODO: fetch resource and see if it's a lambda
    my $d = deferred;
    $d->reject( $self->[0] . " is not a lambda" );
    return $d->promise;
  }
}

sub resolve {
  my ( $self, $engine ) = @_;

  my $d = deferred;

  my $url = $self->[0];

  my $resolver = Dallycot::Resolver->instance;
  $resolver->get($url->as_string)->done(
    sub {
      $d->resolve(@_);
    },
    sub {
      $d->reject(@_);
    }
  );

  return $d->promise;
}

sub resolve_content {
  my ( $self, $engine ) = @_;

  my $d = deferred;

  my $url = $self->[0];

  my $resolver = Dallycot::TextResolver->instance;
  $resolver->get($url->as_string)->done(
    sub {
      $d->resolve(@_);
    },
    sub {
      $d->reject(@_);
    }
  );

  return $d->promise;
}

sub fetch_property {
  my ( $self, $engine, $prop ) = @_;

  if ( @$self < 2 ) {
    print STDERR "Getting " . ($self->[0])."\n";
    push @$self, Dallycot::Resolver->instance->get(
      "".($self -> [0])
    );
  }
 
  $self -> [1] -> then(sub {
    my($tstore) = @_;
    $tstore -> fetch_property( $engine, $prop );
  });
}

1;
