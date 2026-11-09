package DBIO::GraphQL::Limits;
# ABSTRACT: Check a GraphQL document for cycles, depth and cost before it runs
use strict;
use warnings;

our $VERSION = '0.900004';

use Scalar::Util ();

# The document is walked before the engine sees it: the engine has no
# validation of its own, and the relationship fields point at each other, so
# one document can ask for an unbounded amount of work. Three rules, all
# checked on the parsed AST before the first SQL:
#
#   * no fragment cycle (the engine has no NoFragmentCycles rule);
#   * the selection depth after unfolding fragments is at most max_depth;
#   * the cost is at most max_cost: every field costs 1, aliases one by one,
#     and a field that yields rows -- a plural root query with its connection
#     object, a has_many relationship field -- multiplies the cost of what is
#     below it by its page size.


sub check {
  my ($class, %a) = @_;
  my $ast    = $a{ast};
  my $policy = $a{policy};

  my %fragments = map { $_->{name} => $_ } grep { $_->{kind} eq 'fragment' } @$ast;
  _no_fragment_cycles(\%fragments);

  my @operations = grep { $_->{kind} eq 'operation' } @$ast;
  @operations = grep { ($_->{name} // '') eq $a{operation} } @operations
    if defined $a{operation} && length $a{operation};

  my $schema = $a{schema};
  my %connection = _connection_types($schema);

  for my $op (@operations) {
    my $type = $schema->${\ ($op->{operationType} || 'query')} or next;
    my $ctx = {
      fragments  => \%fragments,
      policy     => $policy,
      schema     => $schema,
      connection => \%connection,
      variables  => $a{variables} || {},
      op_vars    => $op->{variables} || {},
    };
    _cost($ctx, $op->{selections} || [], $type, 0);
  }
  return;
}

# The connection objects of the plural root queries: the return type of every
# root field that takes both page and cursor.
sub _connection_types {
  my ($schema) = @_;
  my %names;
  my $fields = $schema->query->fields;
  for my $def (values %$fields) {
    next unless ref $def->{args} eq 'HASH' && $def->{args}{page} && $def->{args}{cursor};
    my $type = _unwrap($def->{type});
    $names{ $type->name } = 1 if $type && $type->can('name');
  }
  return %names;
}

sub _unwrap {
  my ($type) = @_;
  $type = $type->of while $type && $type->can('of');
  return $type;
}

# --- fragment cycles -------------------------------------------------------

sub _spreads {
  my ($selections, $into) = @_;
  for my $node (@$selections) {
    push @$into, $node->{name} if ($node->{kind} // '') eq 'fragment_spread';
    _spreads($node->{selections}, $into) if $node->{selections};
  }
  return $into;
}

sub _no_fragment_cycles {
  my ($fragments) = @_;
  my %edges = map { $_ => _spreads($fragments->{$_}{selections} || [], []) } keys %$fragments;
  my %state;    # 1 = on the current path, 2 = done
  my $visit; $visit = sub {
    my ($name) = @_;
    return if !$edges{$name} || ($state{$name} // 0) == 2;
    die "DBIO::GraphQL: fragment cycle through '$name'\n" if ($state{$name} // 0) == 1;
    $state{$name} = 1;
    $visit->($_) for @{ $edges{$name} };
    $state{$name} = 2;
  };
  $visit->($_) for sort keys %edges;
  undef $visit;
  return;
}

# --- depth and cost ----------------------------------------------------------

# _cost($ctx, \@selections, $parent_type, $depth)
#
# The cost of a selection set, fragments unfolded at every spread. Dies as soon
# as the depth or the running cost passes its limit, so the walk stays as small
# as the budget.
sub _cost {
  my ($ctx, $selections, $type, $depth) = @_;
  my $policy = $ctx->{policy};
  my $total = 0;

  for my $node (@$selections) {
    my $kind = $node->{kind} // '';

    if ($kind eq 'fragment_spread') {
      my $fragment = $ctx->{fragments}{ $node->{name} } or next;
      $total += _cost($ctx, $fragment->{selections} || [], $type, $depth);
    }
    elsif ($kind eq 'inline_fragment') {
      $total += _cost($ctx, $node->{selections} || [], $type, $depth);
    }
    elsif ($kind eq 'field') {
      my $level = $depth + 1;
      die "DBIO::GraphQL: query depth exceeds max_depth (" . $policy->max_depth . ")\n"
        if $level > $policy->max_depth;

      my $def = $type && $type->can('fields') ? $type->fields->{ $node->{name} } : undef;
      my $inner = $def ? _unwrap($def->{type}) : undef;
      my $factor = $def ? _factor($ctx, $node, $def, $type) : 1;
      my $below = $node->{selections}
        ? _cost($ctx, $node->{selections}, $inner, $level)
        : 0;
      $total += 1 + $factor * $below;
    }

    die "DBIO::GraphQL: query cost exceeds max_cost (" . $policy->max_cost . ")\n"
      if $total > $policy->max_cost;
  }
  return $total;
}

# How many rows a field yields, per parent row: the page size of a plural root
# query, default_rows for a has_many field, 1 for everything else.
sub _factor {
  my ($ctx, $node, $def, $parent) = @_;
  my $policy = $ctx->{policy};

  if (ref $def->{args} eq 'HASH' && $def->{args}{page} && $def->{args}{cursor}) {
    my $args = $node->{arguments} || {};
    my $cursor = _value($ctx, $args->{cursor});
    if (ref $cursor eq 'HASH') {
      return _rows(_value($ctx, $cursor->{first}), 10, $policy, 'first');
    }
    my $page = _value($ctx, $args->{page});
    if (ref $page eq 'HASH') {
      return _rows(_value($ctx, $page->{take}), 10, $policy, 'take');
    }
    return $policy->default_rows;
  }

  my $type = $def->{type};
  $type = $type->of while $type && $type->can('of') && !$type->isa('GraphQL::Type::List');
  return $policy->default_rows
    if $type && $type->isa('GraphQL::Type::List')
    && !$ctx->{connection}{ $parent->name };
  return 1;
}

# A given row count, or the resolver's own default when the argument is absent.
sub _rows {
  my ($value, $absent, $policy, $what) = @_;
  return $absent unless defined $value;
  return $policy->default_rows
    unless !ref $value && Scalar::Util::looks_like_number($value);
  die "DBIO::GraphQL: $what $value exceeds max_rows (" . $policy->max_rows . ")\n"
    if $value > $policy->max_rows;
  return $value >= 1 ? $value : 1;
}

# An argument value with variables resolved: the given value, else the
# variable's default in the operation.
sub _value {
  my ($ctx, $value) = @_;
  if (ref $value eq 'SCALAR') {
    my $name = $$value;
    return exists $ctx->{variables}{$name}
      ? $ctx->{variables}{$name}
      : ($ctx->{op_vars}{$name} || {})->{default_value};
  }
  return $value;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::GraphQL::Limits - Check a GraphQL document for cycles, depth and cost before it runs

=head1 VERSION

version 0.900004

=head1 METHODS

=head2 check

  DBIO::GraphQL::Limits->check(
    ast       => $ast,         # GraphQL::Language::Parser::parse result
    schema    => $graphql_schema,
    policy    => $policy,      # DBIO::GraphQL::Policy: max_depth, max_cost, default_rows
    variables => \%variables,
    operation => $name,        # optional operation name
  );

Dies with a message naming the violated rule (C<fragment cycle>,
C<max_depth> or C<max_cost>). Returns nothing when the document passes.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
