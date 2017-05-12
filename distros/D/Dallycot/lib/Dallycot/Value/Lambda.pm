package Dallycot::Value::Lambda;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: An expression with an accompanying closure environment

use strict;
use warnings;

use utf8;
use parent 'Dallycot::Value::Any';

use Promises qw(deferred collect);

use Scalar::Util qw(blessed);
use Carp qw(croak);

use Readonly;

Readonly my $EXPRESSION             => 0;
Readonly my $BINDINGS               => 1;
Readonly my $BINDINGS_WITH_DEFAULTS => 2;
Readonly my $OPTIONS                => 3;
Readonly my $CLOSURE_ENVIRONMENT    => 4;
Readonly my $CLOSURE_NAMESPACES     => 5;
Readonly my $CLOSURE_NAMESPACE_PATH => 6;

sub new {
  my ( $class, %options ) = @_;

  my ( $expression, $bindings, $bindings_with_defaults, $options,
    $closure_environment, $closure_namespaces, $namespace_search_path, $engine )
    = @options{
    qw(expression bindings bindings_with_defaults options closure_environment closure_namespaces namespace_search_path engine)
    };

  $class = ref $class || $class;

  my ($closure_context);

  $bindings               ||= [];
  $bindings_with_defaults ||= [];
  $options                ||= {};
  $closure_environment    ||= {};
  $closure_namespaces     ||= {};
  $namespace_search_path  ||= [];

  if ($engine) {
    $closure_context = $engine->context->make_closure($expression);
    delete @{ $closure_context->environment }{ @$bindings, map { $_->[0] } @$bindings_with_defaults };
    $closure_environment   = $closure_context->environment;
    $closure_namespaces    = $closure_context->namespaces;
    $namespace_search_path = $closure_context->namespace_search_path;
  }

  return bless [
    $expression,          $bindings,           $bindings_with_defaults, $options,
    $closure_environment, $closure_namespaces, $namespace_search_path
  ] => $class;
}

sub is_lambda { return 1; }

sub id {
  return '^^Lambda';
}

sub to_rdf {
  my( $self, $parent_model ) = @_;

  my $model = $parent_model -> child_model(
    namespace_search_path => [ @{$self -> [$CLOSURE_NAMESPACE_PATH]} ],
    prefixes => RDF::Trine::NamespaceMap->new($self -> [$CLOSURE_NAMESPACES]),
  );

  my $bnode = $model -> bnode;
  $model -> add_type($bnode, 'loc:Algorithm');
  $model -> add_expression($bnode, $self -> [$EXPRESSION]);
  $model -> add_list(
    $bnode, 'loc:bindings',
    (map { $self -> _binding_rdf($model, $_) } @{$self->[$BINDINGS]}),
    (map { $self -> _binding_rdf($model, @$_) } @{$self->[$BINDINGS_WITH_DEFAULTS]})
  );
  foreach my $opt(keys %{$self->[$OPTIONS]}) {
    $model -> add_option(
      $bnode,
      $opt,
      $self->[$OPTIONS]->{$opt}->to_rdf($model)
    );
  }
}

sub as_text {
  my ($self) = @_;
  my ( $min, $max ) = $self->arity;
  if ( $min < $max ) {
    return "(lambda/$min..$max)";
  }
  else {
    return "(lambda/$min)";
  }
}

sub arity {
  my ($self) = @_;
  my $min    = scalar( @{ $self->[$BINDINGS] } );
  my $more   = scalar( @{ $self->[$BINDINGS_WITH_DEFAULTS] } );
  if (wantarray) {
    return ( $min, $min + $more );
  }
  else {
    return $min + $more;
  }
}

sub min_arity {
  my ($self) = @_;

  return scalar( @{ $self->[$BINDINGS] } );
}

sub _arity_in_range {
  my ( $self, $arity, $min, $max ) = @_;

  if ( $arity < $min || $arity > $max ) {
    if ( $min == $max ) {
      croak "Expected $min but found $arity arguments.";
    }
    else {
      croak "Expected $min..$max but found $arity arguments.";
    }
    return;
  }
  return 1;
}

sub _options_are_good {
  my ( $self, $options ) = @_;

  if (%$options) {
    my @bad_options = grep { not exists ${ $self->[$OPTIONS] }{$_} } keys %$options;
    if ( @bad_options > 1 ) {
      croak "Options " . join( ", ", sort(@bad_options) ) . " are not allowed.";
    }
    elsif (@bad_options) {
      croak "Option " . $bad_options[0] . " is not allowed.";
    }
  }
  return 1;
}

sub _is_placeholder {
  my ( $self, $obj ) = @_;
  return blessed($obj) && $obj->isa('Dallycot::AST::Placeholder');
}

sub _get_bindings {
  my ( $self, $engine, @bindings ) = @_;

  my ( $min_arity, $max_arity ) = $self->arity;
  my $arity = scalar(@bindings);

  my ( @new_bindings, @new_bindings_with_defaults, @filled_bindings, @filled_identifiers );

  foreach my $idx ( 0 .. $min_arity - 1 ) {
    if ( $self->_is_placeholder( $bindings[$idx] ) ) {
      push @new_bindings, $self->[$BINDINGS][$idx];
    }
    else {
      push @filled_bindings,    $bindings[$idx];
      push @filled_identifiers, $self->[$BINDINGS][$idx];
    }
  }
  if ( $arity > $min_arity ) {
    foreach my $idx ( $min_arity .. $arity - 1 ) {
      if ( $self->_is_placeholder( $bindings[$idx] ) ) {
        push @new_bindings_with_defaults, $self->[$BINDINGS_WITH_DEFAULTS][ $idx - $min_arity ];
      }
      else {
        push @filled_bindings,    $bindings[$idx];
        push @filled_identifiers, $self->[$BINDINGS_WITH_DEFAULTS][ $idx - $min_arity ]->[0];
      }
    }
  }
  if ( $max_arity > 0 && $arity < $max_arity ) {
    foreach my $idx ( $arity .. $max_arity - 1 ) {
      push @filled_bindings,    $self->[$BINDINGS_WITH_DEFAULTS][ $idx - $min_arity ]->[1];
      push @filled_identifiers, $self->[$BINDINGS_WITH_DEFAULTS][ $idx - $min_arity ]->[0];
    }
  }

  my %bindings;
  @bindings{@filled_identifiers} = map { $engine->execute($_) } @filled_bindings;

  return ( \%bindings, \@new_bindings, \@new_bindings_with_defaults );
}

sub _get_options {
  my ( $self, $engine, $options ) = @_;

  my @option_names = keys %$options;

  my %ret_options;

  @ret_options{ keys %$options } = map { $engine->execute($_) } values %$options;

  return +{ %{ $self->[$OPTIONS] }, %ret_options };
}

sub child_nodes { return () }

sub apply {
  my ( $self, $engine, $options, @bindings ) = @_;

  my ( $min_arity, $max_arity ) = $self->arity;

  my $arity = scalar(@bindings);

  $self->_arity_in_range( $arity, $min_arity, $max_arity );
  $self->_options_are_good($options);
  my ( $filled_bindings, $new_bindings, $new_bindings_with_defaults )
    = $self->_get_bindings( $engine, @bindings );
  my ($filled_options) = $self->_get_options( $engine, $options );

  my %environment = ( %{ $self->[$CLOSURE_ENVIRONMENT] || {} }, %$filled_bindings );

  if ( @$new_bindings || @$new_bindings_with_defaults ) {
    my $promise = deferred;
    $promise->resolve(
      bless [
        $self->[$EXPRESSION], $new_bindings, $new_bindings_with_defaults,
        $filled_options,      \%environment, $self->[$CLOSURE_NAMESPACES],
        $self->[$CLOSURE_NAMESPACE_PATH]
      ] => __PACKAGE__
    );
    return $promise->promise;
  }
  else {
    my $new_engine = $engine->with_new_closure(
      +{ %environment, %{$filled_options} },
      $self->[$CLOSURE_NAMESPACES],
      $self->[$CLOSURE_NAMESPACE_PATH]
    );
    return $new_engine->execute( $self->[$EXPRESSION] );
  }
}

1;
