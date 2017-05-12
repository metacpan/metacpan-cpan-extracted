package Dallycot::Library;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Base for adding namespaced functions to Dallycot.

=head1 SYNOPSIS

   package MyLibrary;

   use Moose;
   extends 'Dallycot::Library';

   ns 'http://www.example.com/library#';

   define foo => << 'EOD';
     (a, b) :> ((a * b) mod (b - a))
   EOD

   define bar => sub {
     my($library, $engine, $options, @params) = @_;
     # Perl implementation
   };

=cut

use strict;
use warnings;

use utf8;
use MooseX::Singleton;

use namespace::autoclean -except => [qw/_libraries/];

use MooseX::Types::Moose qw/ArrayRef CodeRef/;
use Carp qw(croak);

use Dallycot::Parser;
use Dallycot::Processor;

use AnyEvent;

use Moose::Exporter;

use Promises qw(deferred collect);

use Module::Pluggable
  inner       => 1,
  instantiate => 'instance',
  sub_name    => '_libraries',
  search_path => 'Dallycot::Library';

our @LIBRARIES;

sub libraries {
  return @LIBRARIES if @LIBRARIES;
  return @LIBRARIES = grep { $_->isa('Dallycot::Library') } shift->_libraries;
}

my %engines;

my %namespaces;

sub ns {
  my ( $meta, $uri ) = @_;

  Dallycot::Registry->instance->register_namespace( $uri, $meta->{'package'} );

  $namespaces{ $meta->{'package'} } = $uri;

  my $engine = $engines{ $meta->{'package'} } ||= Dallycot::Processor->new;
  uses( $meta, $uri );
  return;
}

sub namespace {
  my ($class) = @_;

  $class = ref($class) || $class;

  return $namespaces{$class};
}

my %definitions;
my %uses_promises;

sub define {
  my ( $meta, $name, @options ) = @_;

  my $body    = pop @options;
  my %options = @options;

  my $definitions = $definitions{ $meta->{'package'} } ||= {};

  if ( is_CodeRef($body) ) {

    # Perl subroutine
    my $uri_promise = deferred;
    $uri_promise->resolve( $meta->{'package'}->_uri_for_name($name) );

    $definitions->{$name} = {
      %options,
      uri     => $uri_promise,
      coderef => $body
    };
  }
  else {
    # Dallycot source
    my $parser = Dallycot::Parser->new;
    my $parsed = $parser->parse($body);
    my $engine = $engines{ $meta->{'package'} } ||= Dallycot::Processor->new;

    if ( !$parsed ) {
      croak "Unable to parse Dallycot source for $name";
    }

    $uses_promises{ $meta->{'package'} }->done(
      sub {
        $definitions->{$name} = {
          %options,
          expression => $engine->with_child_scope->execute( @{$parsed} )->catch(
            sub {
              my ($err) = @_;

              print STDERR "Error defining $name: $err\n";
              croak $err;
            }
          )
        };
      }
    );
  }
  return;
}

sub uses {
  my ( $meta, @uris ) = @_;

  my $engine = $engines{ $meta->{'package'} } ||= Dallycot::Processor->new;

  my $promise = Dallycot::Registry->instance->register_used_namespaces(@uris)->then(
    sub {
      $engine->append_namespace_search_path(@uris);
    }
  );

  my $prior_promise = $uses_promises{ $meta->{'package'} };
  if ($prior_promise) {
    $prior_promise = $prior_promise->then( sub {$promise} );
  }
  else {
    $prior_promise = $promise;
  }
  $uses_promises{ $meta->{'package'} } = $prior_promise;

  return;
}

Moose::Exporter->setup_import_methods(
  with_meta => [qw(ns define uses)],
  also      => 'Moose',
);

sub init_meta {
  my ( undef, %p ) = @_;

  my $meta = MooseX::Singleton->init_meta(%p);
  $meta->superclasses(__PACKAGE__);
  return $meta;
}

sub has_assignment {
  my ( $self, $name ) = @_;

  my $def = $self->get_definition($name);
  return defined($def) && keys %$def;
}

sub get_assignment {
  my ( $self, $name ) = @_;

  my $class = ref($self) || $self;

  my $def = $self->get_definition($name);

  return unless defined $def && keys %$def;
  if ( $def->{expression} ) {
    return $def->{expression};
  }
  else {
    return $def->{uri};
  }
}

sub _uri_for_name {
  my ( $class, $name ) = @_;

  $class = ref($class) || $class;

  return Dallycot::Value::URI->new( $class->namespace . $name );
}

sub get_definition {
  my ( $class, $name ) = @_;

  return unless defined $name;

  $class = ref($class) || $class;

  my $definitions = $definitions{$class};

  if ( exists $definitions->{$name} && defined $definitions->{$name} ) {
    return $definitions->{$name};
  }
  else {
    return;
  }
}

sub get_definitions {
  my ( $class ) = @_;

  $class = ref($class) || $class;

  return keys %{$definitions{$class} || {}};
}

sub min_arity {
  my ( $self, $name ) = @_;

  my $def = $self->get_definition($name);

  if ( !$def ) {
    return 0;
  }

  if ( $def->{coderef} ) {
    if ( defined( $def->{arity} ) ) {
      if ( is_ArrayRef( $def->{arity} ) ) {
        return $def->{arity}->[0];
      }
      else {
        return $def->{arity};
      }
    }
    else {
      return 0;
    }
  }
  else {
    return 0;
  }
}

sub _is_placeholder {
  my ( $self, $obj ) = @_;

  return blessed($obj) && $obj->isa('Dallycot::AST::Placeholder');
}

sub apply {
  my ( $self, $name, $parent_engine, $options, @bindings ) = @_;

  my $def = $self->get_definition($name);

  if ( !$def ) {
    my $d = deferred;
    $d->reject("$name is undefined.");
    return $d->promise;
  }

  if ( $def->{coderef} ) {
    if ( defined $def->{arity} ) {
      if ( is_ArrayRef( $def->{arity} ) ) {
        if ( $def->{arity}->[0] > @bindings
          || ( @{ $def->{arity} } > 1 && @bindings > $def->{arity}->[1] ) )
        {
          my $d = deferred;
          $d->reject( "Expected "
              . $def->{arity}->[0] . " to "
              . $def->{arity}->[1]
              . " arguments but found "
              . scalar(@bindings) );
          return $d->promise;
        }
      }
      elsif ( $def->{arity} != @bindings ) {
        my $d = deferred;
        $d->reject( "Expected " . $def->{arity} . " argument(s)s but found " . scalar(@bindings) );
        return $d->promise;
      }
    }

    # we look for placeholders and return a lambda if there are any
    if ( grep { $self->_is_placeholder($_) } @bindings ) {
      my ( @filled_bindings, @filled_identifiers, @args, @new_args );
      foreach my $binding (@bindings) {
        if ( $self->_is_placeholder($binding) ) {
          push @new_args, '__arg_' . $#args;
          push @args,     '__arg_' . $#args;
        }
        else {
          push @filled_identifiers, '__arg_' . $#args;
          push @args,               '__arg_' . $#args;
          push @filled_bindings,    $binding;
        }
      }
      my $engine = $parent_engine->with_child_scope;
      return collect( $engine->collect(@filled_bindings), $engine->collect( values %$options ) )->then(
        sub {
          my ( $collected_bindings, $new_values ) = @_;
          my @collected_bindings = @$collected_bindings;
          my @new_values         = @$new_values;
          my %new_options;
          @new_options{ keys %$options } = @new_values;
          return Dallycot::Value::Lambda->new(
            expression => Dallycot::AST::Apply->new(
              $self->_uri_for_name($name),
              [ map { bless [$_] => 'Dallycot::AST::Fetch' } @args ],
            ),
            bindings => \@new_args,
            options  => \%new_options,
            closure_environment =>
              { map { $filled_identifiers[$_] => $collected_bindings[$_] } ( 0 .. $#filled_identifiers ) }
          );
        }
      );
    }
    elsif ( $def->{hold} ) {
      my $engine = $parent_engine->with_child_scope;
      return $def->{coderef}->( $engine, $options, @bindings );
    }
    else {
      my $engine = $parent_engine->with_child_scope;
      return collect( $engine->collect(@bindings), $engine->collect( values %$options ) )->then(
        sub {
          my ( $collected_bindings, $new_values ) = @_;

          my @collected_bindings = @$collected_bindings;
          my @new_values         = @$new_values;
          my %new_options;
          @new_options{ keys %{ $def->{options} || {} } } = values %{ $def->{options} || {} };
          @new_options{ keys %$options } = @new_values;
          $def->{coderef}->( $engine, \%new_options, @collected_bindings );
        }
      );
    }
  }
  elsif ( $def->{expression} ) {
    my $engine = $parent_engine->with_child_scope;
    return $def->{expression}->then(
      sub {
        my ($lambda) = @_;
        $lambda->apply( $engine, $options, @bindings );
      }
    );
  }
  else {
    my $d = deferred;
    $d->reject("Value is not a lambda");
    return $d->promise;
  }
}

__PACKAGE__->meta->make_immutable;

__PACKAGE__->libraries;

1;
