package DBIO::ResultSetColumn;
# ABSTRACT: Convenience wrapper for working with a single ResultSet column

use strict;
use warnings;

use base 'DBIO::Base';
use DBIO::Carp;
use DBIO::Util qw(fail_on_internal_wantarray assert_no_internal_wantarray);
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
    _parent_resultset => $new_parent_rs
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



sub min {
  return shift->func('MIN');
}


sub min_rs { return shift->func_rs('MIN') }



sub max {
  return shift->func('MAX');
}


sub max_rs { return shift->func_rs('MAX') }



sub sum {
  return shift->func('SUM');
}


sub sum_rs { return shift->func_rs('SUM') }



sub func {
  my ($self,$function) = @_;
  my $cursor = $self->func_rs($function)->cursor;

  if( wantarray ) {
    assert_no_internal_wantarray and my $sog = fail_on_internal_wantarray;
    return map { $_->[ 0 ] } $cursor->all;
  }

  return ( $cursor->next )[ 0 ];
}



sub func_rs {
  my ($self,$function) = @_;

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

version 0.900002

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

=head2 min

=head2 max

=head2 sum

=head2 func

=head2 func_rs

=head2 throw_exception

=head2 _resultset

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

Returns all values of the column in the resultset (or C<undef> if
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

=head2 func_rs

=over 4

=item Arguments: $function

=item Return Value: L<$resultset|DBIO::ResultSet>

=back

Creates the resultset that C<func()> uses to run its query.

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
