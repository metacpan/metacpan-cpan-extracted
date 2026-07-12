package DBIO::Ordered;
# ABSTRACT: Maintain a position column over an ordered list of rows

use strict;
use warnings;
use base qw( DBIO::Base );

sub add_columns {
  my ($self, @cols) = @_;
  my @columns;

  while (my $col = shift @cols) {
    my $info = ref $cols[0] ? shift @cols : {};

    if (delete $info->{position}) {
      $info->{_ordered_position} = 1;
    }
    if (delete $info->{grouping}) {
      $info->{_ordered_grouping} = 1;
    }
    if (exists $info->{null_position_value}) {
      $info->{_ordered_null_position_value} = delete $info->{null_position_value};
    }

    push @columns, $col => $info;
  }

  return $self->next::method(@columns);
}


sub position_column {
  my $self = shift;
  my $source = ref $self
    ? $self->result_source
    : $self->result_source_instance;
  my $info = $source->columns_info;
  for my $col (sort keys %$info) {
    return $col if $info->{$col}{_ordered_position};
  }
  $self->throw_exception(
    "No position column defined on " . (ref $self || $self) .
    " -- mark a column with `position => 1` in add_columns"
  );
}


sub grouping_column {
  my $self = shift;
  my $source = ref $self
    ? $self->result_source
    : $self->result_source_instance;
  my $info = $source->columns_info;
  my @group = sort grep { $info->{$_}{_ordered_grouping} } keys %$info;
  return undef if !@group;
  return $group[0] if @group == 1;
  return \@group;
}


sub null_position_value {
  my $self = shift;
  my $pos_col = $self->position_column;
  my $col_info = $self->result_source->columns_info->{$pos_col};
  return exists $col_info->{_ordered_null_position_value}
    ? $col_info->{_ordered_null_position_value}
    : 0;
}


sub siblings {
  my $self = shift;
  return $self->_siblings->search({}, { order_by => $self->position_column });
}


sub previous_siblings {
  my $self = shift;
  my $position_column = $self->position_column;
  my $position = $self->get_column($position_column);
  return ( defined $position
    ? $self->_siblings->search({ $position_column => { '<', $position } })
    : $self->_siblings
  );
}


sub next_siblings {
  my $self = shift;
  my $position_column = $self->position_column;
  my $position = $self->get_column($position_column);
  return ( defined $position
    ? $self->_siblings->search({ $position_column => { '>', $position } })
    : $self->_siblings
  );
}


sub previous_sibling {
  my $self = shift;
  my $position_column = $self->position_column;
  my $psib = $self->previous_siblings->search(
    {}, { rows => 1, order_by => { '-desc' => $position_column } },
  )->single;
  return defined $psib ? $psib : 0;
}


sub first_sibling {
  my $self = shift;
  my $position_column = $self->position_column;
  my $fsib = $self->previous_siblings->search(
    {}, { rows => 1, order_by => { '-asc' => $position_column } },
  )->single;
  return defined $fsib ? $fsib : 0;
}


sub next_sibling {
  my $self = shift;
  my $position_column = $self->position_column;
  my $nsib = $self->next_siblings->search(
    {}, { rows => 1, order_by => { '-asc' => $position_column } },
  )->single;
  return defined $nsib ? $nsib : 0;
}


sub last_sibling {
  my $self = shift;
  my $position_column = $self->position_column;
  my $lsib = $self->next_siblings->search(
    {}, { rows => 1, order_by => { '-desc' => $position_column } },
  )->single;
  return defined $lsib ? $lsib : 0;
}

sub _last_sibling_posval {
  my $self = shift;
  my $position_column = $self->position_column;

  my $cursor = $self->next_siblings->search(
    {}, { rows => 1, order_by => { '-desc' => $position_column }, select => $position_column },
  )->cursor;

  my ($pos) = $cursor->next;
  return $pos;
}


sub move_previous {
  my $self = shift;
  return $self->move_to($self->_position - 1);
}


sub move_next {
  my $self = shift;
  return 0 unless defined $self->_last_sibling_posval;
  return $self->move_to($self->_position + 1);
}


sub move_first { return shift->move_to(1) }


sub move_last {
  my $self = shift;
  my $last_posval = $self->_last_sibling_posval;
  return 0 unless defined $last_posval;
  return $self->move_to($self->_position_from_value($last_posval));
}


sub move_to {
  my ($self, $to_position) = @_;
  return 0 if ($to_position < 1);

  my $position_column = $self->position_column;

  my $is_txn;
  if ($is_txn = $self->result_source->schema->storage->transaction_depth) {
    $self->store_column(
      $position_column,
      ( $self->result_source
              ->resultset
               ->search($self->_storage_ident_condition, { rows => 1, columns => $position_column })
                ->cursor
                 ->next
      )[0] || $self->throw_exception(
        sprintf "Unable to locate object '%s' in storage - object went ouf of sync...?",
        $self->ID
      ),
    );
    delete $self->{_dirty_columns}{$position_column};
  }
  elsif ($self->is_column_changed($position_column)) {
    $self->store_column($position_column, delete $self->{_column_data_in_storage}{$position_column});
    delete $self->{_dirty_columns}{$position_column};
  }

  my $from_position = $self->_position;

  if ($from_position == $to_position) {
    return 0;
  }

  my $guard = $is_txn ? undef : $self->result_source->schema->txn_scope_guard;

  my ($direction, @between);
  if ($from_position < $to_position) {
    $direction = -1;
    @between = map { $self->_position_value($_) } ($from_position + 1, $to_position);
  }
  else {
    $direction = 1;
    @between = map { $self->_position_value($_) } ($to_position, $from_position - 1);
  }

  my $new_pos_val = $self->_position_value($to_position);

  if (grep { $_ eq $position_column } (map { @$_ } values %{{ $self->result_source->unique_constraints }})) {
    $self->_ordered_internal_update({ $position_column => $self->null_position_value });
  }

  $self->_shift_siblings($direction, @between);
  $self->_ordered_internal_update({ $position_column => $new_pos_val });

  $guard->commit if $guard;
  return 1;
}


sub move_to_group {
  my ($self, $to_group, $to_position) = @_;

  unless (ref $to_group eq 'HASH') {
    my @gcols = $self->_grouping_columns;
    $self->throw_exception('Single group supplied for a multi-column group identifier') if @gcols > 1;
    $to_group = { $gcols[0] => $to_group };
  }

  my $position_column = $self->position_column;

  return 0 if (defined($to_position) and $to_position < 1);

  for ($self->_grouping_columns) {
    if ($self->is_column_changed($_)) {
      $self->store_column($_, delete $self->{_column_data_in_storage}{$_});
      delete $self->{_dirty_columns}{$_};
    }
  }

  if ($self->_is_in_group($to_group)) {
    my $ret;
    if (defined $to_position) {
      $ret = $self->move_to($to_position);
    }
    return $ret || 0;
  }

  my $guard = $self->result_source->schema->txn_scope_guard;

  $self->move_last;

  $self->set_inflated_columns({ %$to_group, $position_column => undef });
  my $new_group_last_posval = $self->_last_sibling_posval;
  my $new_group_last_position = $self->_position_from_value($new_group_last_posval);

  if (not defined($to_position) or $to_position > $new_group_last_position) {
    $self->set_column(
      $position_column => $new_group_last_position
        ? $self->_next_position_value($new_group_last_posval)
        : $self->_initial_position_value
    );
  }
  else {
    my $bumped_pos_val = $self->_position_value($to_position);
    my @between = map { $self->_position_value($_) } ($to_position, $new_group_last_position);
    $self->_shift_siblings(1, @between);
    $self->set_column($position_column => $bumped_pos_val);
  }

  $self->_ordered_internal_update;
  $guard->commit;
  return 1;
}


sub insert {
  my $self = shift;
  my $position_column = $self->position_column;

  unless ($self->get_column($position_column)) {
    my $lsib_posval = $self->_last_sibling_posval;
    $self->set_column(
      $position_column => (defined $lsib_posval
        ? $self->_next_position_value($lsib_posval)
        : $self->_initial_position_value
      )
    );
  }

  return $self->next::method(@_);
}


sub update {
  my $self = shift;

  return $self->next::method(@_) if $self->result_source->schema->{_ORDERED_INTERNAL_UPDATE};

  my $upd = shift;
  $self->set_inflated_columns($upd) if $upd;

  my $position_column = $self->position_column;
  my @group_columns = $self->_grouping_columns;

  my $changed_ordering_cols = { map { $_ => $self->get_column($_) } grep { $self->is_column_changed($_) } ($position_column, @group_columns) };

  if (! keys %$changed_ordering_cols) {
    return $self->next::method(undef, @_);
  }
  elsif (grep { exists $changed_ordering_cols->{$_} } @group_columns) {
    $self->move_to_group(
      { $self->_grouping_clause },
      (exists $changed_ordering_cols->{$position_column}
        ? $changed_ordering_cols->{$position_column}
        : $self->_position
      ),
    );
  }
  else {
    $self->move_to($changed_ordering_cols->{$position_column});
  }

  return $self;
}


sub delete {
  my $self = shift;
  my $guard = $self->result_source->schema->txn_scope_guard;
  $self->move_last;
  $self->next::method(@_);
  $guard->commit;
  return $self;
}

sub _track_storage_value {
  my ($self, $col) = @_;
  return (
    $self->next::method($col)
      ||
    grep { $_ eq $col } ($self->position_column, $self->_grouping_columns)
  );
}


sub _position_from_value {
  my ($self, $val) = @_;
  return 0 unless defined $val;
  return $val;
}


sub _position_value {
  my ($self, $pos) = @_;
  return $pos;
}


__PACKAGE__->mk_classdata('_initial_position_value' => 1);


sub _next_position_value { return $_[1] + 1 }


sub _shift_siblings {
  my ($self, $direction, @between) = @_;
  return 0 unless $direction;

  my $position_column = $self->position_column;

  my ($op, $ord);
  if ($direction < 0) { $op = '-'; $ord = 'asc'  }
  else                { $op = '+'; $ord = 'desc' }

  my $shift_rs = $self->_group_rs->search({ $position_column => { -between => \@between } });

  my $rsrc = $self->result_source;
  local $rsrc->schema->{_ORDERED_INTERNAL_UPDATE} = 1;
  my @pcols = $rsrc->primary_columns;

  if (grep { $_ eq $position_column } (map { @$_ } values %{{ $rsrc->unique_constraints }})) {
    my $clean_rs = $rsrc->resultset;
    for ($shift_rs->search(
      {}, { order_by => { "-$ord", $position_column }, select => [$position_column, @pcols] }
    )->cursor->all) {
      my $pos = shift @$_;
      $clean_rs->find(@$_)->update({ $position_column => $pos + (($op eq '+') ? 1 : -1) });
    }
  }
  else {
    $shift_rs->update({ $position_column => \"$position_column $op 1" });
  }
}

sub _group_rs {
  my $self = shift;
  return $self->result_source->resultset->search({ $self->_grouping_clause });
}

sub _siblings {
  my $self = shift;
  my $position_column = $self->position_column;
  my $pos;
  return defined($pos = $self->get_column($position_column))
    ? $self->_group_rs->search({ $position_column => { '!=' => $pos } })
    : $self->_group_rs;
}

sub _position {
  my $self = shift;
  return $self->_position_from_value($self->get_column($self->position_column));
}

sub _grouping_clause {
  my ($self) = @_;
  return map { $_ => $self->get_column($_) } $self->_grouping_columns;
}

sub _grouping_columns {
  my ($self) = @_;
  my $col = $self->grouping_column;
  if (ref $col eq 'ARRAY')   { return @$col }
  elsif (defined $col)       { return ($col) }
  else                       { return ()    }
}

sub _is_in_group {
  my ($self, $other) = @_;
  my $current = { $self->_grouping_clause };

  no warnings qw/uninitialized/;

  return 0 if (
    join("\x00", sort keys %$current) ne join("\x00", sort keys %$other)
  );
  for my $key (keys %$current) {
    return 0 if $current->{$key} ne $other->{$key};
  }
  return 1;
}

sub _ordered_internal_update {
  my $self = shift;
  local $self->result_source->schema->{_ORDERED_INTERNAL_UPDATE} = 1;
  return $self->update(@_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Ordered - Maintain a position column over an ordered list of rows

=head1 VERSION

version 0.900001

=head1 SYNOPSIS

  package MyApp::Schema::Result::Item;
  use base 'DBIO::Core';

  __PACKAGE__->load_components(qw/Ordered/);
  __PACKAGE__->table('items');
  __PACKAGE__->add_columns(
    item_id  => { data_type => 'integer', is_auto_increment => 1 },
    name     => { data_type => 'varchar', size => 100 },
    position => { data_type => 'integer', position => 1 },
  );
  __PACKAGE__->set_primary_key('item_id');

With one or more grouping columns for independent ordered lists per group:

  __PACKAGE__->add_columns(
    item_id  => { data_type => 'integer', is_auto_increment => 1 },
    name     => { data_type => 'varchar', size => 100 },
    position => { data_type => 'integer', position => 1 },
    group_id => { data_type => 'integer', grouping => 1 },
  );

In code:

  my $rs       = $item->siblings;
  my $sibling  = $item->first_sibling;
  $item->move_previous;
  $item->move_next;
  $item->move_first;
  $item->move_last;
  $item->move_to($position);
  $item->move_to_group('groupname');
  $item->move_to_group('groupname', $position);
  $item->move_to_group({ group_id => 'a', other_group_id => 'b' }, $position);

See F<t/ordered.t> for a runnable example of the core moves against the
shared L<DBIO::Test::Schema::Employee> fixture (mock storage can verify
the emitted SQL and the invoking row's own position change, but not a
full multi-row persisted reorder -- see the caveat in that file).

=head1 DESCRIPTION

Maintains a position column over an ordered list of rows. Mark the
position column with C<< position =E<gt> 1 >> in C<add_columns>; mark
zero or more grouping columns with C<< grouping =E<gt> 1 >> to maintain
independent ordered lists within the same table.

The C<move_*> methods automatically update sibling rows to keep the
order contiguous. This is not configurable -- moving one row in an
ordered list always shifts others.

=head1 ATTRIBUTES

=head2 _initial_position_value

  __PACKAGE__->_initial_position_value(0);

Position value assigned to the first row of a group when no value is
supplied. Defaults to C<1>.

=head1 METHODS

=head2 position_column

  my $col = $self->position_column;

Returns the name of the column flagged with C<< position =E<gt> 1 >>.
Throws if no such column is defined on the result source.

=head2 grouping_column

  my $col_or_aref = $self->grouping_column;

Returns the column (or arrayref of columns) flagged with
C<< grouping =E<gt> 1 >>. Returns a single scalar when exactly one column
is flagged, an arrayref when multiple are flagged, and C<undef> when no
grouping is configured.

=head2 null_position_value

  my $val = $self->null_position_value;

Returns the value used as a placeholder while a row is being moved, so
unique constraints involving the position column are not violated.
Reads from the C<null_position_value> flag on the position column;
defaults to C<0>.

=head2 siblings

  my $rs = $item->siblings;

Returns an ordered resultset of all other rows in the same group,
excluding the row this was called on.

=head2 previous_siblings

  my $rs = $item->previous_siblings;

Returns a resultset of all rows in the same group positioned before
this one.

=head2 next_siblings

  my $rs = $item->next_siblings;

Returns a resultset of all rows in the same group positioned after
this one.

=head2 previous_sibling

Returns the row one position before this one, or 0 if this is the first.

=head2 first_sibling

Returns the first row in the group, or 0 if this is the first.

=head2 next_sibling

Returns the row one position after this one, or 0 if this is the last.

=head2 last_sibling

Returns the last row in the group, or 0 if this is the last.

=head2 move_previous

Swaps with the sibling one position before this one. Returns 1 on
success, 0 if already first.

=head2 move_next

Swaps with the sibling one position after this one. Returns 1 on
success, 0 if already last.

=head2 move_first

Moves to the first position. Returns 1 on success, 0 if already first.

=head2 move_last

Moves to the last position. Returns 1 on success, 0 if already last.

=head2 move_to

  $item->move_to($position);

Moves to the specified position. Returns 1 on success, 0 if already
at that position.

=head2 move_to_group

  $item->move_to_group($group, $position);

Moves to the specified position of the specified group, or to the end
of the group if C<$position> is C<undef>. Returns 1 on success, 0 if
already at that position. C<$group> may be a single scalar (when only
one grouping column is in use) or a hashref of column => value pairs.

=head2 insert

Assigns a default position (one past the current last sibling) when the
position column has no value set.

=head2 update

If the position or grouping columns changed, performs the move via
L</move_to> or L</move_to_group> to keep siblings consistent.

=head2 delete

Moves to the last position before deleting, keeping the order tree
contiguous.

=head2 _position_from_value

  my $num_pos = $item->_position_from_value($pos_value);

Returns the absolute numeric position of a row given a raw position
value. Default: returns C<$pos_value> unchanged.

=head2 _position_value

  my $pos_value = $item->_position_value($pos);

Returns the value of L</position_column> for the row at numeric
position C<$pos>. Default: returns C<$pos> unchanged.

=head2 _next_position_value

  my $new_value = $item->_next_position_value($position_value);

Returns the next position value after C<$position_value>. Default:
C<$position_value + 1>.

=head2 _shift_siblings

  $item->_shift_siblings($direction, @between);

Shifts all siblings whose position values fall within the inclusive
range C<@between> by one position in the given direction (left if
C<E<lt> 0>, right if C<E<gt> 0>). Handles unique-constraint cases by
falling back to a one-by-one update.

=head1 COLUMN FLAGS

=over 4

=item C<< position =E<gt> 1 >>

Marks the column that stores the integer position of each row.

=item C<< grouping =E<gt> 1 >>

Marks a column as a grouping key. Multiple columns may be flagged --
in that case all of them must match for two rows to be considered
siblings.

=item C<< null_position_value =E<gt> $value >>

Set on the position column. Specifies the placeholder value used while
a row is mid-move, so unique constraints involving the position column
are not violated. Defaults to C<0>; set to C<undef> if your positions
start at 0.

=back

=head1 OVERRIDABLE METHODS

Override these in your Result class if you use sparse (non-linear) or
non-numeric position values, e.g. when working with materialized path
columns.

=over 4

=item C<_position_from_value($value)>

Maps a stored position value to an absolute numeric position. Default:
identity.

=item C<_position_value($position)>

Inverse of the above. Default: identity.

=item C<_next_position_value($value)>

Returns the next position value after C<$value>. Default: C<$value + 1>.

=item C<_initial_position_value>

Class data with the position value used for the first row of a group.
Defaults to C<1>.

=back

=head1 CAVEATS

=head2 Resultset methods

All insert/create/delete overrides happen on L<DBIO::Row>. If you use
the L<DBIO::ResultSet> versions of C<update> or C<delete>, all logic
in this component is bypassed. Use C<update_all> / C<delete_all>
instead -- they invoke the row method on every member.

=head2 Race condition on insert

If no position is supplied at insert time, one is chosen based on
L</_initial_position_value> or L</_next_position_value>. The window
between select and insert introduces a race. Add unique constraints on
the position/group columns and use transactions to prevent silent
corruption.

=head2 Multiple moves

When multiple same-group rows are loaded from storage, C<move_*>
operations on them can drift out of sync with the underlying storage.
Wrapping in a transaction triggers an implicit reload; otherwise call
L<DBIO::Row/discard_changes> to refresh.

=head2 Default values

Database-side default values on grouping columns can result in
incorrect position assignment.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
