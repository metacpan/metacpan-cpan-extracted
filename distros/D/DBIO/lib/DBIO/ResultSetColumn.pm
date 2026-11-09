package DBIO::ResultSetColumn;
# ABSTRACT: Convenience wrapper for working with a single ResultSet column

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Base';
use DBIO::Carp;
use DBIO::Util qw(assert_no_list_context assert_function_name);
use Scalar::Util 'blessed';
use namespace::clean;




sub new {
  my ($class, $rs, $column) = @_;
  $class = ref $class if ref $class;

  $rs->throw_exception('column must be supplied') unless $column;

  my $orig_attrs = $rs->_resolved_attrs;
  my $alias = $rs->current_source_alias;
  my $rsrc = $rs->result_source;

  # If $column can be found in the 'as' list of the parent resultset, use the
  # corresponding element of its 'select' list (to keep any custom column
  # definition set up with 'select' or '+select' attrs), otherwise use $column
  # (to create a new column definition on-the-fly).
  my $as_list = $orig_attrs->{as} || [];
  my $select_list = $orig_attrs->{select} || [];
  my ($as_index) = grep { ($as_list->[$_] || "") eq $column } 0..$#$as_list;
  my $select = defined $as_index ? $select_list->[$as_index] : $column;

  my $colmap;
  for ($rsrc->columns, $column) {
    if ($_ =~ /^ \Q$alias\E \. ([^\.]+) $ /x) {
      $colmap->{$_} = $1;
    }
    elsif ($_ !~ /\./) {
      $colmap->{"$alias.$_"} = $_;
      $colmap->{$_} = $_;
    }
  }

  my $new_parent_rs;
  # analyze the order_by, and see if it is done over a function/nonexistentcolumn
  # if this is the case we will need to wrap a subquery since the result of RSC
  # *must* be a single column select
  if (
    scalar grep
      { ! exists $colmap->{$_->[0]} }
      ( $rsrc->schema->storage->_extract_order_criteria ($orig_attrs->{order_by} ) )
  ) {
    # nuke the prefetch before collapsing to sql
    my $subq_rs = $rs->search_rs;
    $subq_rs->{attrs}{join} = $subq_rs->_merge_joinpref_attr( $subq_rs->{attrs}{join}, delete $subq_rs->{attrs}{prefetch} );
    $new_parent_rs = $subq_rs->as_subselect_rs;
  }

  $new_parent_rs ||= $rs->search_rs;
  my $new_attrs = $new_parent_rs->{attrs} ||= {};

  # prefetch causes additional columns to be fetched, but we can not just make a new
  # rs via the _resolved_attrs trick - we need to retain the separation between
  # +select/+as and select/as. At the same time we want to preserve any joins that the
  # prefetch would otherwise generate.
  $new_attrs->{join} = $rs->_merge_joinpref_attr( $new_attrs->{join}, delete $new_attrs->{prefetch} );

  # {collapse} would mean a has_many join was injected, which in turn means
  # we need to group *IF WE CAN* (only if the column in question is unique)
  if (!$orig_attrs->{group_by} && $orig_attrs->{collapse}) {

    if ($colmap->{$select} and $rsrc->_identifying_column_set([$colmap->{$select}])) {
      $new_attrs->{group_by} = [ $select ];
      delete @{$new_attrs}{qw(distinct _grouped_by_distinct)}; # it is ignored when group_by is present
    }
    else {
      carp (
          "Attempting to retrieve non-unique column '$column' on a resultset containing "
        . 'one-to-many joins will return duplicate results.'
      );
    }
  }

  return bless {
    _select => $select,
    _as => $column,
    _parent_resultset => $new_parent_rs,
    # A column resultset built from a context-bound resultset inherits the
    # pinned async context, so $rs->with_context($ctx)->get_column($c)->all_async
    # fetches on the pinned connection instead of the pool.
    ( $rs->_async_context ? ( _async_context => $rs->_async_context ) : () ),
  }, $class;
}


sub as_query { return shift->_resultset->as_query(@_) }



sub next {
  my $self = shift;

  # using cursor so we don't inflate anything
  my ($row) = $self->_resultset->cursor->next;

  return $row;
}



sub all {
  my $self = shift;

  # using cursor so we don't inflate anything
  return map { $_->[0] } $self->_resultset->cursor->all;
}



sub reset {
  my $self = shift;
  $self->_resultset->cursor->reset;
  return $self;
}



sub first {
  my $self = shift;

  # using cursor so we don't inflate anything
  $self->_resultset->cursor->reset;
  my ($row) = $self->_resultset->cursor->next;

  return $row;
}



sub single {
  my $self = shift;

  my $attrs = $self->_resultset->_resolved_attrs;
  my ($row) = $self->_resultset->result_source->storage->select_single(
    $attrs->{from}, $attrs->{select}, $attrs->{where}, $attrs
  );

  return $row;
}



sub single_async {
  my $self = shift;

  return $self->_rsc_run_async('single',
    sub {
      my ($backend, $fc) = @_;

      my $attrs = $self->_resultset->_resolved_attrs;
      return $backend->select_single_async(
        $attrs->{from}, $attrs->{select}, $attrs->{where}, $attrs,
      )->then(sub {
        my ($raw_row) = @_;
        return (defined $raw_row && ref $raw_row eq 'ARRAY') ? $raw_row->[0] : $raw_row;
      });
    },
    sub { $self->single },
  );
}



sub all_async {
  my $self = shift;

  return $self->_rsc_run_async('all',
    sub {
      my ($backend, $fc) = @_;

      my $attrs = $self->_resultset->_resolved_attrs;
      return $backend->select_async(
        $attrs->{from}, $attrs->{select}, $attrs->{where}, $attrs,
      )->then(sub {
        my @raw = @_;
        return $fc->done( map { $_->[0] } @raw );
      });
    },
    sub { $self->all },
  );
}



sub min {
  return shift->func('MIN');
}


sub min_rs { return shift->func_rs('MIN') }



sub min_async { return shift->_run_func_async('MIN', 'min') }



sub max {
  return shift->func('MAX');
}


sub max_rs { return shift->func_rs('MAX') }



sub max_async { return shift->_run_func_async('MAX', 'max') }



sub sum {
  return shift->func('SUM');
}


sub sum_rs { return shift->func_rs('SUM') }



sub sum_async { return shift->_run_func_async('SUM', 'sum') }



sub func {
  my ($self,$function) = @_;

  assert_function_name($function, "->func");

  # ADR 0042: func() used to return one value per row in list context.
  # It now always returns the single scalar and refuses list context.
  assert_no_list_context('->func') if wantarray;

  my $cursor = $self->func_rs($function)->cursor;
  return ( $cursor->next )[ 0 ];
}



sub func_rs {
  my ($self,$function) = @_;

  assert_function_name($function, "->func_rs");

  my $rs = $self->{_parent_resultset};
  my $select = $self->{_select};

  # wrap a grouped rs
  if ($rs->_resolved_attrs->{group_by}) {
    $select = $self->{_as};
    $rs = $rs->as_subselect_rs;
  }

  $rs->search( undef, {
    columns => { $self->{_as} => { $function => $select } }
  } );
}



sub func_async {
  my ($self, $function) = @_;
  return $self->_run_func_async($function, 'func');
}

# Shared by min_async/max_async/sum_async/func_async: builds the resultset
# func_rs($function) would query and fetches its one aggregate row through
# select_single_async, bypassing the cursor -- the same shape single_async
# uses, and the async equivalent of func()'s own scalar-context
# ($cursor->next)[0] return.
sub _run_func_async {
  my ($self, $function, $name) = @_;

  return $self->_rsc_run_async($name,
    sub {
      my ($backend, $fc) = @_;

      my $attrs = $self->func_rs($function)->_resolved_attrs;
      return $backend->select_single_async(
        $attrs->{from}, $attrs->{select}, $attrs->{where}, $attrs,
      )->then(sub {
        my ($raw_row) = @_;
        return (defined $raw_row && ref $raw_row eq 'ARRAY') ? $raw_row->[0] : $raw_row;
      });
    },
    # scalar: _rsc_run_async's sync fallback runs its closure in list
    # context (my @r = eval { ... }), and func() now refuses list context
    # outright (ADR 0042) -- force scalar so the immediate mode keeps working.
    sub { scalar $self->func($function) },
  );
}

# ResultSetColumn-level mirror of DBIO::ResultSet::_rs_run_async /
# DBIO::Row::_row_run_async (ADR 0030/0031), one tier down: route to a live
# embedded backend, degrade synchronously in the 'immediate' mode, or croak on
# a sync instance. RSC has no ResultSet of its own to delegate the dispatch to
# (it wraps one, via _resultset/_parent_resultset), so it gets its own copy of
# the three-way contract, exactly as Row does.
sub _rsc_run_async {
  my ($self, $name, $backend_build, $sync_run) = @_;

  my $storage = $self->_resultset->result_source->storage;
  my $fc = $storage->future_class;

  # A pinned context inherited from a context-bound resultset (get_column
  # on a bound RS) or bound directly wins over the pooled backend, so this
  # column's single_async/all_async/func_async runs on the pinned connection.
  # No context => historical path below, unchanged.
  if (my $ctx = $self->_async_context) {
    $self->_assert_async_context_active($ctx, $name);
    $storage->_assert_async_context_owner($ctx);
    return $backend_build->($ctx, $fc);
  }

  if (my $backend = $storage->_async_storage) {
    # A Future derived from the storage's own is reported to the pool (k397).
    return $backend->can('_note_pooled_derivation')
      ? $backend->_note_pooled_derivation(sub { $backend_build->($backend, $fc) })
      : $backend_build->($backend, $fc);
  }

  $self->throw_exception(
    "not an async connection -- connect with { async => ... } to use ${name}_async"
  ) unless defined $storage->_async_mode;

  my @r = eval { $sync_run->() };
  return $@ ? $fc->fail($@) : $fc->done(@r);
}

# ADR 0045: the pinned async context bound to this column resultset (undef when
# unbound). A column resultset produced by ->get_column on a context-bound
# ResultSet inherits its context (see new()), so a bound $rs->get_column($c)
# still batches/pins its aggregate fetch. Mirrors the same-named helpers on
# DBIO::ResultSet / DBIO::Row.
sub _async_context { $_[0]->{_async_context} }


sub with_context {
  my ($self, $ctx) = @_;
  $self->throw_exception(
    'with_context requires an async context object (the one passed to a '
  . 'txn_do_async / pipeline coderef)'
  ) unless defined $ctx and blessed($ctx) and $ctx->can('select_async');
  my $storage = $self->{_parent_resultset}->result_source->storage;
  $storage->_assert_async_context_owner($ctx);
  my $clone = bless { %$self }, ref $self;
  $clone->{_async_context} = $ctx;

  # ADR 0045 / karr k325: func_rs (and min_rs / max_rs / sum_rs) and _resultset
  # are derived from the parent resultset, so the clone gets a bound clone of
  # it -- a column bound here then looks the same as one that get_column made
  # from a bound resultset. The inner resultset is forgotten and built again
  # from the bound parent on first use. The column this was cloned from keeps
  # its own parent and stays unbound.
  $clone->{_parent_resultset} = $self->{_parent_resultset}->with_context($ctx);
  delete $clone->{_resultset};

  return $clone;
}

sub _assert_async_context_active {
  my ($self, $ctx, $name) = @_;
  return if !$ctx->can('_context_active') || $ctx->_context_active;
  $self->throw_exception(
    "the async context bound to this result is no longer active; ${name}_async "
  . "cannot be routed onto it. Pipeline contexts stop accepting work when their "
  . "synchronous batch coderef returns; transaction contexts stop on their "
  . "terminal BEGIN / COMMIT / ROLLBACK path. Issue the async work while its "
  . "owning context remains active, not from a column held past it."
  );
}



sub throw_exception {
  my $self = shift;

  if (ref $self && $self->{_parent_resultset}) {
    $self->{_parent_resultset}->throw_exception(@_);
  }
  else {
    DBIO::Exception->throw(@_);
  }
}

# _resultset
#
# Arguments: none
#
# Return Value: $resultset
#
#  $year_col->_resultset->next
#
# Returns the underlying resultset. Creates it from the parent resultset if
# necessary.
#

sub _resultset {
  my $self = shift;

  return $self->{_resultset} ||= do {

    my $select = $self->{_select};

    if ($self->{_parent_resultset}{attrs}{distinct}) {
      my $alias = $self->{_parent_resultset}->current_source_alias;
      my $rsrc = $self->{_parent_resultset}->result_source;
      my %cols = map { $_ => 1, "$alias.$_" => 1 } $rsrc->columns;

      unless( $cols{$select} ) {
        carp_unique(
          'Use of distinct => 1 while selecting anything other than a column '
        . 'declared on the primary ResultSource is deprecated (you selected '
        . "'$self->{_as}') - please supply an explicit group_by instead"
        );

        # collapse the selector to a literal so that it survives the distinct parse
        # if it turns out to be an aggregate - at least the user will get a proper exception
        # instead of silent drop of the group_by altogether
        $select = \[ $rsrc->storage->sql_maker->_recurse_fields($select) ];
      }
    }

    $self->{_parent_resultset}->search(undef, {
      columns => { $self->{_as} => $select }
    });
  };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::ResultSetColumn - Convenience wrapper for working with a single ResultSet column

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  $rs = $schema->resultset('CD')->search({ artist => 'Tool' });
  $rs_column = $rs->get_column('year');
  $max_year = $rs_column->max; #returns latest year

See F<t/resultset/get_column_max.t> for a runnable example of the scalar
aggregate return shown above (and F<t/resultset/as_query.t> for the
C<< ->as_query >>/C<*_rs> resultset builders).

=head1 DESCRIPTION

L<DBIO::ResultSetColumn> is the helper object returned by
L<DBIO::ResultSet/get_column>. It lets you run column-oriented operations such
as aggregates or value iteration without fetching full row objects.

=head1 METHODS

=head2 new

  my $obj = DBIO::ResultSetColumn->new($rs, $column);

Creates a new resultset column object from the resultset and column
passed as params. Used internally by L<DBIO::ResultSet/get_column>.

=head2 new

=head2 next

=head2 all

=head2 reset

=head2 first

=head2 single

=head2 single_async

=head2 all_async

=head2 min

=head2 min_async

=head2 max

=head2 max_async

=head2 sum

=head2 sum_async

=head2 func

=head2 func_rs

=head2 func_async

=head2 with_context

    $rs->get_column($col)->with_context($ctx)->all_async;

Returns a clone of this column resultset bound to a pinned async context --
the object handed to a L<DBIO::Storage::Async/txn_do_async> or C<pipeline>
coderef. Once bound, every C<*_async> method on the clone routes onto the
context's pinned connection instead of the pool. See
L<DBIO::ResultSet/with_context> for the full picture; a column resultset
inherits this binding automatically when produced by C<get_column> or
C<count_rs> on a context-bound resultset.

The resultsets a bound column hands out -- L</func_rs>, L</min_rs>, L</max_rs>
and L</sum_rs> -- are bound too, however the column came by its binding. The
column C<with_context> is called on is left as it was.

In the C<immediate> mode the context C<txn_do_async> hands its coderef is the
storage itself, and C<with_context> takes it; see
L<DBIO::ResultSet/with_context> for what is particular to that mode.

=head2 throw_exception

=head2 _resultset

=head1 ASYNC

L</single_async>, L</all_async>, L</min_async>, L</max_async>, L</sum_async>
and L</func_async> mirror their synchronous counterparts, requiring an async
connection (C<< connect(..., { async => ... }) >>, see L<DBIO::ResultSet/ASYNC>
for the full three-way live-backend/C<immediate>/croak contract shared by
every DBIO C<*_async> method). C<single_async>/C<all_async> route through the
same backend calls L<DBIO::ResultSet/single_async>/L<DBIO::ResultSet/all_async>
use, one tier down; C<min_async>/C<max_async>/C<sum_async>/C<func_async> route
the aggregate through C<func_rs> and the backend's C<select_single_async>,
bypassing the cursor. One asymmetry worth knowing: if C<func_rs> ends up
selecting more than one row (e.g. a C<func_async> call over a resultset with
a C<group_by>, so the "aggregate" is really one value per group),
C<select_single_async> carps C<"Query returned more than one row...
DEPRECATED for -E<gt>find and -E<gt>single"> -- naming the wrong methods, since
it's a shared warning from the storage layer, not written for
C<min_async>/C<max_async>/C<sum_async>/C<func_async>. The synchronous
C<func()> has no such warning in this situation: it reads exactly one row off
the cursor (C<< ($cursor->next)[0] >>) and silently ignores the rest.

L</next>, L</first> and L</reset> have no async twin: they iterate a cursor,
and there is no async cursor iteration yet -- the same gap ADR 0031 already
documents for L<DBIO::ResultSet/first_async>'s own over-fetch. This gap
does not limit C<func_async>, though: C<func> always returns a single
scalar (L</func>), never a per-row list, so its async twin covers it
completely.

=head2 as_query

=over 4

=item Arguments: none

=item Return Value: \[ $sql, L<@bind_values|DBIO::ResultSet/DBIO BIND VALUES> ]

=back

Returns the SQL query and bind vars associated with the invocant.

This is generally used as the RHS for a subquery.

=head2 next

=over 4

=item Arguments: none

=item Return Value: $value

=back

Returns the next value of the column in the resultset (or C<undef> if
there is none).

Much like L<DBIO::ResultSet/next> but just returning the
one value.

=head2 all

=over 4

=item Arguments: none

=item Return Value: @values

=back

Returns all values of the column in the resultset (an empty list if
there are none).

Much like L<DBIO::ResultSet/all> but returns values rather
than result objects.

=head2 reset

=over 4

=item Arguments: none

=item Return Value: $self

=back

Resets the underlying resultset's cursor, so you can iterate through the
elements of the column again.

Much like L<DBIO::ResultSet/reset>.

=head2 first

=over 4

=item Arguments: none

=item Return Value: $value

=back

Resets the underlying resultset and returns the next value of the column in the
resultset (or C<undef> if there is none).

Much like L<DBIO::ResultSet/first> but just returning the one value.

=head2 single

=over 4

=item Arguments: none

=item Return Value: $value

=back

Much like L<DBIO::ResultSet/single> fetches one and only one column
value using the cursor directly. If additional rows are present a warning
is issued before discarding the cursor.

=head2 single_async

  my $future = $rs_column->single_async;

Async variant of L</single>. Requires an async connection (C<< connect(...,
{ async => ... }) >>); on a sync instance it croaks. In the C<immediate> mode
it runs synchronously and resolves immediately. See ADR 0030/0031.

=head2 all_async

  my $future = $rs_column->all_async;
  $future->then(sub { my @values = @_; ... });

Async variant of L</all>. Requires an async connection (C<< connect(...,
{ async => ... }) >>); on a sync instance it croaks. In the C<immediate> mode
it runs synchronously and resolves immediately. See ADR 0030/0031.

=head2 min

=over 4

=item Arguments: none

=item Return Value: $lowest_value

=back

  my $first_year = $year_col->min();

Wrapper for ->func. Returns the lowest value of the column in the
resultset (or C<undef> if there are none).

=head2 min_rs

=over 4

=item Arguments: none

=item Return Value: L<$resultset|DBIO::ResultSet>

=back

  my $rs = $year_col->min_rs();

Wrapper for ->func_rs for function MIN().

=head2 min_async

  my $future = $year_col->min_async;

Async variant of L</min>. Routes the aggregate through C<func_rs('MIN')> and
the backend's C<select_single_async> (the same shape L</single_async> uses),
rather than through a cursor. Requires an async connection; on a sync instance
it croaks. In the C<immediate> mode it runs synchronously and resolves
immediately. See ADR 0030/0031.

=head2 max

=over 4

=item Arguments: none

=item Return Value: $highest_value

=back

  my $last_year = $year_col->max();

Wrapper for ->func. Returns the highest value of the column in the
resultset (or C<undef> if there are none).

=head2 max_rs

=over 4

=item Arguments: none

=item Return Value: L<$resultset|DBIO::ResultSet>

=back

  my $rs = $year_col->max_rs();

Wrapper for ->func_rs for function MAX().

=head2 max_async

  my $future = $year_col->max_async;

Async variant of L</max>. Routes the aggregate through C<func_rs('MAX')> and
the backend's C<select_single_async> (the same shape L</single_async> uses),
rather than through a cursor. Requires an async connection; on a sync instance
it croaks. In the C<immediate> mode it runs synchronously and resolves
immediately. See ADR 0030/0031.

=head2 sum

=over 4

=item Arguments: none

=item Return Value: $sum_of_values

=back

  my $total = $prices_col->sum();

Wrapper for ->func. Returns the sum of all the values in the column of
the resultset. Use on varchar-like columns at your own risk.

=head2 sum_rs

=over 4

=item Arguments: none

=item Return Value: L<$resultset|DBIO::ResultSet>

=back

  my $rs = $year_col->sum_rs();

Wrapper for ->func_rs for function SUM().

=head2 sum_async

  my $future = $prices_col->sum_async;

Async variant of L</sum>. Routes the aggregate through C<func_rs('SUM')> and
the backend's C<select_single_async> (the same shape L</single_async> uses),
rather than through a cursor. Requires an async connection; on a sync instance
it croaks. In the C<immediate> mode it runs synchronously and resolves
immediately. See ADR 0030/0031.

=head2 func

=over 4

=item Arguments: $function

=item Return Value: $function_return_value

=back

  $rs = $schema->resultset("CD")->search({});
  $length = $rs->get_column('title')->func('LENGTH');

Runs a query using the function on the column and returns the
value. Produces the following SQL:

  SELECT LENGTH( title ) FROM cd me

The function name is an identifier, optionally schema-qualified
(C<LENGTH>, C<pg_catalog.max>); any other name throws. Write an expression
as a literal in C<select> (C<\'...'> or C<\[ ... ]>).

=head2 func_rs

=over 4

=item Arguments: $function

=item Return Value: L<$resultset|DBIO::ResultSet>

=back

Creates the resultset that C<func()> uses to run its query. The function name is an
identifier as described at L</func>. A binding made
with L</with_context> goes with it.

=head2 func_async

  my $future = $rs_column->func_async('LENGTH');

Async variant of L</func>. Routes the aggregate through C<func_rs($function)>
and the backend's C<select_single_async>, exactly like L</min_async>,
L</max_async> and L</sum_async>. Like L</func> it returns the single scalar
value the aggregate produces; there is no per-row list variant to mirror.

Requires an async connection; on a sync instance it croaks. In the
C<immediate> mode it runs synchronously and resolves immediately. See ADR
0030/0031.

=head2 throw_exception

See L<DBIO::Schema/throw_exception> for details.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
