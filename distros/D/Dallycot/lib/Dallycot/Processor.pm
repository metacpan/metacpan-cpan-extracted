package Dallycot::Processor;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Run compiled Dallycot code.

use strict;
use warnings;

use utf8;
use Moose;

use namespace::autoclean;

use Promises qw(deferred);

use experimental qw(switch);

use Dallycot::Context;
use Dallycot::Registry;
use Dallycot::Resolver;
use Dallycot::Value;
use Dallycot::AST;

use Readonly;

use Math::BigRat try => 'GMP';

BEGIN {
  $Dallycot::Processor::USING_XS = eval {
    require Dallycot::Processor::XS;
    1;
  };

  if ($Dallycot::Processor::USING_XS) {
    extends 'Dallycot::Processor::XS';
  }
  else {
    extends 'Dallycot::Processor::PP';
  }
}

has context => (
  is      => 'ro',
  isa     => 'Dallycot::Context',
  handles => [
    qw[
      has_assignment
      get_assignment
      add_assignment
      has_namespace
      get_namespace
      add_namespace
      get_namespace_search_path
      append_namespace_search_path
      ]
  ],
  default => sub {
    Dallycot::Context->new;
  }
);

has channels => (
  is        => 'ro',
  isa       => 'HashRef',
  default   => sub { +{} },
  predicate => 'has_channels',
  lazy      => 1
);

has max_cost => (
  is      => 'ro',
  isa     => 'Int',
  default => 100_000
);

has ignore_cost => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0
);

has cost => (
  is      => 'ro',
  isa     => 'Int',
  writer  => '_cost',
  default => 0
);

has parent => (
  is        => 'ro',
  predicate => 'has_parent',
  isa       => __PACKAGE__
);

sub channel_send {
  my ( $self, $channel, @items ) = @_;

  if ( $self->has_channels && exists( $self->channels->{$channel} ) ) {
    if ( $self->channels->{$channel} ) {
      $self->channels->{$channel}->send_data(@items);
    }
  }
  elsif ( $self->has_parent ) {
    $self->parent->channel_send( $channel, @items );
  }
  return;
}

sub channel_read {
  my ( $self, $channel, %options ) = @_;

  if ( $self->has_channels && exists( $self->channels->{$channel} ) ) {
    if ( $self->channels->{$channel} ) {
      return $self->channels->{$channel}->receive_data(%options);
    }
  }
  elsif ( $self->has_parent ) {
    return $self->parent->channel_read( $channel, %options );
  }
  my $d = deferred;
  $d->resolve( Dallycot::Value::String->new('') );
  return $d->promise;
}

sub create_channel {
  my ( $self, $channel, $object ) = @_;

  $self->channels->{$channel} = $object;
  return;
}

sub with_child_scope {
  my ($self) = @_;

  my $ctx = $self->context;

  return __PACKAGE__->new(
    parent   => $self,
    max_cost => $self->max_cost - $self->cost,
    context  => Dallycot::Context->new(
      parent                => $ctx,
      namespace_search_path => [ @{ $ctx->namespace_search_path } ]
    )
  );
}

sub with_new_closure {
  my ( $self, $environment, $namespaces, $search_path ) = @_;

  return __PACKAGE__->new(
    parent   => $self,
    max_cost => $self->max_cost - $self->cost,
    context  => Dallycot::Context->new(
      environment           => +{%$environment},
      namespaces            => +{%$namespaces},
      namespace_search_path => [ @{ ( $search_path // $self->context->namespace_search_path ) } ]
    )
  );
}

sub _execute_expr {
  my ( $self, $expr ) = @_;

  if ( 'ARRAY' eq ref $expr ) {
    return $self->execute(@$expr);
  }
  else {
    return $self->execute($expr);
  }
}

sub collect {
  my ( $self, @exprs ) = @_;

  return Promises::collect( map { $self->_execute_expr($_) } @exprs )->then(
    sub {
      map {@$_} @_;
    }
  );
}

# for now, just returns the original values
sub coerce {
  my ( $self, $a, $b, $atype, $btype ) = @_;

  my $d = deferred;

  $d->resolve( $a, $b );

  return $d->promise;
}

sub make_lambda {
  my ( $self, $expression, $bindings, $bindings_with_defaults, $options ) = @_;

  $bindings               ||= [];
  $bindings_with_defaults ||= [];
  $options                ||= {};

  return Dallycot::Value::Lambda->new(
    expression             => $expression,
    bindings               => $bindings,
    bindings_with_defaults => $bindings_with_defaults,
    options                => $options,
    engine                 => $self
  );
}

Readonly my $TRUE      => Dallycot::Value::Boolean->new(1);
Readonly my $FALSE     => Dallycot::Value::Boolean->new();
Readonly my $UNDEFINED => Dallycot::Value::Undefined->new;
Readonly my $ZERO      => Dallycot::Value::Numeric->new( Math::BigRat->bzero() );
Readonly my $ONE       => Dallycot::Value::Numeric->new( Math::BigRat->bone() );

sub TRUE ()      { return $TRUE }
sub FALSE ()     { return $FALSE }
sub UNDEFINED () { return $UNDEFINED }
sub ZERO ()      { return $ZERO }
sub ONE ()       { return $ONE }

sub _execute_loop {
  my ( $self, $deferred, $expected_types, $stmt, @stmts ) = @_;

  if ( !@stmts ) {
    $self->_execute( $expected_types, $stmt )
      ->done( sub { $deferred->resolve(@_); }, sub { $deferred->reject(@_); } );
    return;
  }
  $self->_execute( ['Any'], $stmt )
    ->done( sub { $self->_execute_loop( $deferred, $expected_types, @stmts ) },
    sub { $deferred->reject(@_); } );
  return;
}

sub _execute {
  my ( $self, $expected_types, $ast ) = @_;

  my $promise = eval {
    if ( $self->add_cost(1) > $self->max_cost ) {
      my $d = deferred;
      $d->reject("Exceeded maximum evaluation cost");
      $d->promise;
    }
    else {
      $ast->execute($self);
    }
  };

  return $promise if $promise;

  my $d = deferred;
  if ($@) {
    $d->reject($@);
  }
  else {
    $d->reject("Unable to evaluate");
  }
  return $d->promise;
}

sub execute {
  my ( $self, $ast, @ast ) = @_;

  if(!defined $ast) {
    my $d = deferred;
    $d -> resolve(UNDEFINED);
    return $d -> promise;
  }

  if ( !blessed $ast) {
    print STDERR "$ast not blessed at ", join( " ", caller ), "\n";
  }

  my @expected_types = ('Any');

  if (@ast) {
    my $potential_types = pop @ast;

    if ( 'ARRAY' eq ref $potential_types ) {
      @expected_types = @$potential_types;
    }
    else {
      push @ast, $potential_types;
    }
  }

  if (@ast) {
    my $d = deferred;
    $self->_execute_loop( $d, \@expected_types, $ast, @ast );
    return $d->promise;
  }
  else {
    return $self->_execute( \@expected_types, $ast );
  }
}

sub compose_lambdas {
  my ( $self, @lambdas ) = @_;
  @lambdas = reverse @lambdas;

  my $new_engine = $self->with_child_scope;

  my $expression = Dallycot::AST::Fetch->new('#');

  for my $idx ( 0 .. $#lambdas ) {
    $new_engine->context->add_assignment( "__lambda_" . $idx, $lambdas[$idx] );
    $expression
      = Dallycot::AST::Apply->new( Dallycot::AST::Fetch->new( '__lambda_' . $idx ), [$expression] );
  }

  return $new_engine->make_lambda( $expression, ['#'] );
}

sub _add_filter_to_context {
  my ( $engine, $idx, $filter, $expression ) = @_;

  $engine->context->add_assignment( "__lambda_" . $idx, $filter );
  return Dallycot::AST::Apply->new( Dallycot::AST::Fetch->new( '__lambda_' . $idx ), [$expression] );
}

sub compose_filters {
  my ( $self, @filters ) = @_;

  if ( @filters == 1 ) {
    return $filters[0];
  }

  my $new_engine = $self->with_child_scope;

  my $expression   = Dallycot::AST::Fetch->new('#');
  my $idx          = 0;
  my @applications = map { _add_filter_to_context( $new_engine, $idx++, $_, $expression ) } @filters;

  return $new_engine->make_lambda( Dallycot::AST::All->new(@applications), ['#'] );
}

sub make_map {
  my ( $self, $transform ) = @_;

  return $self->execute(
    Dallycot::AST::Apply->new(
      Dallycot::Value::URI->new('http://www.dallycot.net/ns/loc/1.0#map'),
      [ $transform, Dallycot::AST::Placeholder->new ], {}
    )
  );
}

sub make_filter {
  my ( $self, $selector ) = @_;

  return $self->execute(
    Dallycot::AST::Apply->new(
      Dallycot::Value::URI->new('http://www.dallycot.net/ns/loc/1.0#filter'),
      [ $selector, Dallycot::AST::Placeholder->new ], {}
    )
  );
}

__PACKAGE__->meta->make_immutable;

require Dallycot::Library::Core;

1;
