package Dallycot::AST::Sequence;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Creates a new execution context for child nodes

use strict;
use warnings;

use utf8;
use parent 'Dallycot::AST';

use List::Util qw(any);
use Promises qw(deferred);
use Scalar::Util qw(blessed);

sub new {
  my ( $class, @expressions ) = @_;

  my @declarations = grep { blessed($_) && $_->is_declarative } @expressions;
  my @statements   = grep { blessed($_) && !$_->is_declarative } @expressions;

  my @assignment_names = grep {defined} map { $_->identifier } @declarations;

  my %namespace_prefixes
    = map { $_->prefix => $_->namespace } grep { $_->isa('Dallycot::AST::XmlnsDef') } @declarations;

  @declarations = grep { !$_->isa('Dallycot::AST::XmlnsDef') } @declarations;

  my @namespace_searches = map { $_->namespace } grep { $_->isa('Dallycot::AST::Uses') } @declarations;

  @declarations = grep { !$_->isa('Dallycot::AST::Uses') } @declarations;

  $class = ref $class || $class;

  return
    bless [ \@declarations, \@statements, \@assignment_names, \%namespace_prefixes,
    \@namespace_searches ] => $class;
}

sub to_rdf {
  my($self, $model) = @_;

  my $bnode = $model -> bnode;
  my $child_model = $model -> child_model;

  while(my($ns, $href) = each %{$self->[3]||{}}) {
    $child_model -> add_namespace_mapping(
      $ns => (blessed $href ? $href -> value : $href)
    );
  }

  my @uses = @{$self -> [4]||[]};
  $child_model -> add_search_path(@uses);

  foreach my $decl (@{$self->[0]}) {
    $decl -> to_rdf($child_model)
  }

  # actually, we need to build out a lambda for each one and discard
  # its argument, something like:
  # { expression[n] }( { expression[n-1] }( { expression[n-2] }( ... ) ) )
  #
  # run( a, b ) => b
  # run( run( expression[1] ), expression[0] )
  # run( run( expression[2] ), expression[1] ), expression[0] )
  #
  # last({ (#2)() }/2 << [ sequence of expressions ])
  #
  # applying <last> to <foldl> applied to a list of expressions
  # with each expression being a closure over what's declared in this scope
  #   and parent scopes
  #
  my @expressions = @{$self->[1]};

  return $bnode unless @expressions;

  if(@expressions == 1) {
    return $expressions[0] -> to_rdf($child_model);
  }

  my $expression_list = $child_model -> model -> add_list(
    map { $_ -> to_rdf($child_model) } @expressions
  );

  $child_model -> apply(
    $child_model -> meta_uri('loc:execute-list'),
    [ $expression_list ]
  );

  return $bnode;
}

sub to_string {
  my ($self) = @_;
  return join( "; ",
    ( map { 'uses "' . $_ . '"' } @{ $self->[4] } ),
    ( map { "ns:$_ := \"" . $self->[3]->{$_} . "\"" } keys %{ $self->[3] } ),
    map { $_->to_string } @{ $self->[0] },
    @{ $self->[1] } );
}

sub simplify {
  my ($self) = @_;

  return $self->new( map { $_->simplify } @{ $self->[0] }, @{ $self->[1] } );
}

sub check_for_common_mistakes {
  my ($self) = @_;

  my @warnings;

# if(any { $_ -> isa('Dallycot::AST::Equality') } @{$self}[1][0..-2]) {
#   push @warnings, 'Did you mean to assign instead of test for equality?';
# }
# if(any { !$_ -> isa('Dallycot::AST::Equality') && $_ -> isa('Dallycot::AST::ComparisonBase') } @{$self}[1][0..-2]) {
#   push @warnings, 'Result of comparison is not used.';
# }
# push @warnings, map { $_ -> check_for_common_mistakes } @$self;
  return @warnings;
}

sub execute {
  my ( $self, $engine ) = @_;

  my $child_scope = $engine->with_child_scope();
  my $var_scope = $engine->has_parent ? $child_scope : $engine;

  foreach my $ident ( @{ $self->[2] } ) {
    $var_scope->add_assignment($ident);
  }

  # wait for namespaces to load
  Dallycot::Registry->instance->register_used_namespaces( @{$self->[4]} )->then(sub {
    $var_scope->append_namespace_search_path( @{ $self->[4] } );

    for my $ns ( keys %{ $self->[3] } ) {
      $var_scope->add_namespace( $ns, $self->[3]->{$ns} );
    }

    my $assignments = $var_scope->collect( @{ $self->[0] } );

    if(@{$self->[1]}) {
      $assignments->done(sub{});
      return $var_scope->execute( @{ $self->[1] } );
    }
    else {
      return $assignments->then(sub {
        my($last) = pop @_;
        if($last) {
          return $last;
        }
        else {
          return $engine -> UNDEFINED;
        }
      });
    }
  });
}

sub identifiers {
  my ($self) = @_;

  my @identifiers = map { $_->identifiers } $self->child_nodes;
  my %assignments = map { $_ => 1 } @{ $self->[2] };
  return grep { !$assignments{$_} } @identifiers;
}

sub child_nodes {
  my ($self) = @_;

  return ( @{ $self->[0] }, @{ $self->[1] } );
}

1;
