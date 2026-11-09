package DBIO::MySQL::SQLMaker;
# ABSTRACT: MySQL-specific SQL generation for DBIO

use warnings;
use strict;

our $VERSION = '0.900004';

use base qw( DBIO::SQLMaker );

use Text::Balanced ();
use DBIO::Util qw( is_literal_value );


sub new {
  my $self = shift->next::method(@_);

  # copy first: the table of render ops may be shared with other makers
  $self->{render_op} = {
    %{ $self->{render_op} },
    nulls_first => '_render_op_nulls',
    nulls_last  => '_render_op_nulls',
  };

  return $self;
}


sub _render_op_nulls {
  my ($self, $op, $args) = @_;
  my ($node) = @$args;

  my $expr = $node;
  if (ref $node eq 'HASH' and ref $node->{-op} eq 'ARRAY'
      and $node->{-op}[0] =~ /\A(?:asc|desc)\z/) {
    $expr = $node->{-op}[1];
  }

  return $self->join_query_parts(', ',
    { -op => [ ( $op eq 'nulls_first' ? 'desc' : 'asc' ),
               { -op => [ 'is_null', $expr ] } ] },
    $node,
  );
}


sub apply_limit {
    my ( $self, $sql, $rs_attrs, $rows, $offset ) = @_;
    $sql .= $self->_parse_rs_attrs( $rs_attrs ) . " LIMIT ";
    if ($offset) {
      $sql .= '?, ';
      push @{$self->{limit_bind}}, [ $self->__offset_bindtype => $offset ];
    }
    $sql .= '?';
    push @{$self->{limit_bind}}, [ $self->__rows_bindtype => $rows ];

    return $sql;
}

#
# MySQL does not understand the standard INSERT INTO $table DEFAULT VALUES
# Adjust SQL here instead
#
sub insert {
  my $self = shift;
  my ($table, $data, $options) = @_;

  my $have_options = ref $options eq 'HASH';

  # ADR 0036: $options->{on_conflict} is the atomic-upsert transport, and
  # consuming (deleting) it is part of the contract -- the generic
  # DBIO::SQLMaker::ClassicExtensions::insert throws when it still sees the
  # key, because a clause it cannot place must never be silently dropped
  # from the statement.
  my $on_conflict = $have_options ? delete $options->{on_conflict} : undef;

  # RETURNING is held back over the call to the base for the same reason: it
  # is the LAST tail of the statement, and the conflict clause goes before it
  # (ADR 0036 section 2, trap 1). So the statement is assembled here in
  # grammar order rather than appended to whatever the base produced.
  # MariaDB 10.5+ is the only server in this driver's reach that has
  # RETURNING at all (see DBIO::MySQL::Storage/_determine_supports_insert_returning).
  my $returning = $have_options ? delete $options->{returning} : undef;

  my ($sql, @bind);
  if (! $data or (ref $data eq 'HASH' and ! keys %$data) ) {
    $sql = 'INSERT INTO ' . $self->_quote($table) . ' () VALUES ()';
  }
  else {
    ($sql, @bind) = $self->next::method($table, $data, $options);
  }

  # Put it back before anything else can happen: DBIO::Storage::DBI::insert
  # reads $options->{returning} AGAIN after _execute, to decide whether to
  # fetch the returned row off the statement handle. A key that stays deleted
  # yields perfectly correct SQL whose result is never collected -- and it
  # looks like an identity problem rather than a plumbing one (ADR 0036
  # section 2, trap 2).
  $options->{returning} = $returning if defined $returning;

  if ($on_conflict) {
    my ($tail, @tail_bind) = $self->_insert_on_conflict($on_conflict, $data);
    $sql .= $tail;
    push @bind, @tail_bind;
  }

  if (defined $returning) {
    my ($tail, @tail_bind) = $self->_insert_returning($options);
    $sql .= $tail;
    push @bind, @tail_bind;
  }

  return ($sql, @bind);
}



sub _insert_row_alias { $_[0]->{_upsert_row_alias} }


sub _insert_on_conflict {
  my ($self, $on_conflict, $data) = @_;

  my $action   = $on_conflict->{action} || 'update';
  my $identity = $on_conflict->{identity_column};
  my $alias    = $self->_insert_row_alias;

  my (@assignments, @bind, $alias_used);

  # LAST_INSERT_ID(<pk>) is a no-op on the stored value; its only purpose is
  # to make LAST_INSERT_ID() report the primary key of the row the statement
  # actually touched -- insert or update, regardless of which unique index
  # collided (ADR 0036 section 4, rule 3).
  my $identity_assignment = defined $identity
    ? $self->_quote($identity) . ' = LAST_INSERT_ID(' . $self->_quote($identity) . ')'
    : undef;

  if ($action eq 'nothing') {
    if (defined $identity_assignment) {
      # the no-op set and the identity channel are the same assignment here
      push @assignments, $identity_assignment;
    }
    else {
      my $col = $on_conflict->{noop_column}
             // $self->_insert_on_conflict_noop_column($on_conflict, $data);

      $self->throw_exception(
        "Cannot emulate ON CONFLICT DO NOTHING on MySQL: there is no column "
      . 'to assign to itself. ON DUPLICATE KEY UPDATE requires at least one '
      . 'assignment.'
      ) unless defined $col;

      push @assignments, $self->_quote($col) . ' = ' . $self->_quote($col);
    }
  }
  else {
    my $set = $on_conflict->{set} || {};

    for my $col (sort keys %$set) {
      my ($expr, $used_alias, @expr_bind)
        = $self->_insert_on_conflict_value($col, $set->{$col}, $alias);

      push @assignments, $self->_quote($col) . ' = ' . $expr;
      push @bind, @expr_bind;
      $alias_used ||= $used_alias;
    }

    push @assignments, $identity_assignment if defined $identity_assignment;
  }

  $self->throw_exception(
    'ON DUPLICATE KEY UPDATE requires at least one assignment, but the '
  . 'conflict set is empty'
  ) unless @assignments;

  my $tail = '';
  # the row alias is introduced in the statement itself, right after the
  # VALUES clause; L</insert> appends this whole tail before RETURNING, which
  # is where the two would otherwise collide (they never do in practice --
  # the alias is MySQL 8.0.20+, RETURNING is MariaDB, no server has both)
  $tail .= ' AS ' . $self->_quote($alias) if $alias_used;
  $tail .= ' ON DUPLICATE KEY UPDATE ' . join(', ', @assignments);

  return ($tail, @bind);
}

# One conflict-set assignment. Returns the right-hand side, whether it used
# the row alias, and any binds it needs.
sub _insert_on_conflict_value {
  my ($self, $col, $value, $alias) = @_;

  if (ref $value eq 'HASH' and keys %$value == 1 and exists $value->{-attempted}) {
    my $attempted = $value->{-attempted};

    return ($self->_quote($alias) . '.' . $self->_quote($attempted), 1)
      if defined $alias;

    return ('VALUES(' . $self->_quote($attempted) . ')', 0);
  }

  if (my $literal = is_literal_value($value)) {
    my ($sql, @literal_bind) = @$literal;
    return ($sql, 0, @literal_bind);
  }

  return ('?', 0, $self->_bindtype($col, $value));
}

# The column the DO NOTHING emulation assigns to itself when the storage did
# not name one (a maker driven directly, without a ResultSource behind it).
sub _insert_on_conflict_noop_column {
  my ($self, $on_conflict, $data) = @_;

  my $target = $on_conflict->{target};
  return $target->[0] if ref $target eq 'ARRAY' and @$target;

  return (sort keys %$data)[0] if ref $data eq 'HASH' and keys %$data;

  return undef;
}

# Allow STRAIGHT_JOIN's
sub _generate_join_clause {
    my ($self, $join_type) = @_;

    if( $join_type && $join_type =~ /^STRAIGHT\z/i ) {
        return ' STRAIGHT_JOIN '
    }

    return $self->next::method($join_type);
}

sub _wrap_self_referencing_subquery {
  my ($self, $sql, $target_name) = @_;

  return $sql unless $target_name;

  my $re = qr/ (?<!DELETE) [\s\)] (?: FROM | JOIN ) \s (?: \` \Q$target_name\E \` | \Q$target_name\E ) [\s\(] /xi;

  return $sql unless $sql =~ $re;

  my $new_sql;
  while (1) {

    my ($prefix, $parenthesized);

    ($parenthesized, $sql, $prefix) = do {
      # idiotic design - writes to $@ but *DOES NOT* throw exceptions
      local $@;
      Text::Balanced::extract_bracketed( $sql, '()', qr/[^\(]*/ );
    };

    # this is how an error is indicated, in addition to crapping in $@
    last unless $parenthesized;

    if ($parenthesized =~ $re) {
      # is this a select subquery?
      if ( $parenthesized =~ /^ \( \s* SELECT \s+ /xi ) {
        $parenthesized = "( SELECT * FROM $parenthesized `_forced_double_subquery` )";
      }
      # then drill down until we find it (if at all)
      else {
        $parenthesized =~ s/^ \( (.+) \) $/$1/x;
        $parenthesized = join ' ', '(', $self->_wrap_self_referencing_subquery( $parenthesized, $target_name ), ')';
      }
    }

    $new_sql .= $prefix . $parenthesized;
  }

  return $new_sql . $sql;
}

sub update {
  my $self = shift;
  my ($target, $source, $attributes) = @_;

  my ($sql, @bind) = $self->next::method(@_);

  # Extract target table name for self-referencing detection
  my $target_name = $self->_extract_target_name($target);

  $sql = $self->_wrap_self_referencing_subquery($sql, $target_name) if $target_name;

  return ($sql, @bind);
}

sub delete {
  my $self = shift;
  my ($target, $source, $attributes) = @_;

  my ($sql, @bind) = $self->next::method(@_);

  # Extract target table name for self-referencing detection
  my $target_name = $self->_extract_target_name($target);

  $sql = $self->_wrap_self_referencing_subquery($sql, $target_name) if $target_name;

  return ($sql, @bind);
}

sub _extract_target_name {
  my ($self, $target) = @_;

  return unless defined $target;

  if (ref $target eq 'SCALAR') {
    if ($$target =~ /^ (?:
        \` ( [^`]+ ) \` #`
      | ( [\w\-]+ )
    ) $/x
    ) {
      return (defined $1) ? $1 : $2;
    }
    return; # complex scalar ref, can't deal
  }

  # For HASH refs (simple result source) or plain strings, return as-is
  return ref $target ? undef : $target;
}


#
# Support for MySQL lock clause syntax according to specification
# including updates introduced in MySQL 8.0.1)
# FOR UPDATE | FOR SHARE [OF tbl_name [, tbl_name] ...] [NOWAIT | SKIP LOCKED]
#
# Which of those three parts the server at the other end actually has is a
# SERVER question, not a DBD one, so the storage answers it and stashes the
# answer here (karr #30, same shape as _insert_row_alias above). See
# DBIO::MySQL::Storage/_lock_dialect for the version table.

my $lock_modifiers = {
  nowait => 'NOWAIT',
  skip_locked => 'SKIP LOCKED'
};

# What a maker driven without a storage assumes: a current MySQL. Same polarity
# as the set-operation declarations in DBIO::MySQL::Storage -- every non-EOL
# MySQL is past 8.0.1, so the permissive answer is right for essentially the
# whole installed base, and the two servers that need the older spelling
# (MariaDB, MySQL before 8.0.1) are exactly the ones a connected storage can
# recognise. Byte-for-byte the behaviour this maker had before karr #30.
my $DEFAULT_LOCK_DIALECT = {
  share       => 'FOR SHARE',
  of          => 1,
  nowait      => 1,
  skip_locked => 1,
  server      => 'a MySQL 8.0.1 or newer (assumed -- no server was asked)',
};

sub _lock_dialect { $_[0]->{_lock_dialect} || $DEFAULT_LOCK_DIALECT }

sub _lock_select {
  my ($self, $type) = @_;

  my $dialect = $self->_lock_dialect;

  my $lock_types = {
    update => 'FOR UPDATE',
    share  => $dialect->{share},
  };

  # Handle hash-based configuration to support new featureset
  if (ref $type eq 'HASH') {
    my $lock_type = $type->{type};
    my $tables = $type->{of};
    my $modifier = $type->{modifier};

    my $lock_clause = $lock_types->{$lock_type}
      || $self->throw_exception("Unknown SELECT .. FOR type '$lock_type' requested");

    # Add OF clause if tables are specified
    if ($tables) {
      $self->throw_exception(
        "This server has no OF clause on a locking read, so this driver "
      . "refuses the 'of' key of the for => {} attribute. MySQL gained "
      . "OF tbl_name together with FOR SHARE, NOWAIT and SKIP LOCKED in "
      . "8.0.1; MariaDB has never had it -- its SELECT grammar reads "
      . "[FOR UPDATE lock_option | LOCK IN SHARE MODE lock_option] with "
      . "lock_option: [WAIT n | NOWAIT | SKIP LOCKED], and no OF anywhere. "
      . "The server here is $dialect->{server}. Drop the 'of' key: without "
      . "it the lock covers every table the statement reads, which is what "
      . "these servers do anyway."
      ) unless $dialect->{of};

      my @table_list = ref $tables eq 'ARRAY' ? @$tables : ($tables);
      if (@table_list) {
        my $quoted_tables = join(', ',
          map { $self->_quote($_) } @table_list
        );
        $lock_clause .= " OF $quoted_tables";
      }
    }

    # Add modifier if specified. The name is resolved before the server is
    # asked about it, so an unknown modifier is still reported as unknown
    # rather than as unavailable -- and so the availability question can be
    # asked per modifier, which is what the dialect answers: MySQL got NOWAIT
    # and SKIP LOCKED together in 8.0.1, MariaDB did not (karr #38).
    if ($modifier) {
      my $mod_sql = $lock_modifiers->{$modifier}
        || $self->throw_exception("Unknown lock modifier '$modifier' requested");

      $self->throw_exception(
        "This server has no $mod_sql on a locking read, so this driver refuses "
      . "modifier => '$modifier' in the for => {} attribute. The two products "
      . "drew the line in different places: MySQL gained NOWAIT and SKIP "
      . "LOCKED together in 8.0.1 (Reference Manual 17.7.2.4, 'Locking Read "
      . "Concurrency with NOWAIT and SKIP LOCKED'), while MariaDB gained "
      . "NOWAIT in 10.3 (MDEV-11379) and SKIP LOCKED only in 10.6 "
      . "(MDEV-13115), so a MariaDB in between has the one and not the other. "
      . "The server here is $dialect->{server}. Drop the modifier and the "
      . "locking read waits, which is the only behaviour this server has."
      ) unless $dialect->{$modifier};

      $lock_clause .= " $mod_sql";
    }

    return " $lock_clause";
  }

  # Handle simple string types (for backward compatibility)
  my $sql = $lock_types->{$type}
    || $self->throw_exception("Unknown SELECT .. FOR type '$type' requested");

  return " $sql";
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::SQLMaker - MySQL-specific SQL generation for DBIO

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  # Used automatically by DBIO::MySQL::Storage — no manual setup needed.

=head1 DESCRIPTION

MySQL-specific SQL generation layer for L<DBIO>. Extends L<DBIO::SQLMaker>
with the following MySQL adaptations:

=over 4

=item *

C<INSERT> with no columns emits C<INSERT INTO t () VALUES ()> instead of
the standard C<INSERT INTO t DEFAULT VALUES>, which MySQL does not support.

=item *

Supports C<STRAIGHT_JOIN> as a join type hint via the C<join_type> result
source attribute.

=item *

C<UPDATE> and C<DELETE> statements that reference the modification target
table in a subquery are automatically wrapped in a double subquery to work
around MySQL's restriction against self-referencing in DML.

=item *

Implements MySQL's C<SELECT ... FOR UPDATE / FOR SHARE> locking syntax,
including the C<OF tbl_name>, C<NOWAIT>, and C<SKIP LOCKED> clauses
introduced in MySQL 8.0.1.

=item *

Renders the atomic upsert (ADR 0036) as C<ON DUPLICATE KEY UPDATE>, in either
the C<VALUES(col)> or the C<< AS new ... new.col >> form depending on the
server version. See L</_insert_on_conflict>.

=item *

C<NULLS FIRST> / C<NULLS LAST> (the C<-nulls> key of an C<order_by> entry) is
emulated, neither MySQL nor MariaDB has the clause. The sort key is preceded by
a sort on whether it is C<NULL>: C<< { -asc => 'col', -nulls => 'first' } >>
renders C<< `col` IS NULL DESC, `col` ASC >>, and C<< -nulls => 'last' >>
renders C<< `col` IS NULL ASC, `col` ASC >> -- the rows come back in the same
order as on PostgreSQL. Always the C<IS NULL> form, whatever the direction. The
column expression is rendered twice, so a bind inside it is bound twice, in
order. See L</_render_op_nulls>.

=back

=head1 METHODS

=head2 _render_op_nulls

Renders the C<nulls_first> / C<nulls_last> ops SQL::Abstract builds for
C<-nulls> as C<< expr IS NULL DESC|ASC, expr [ASC|DESC] >>. The wrapped node is
the sort entry C<< expr ASC|DESC >> (or a bare C<expr>); the leading
C<IS NULL> sort puts the NULLs first (C<DESC>: true sorts before false) or last
(C<ASC>).

=head2 apply_limit

Uses MySQL's C<LIMIT [offset,] rows> syntax instead of the standard
C<LIMIT rows OFFSET offset>.

=head2 insert

Overrides the standard C<INSERT> to emit C<INSERT INTO t () VALUES ()> for
rows with no column values, satisfying MySQL's syntax requirements, and to
assemble the statement in grammar order:

  INSERT INTO ... VALUES ( ... ) [ AS `new` ] [ ON DUPLICATE KEY UPDATE ... ] [ RETURNING ... ]

Both tails are appended here rather than by the base, because the atomic-upsert
clause (ADR 0036, see L</_insert_on_conflict>) has to precede C<RETURNING> and
the base appends C<RETURNING> last. C<< $options->{returning} >> is restored
afterwards -- core reads it a second time, after the statement ran, to decide
whether to fetch the returned row.

Without either option the output is byte-for-byte what it was before.

=head2 _insert_row_alias

The name of the row alias this server understands in
C<INSERT ... VALUES (...) AS I<alias>>, or C<undef> when the older
C<VALUES(col)> function has to be used instead.

MySQL 8.0.20 deprecated C<VALUES(col)> and introduced the row alias; MariaDB
never grew that syntax at all. Which of the two applies is a fact about the
connected server, so L<DBIO::MySQL::Storage/sql_maker> determines it (from
the server version, never from the DBD driver name -- this dist's ADR 0001) and stashes
it on the maker instance. A maker built standalone has no server to ask and
falls back to C<VALUES(col)>, which every MySQL and MariaDB understands.

=head2 _insert_on_conflict

  my ($tail, @bind) = $sql_maker->_insert_on_conflict(\%on_conflict, \%data);

Renders the C<ON DUPLICATE KEY UPDATE> tail for the normalized C<on_conflict>
structure core hands down the insert options transport (ADR 0036 section 2),
mirroring how C<_insert_returning> appends the C<RETURNING> tail elsewhere.

Two MySQL facts shape the result:

=over 4

=item *

B<There is no conflict target.> C<ON DUPLICATE KEY UPDATE> fires on I<any>
primary-key or unique-key collision, so C<< $on_conflict->{target} >> is not
rendered at all. Whether a target the caller demanded can be honoured is
decided from the ResultSource's constraint metadata, one layer up, in
L<DBIO::MySQL::Storage/insert>.

=item *

B<There is no C<DO NOTHING>.> C<< action => 'nothing' >> is emulated with a
no-op assignment (C<< `col` = `col` >>), which is the documented idiom. The
affected-rows count tells the two outcomes apart (0 means the row was already
there, 1 means it was inserted) only on a connection without
C<CLIENT_FOUND_ROWS>. L<DBD::mysql> and L<DBD::MariaDB> both set that flag by
default (C<mysql_client_found_rows>, C<mariadb_client_found_rows>), and the
server -- MySQL and MariaDB alike -- then reports 1 for the already-present
row as well. Measured on MySQL 8.0.30 and MariaDB 11.8.8 through both DBDs
(F<t/81-upsert-affected-rows-found-rows-live.t>):

                               default / flag on   flag off
  DO NOTHING, new row                  1               1
  DO NOTHING, row already there        1               0
  upsert, new row                      1               1
  upsert, row there, nothing changed   1               0
  upsert, row there, changed           2               2

So on a default connection neither C<DO NOTHING> nor an upsert that changes
nothing can be told from an insert by its count. See
L<DBIO::MySQL::Storage/insert>.

=back

The attempted values (core's C<< { -attempted => $col } >>) render as
C<VALUES(`col`)> or, on a server that has the row alias, as C<< `new`.`col` >>
with C<AS `new`> appended to the C<VALUES> clause. Caller-supplied literals
(C<< \'count + 1' >>, C<< \[ 'x + ?', $n ] >>) pass through verbatim; anything
else becomes a placeholder plus bind.

Two private keys the storage may add to the structure are honoured here:
C<identity_column> (render C<< `pk` = LAST_INSERT_ID(`pk`) >>, the identity
idiom of ADR 0036 section 4) and C<noop_column> (the column the C<DO NOTHING>
emulation assigns to itself).

=head2 update

=head2 delete

Overrides the base C<update> and C<delete> methods. When the modification
target table is referenced in a subquery within the same statement (a pattern
MySQL rejects), the affected subquery is automatically re-wrapped in an
additional C<SELECT * FROM (...) `_forced_double_subquery`> layer to satisfy
MySQL's parser.

=head2 _lock_dialect

  my $dialect = $sql_maker->_lock_dialect;

The locking-read grammar of the B<connected server>, as
L<DBIO::MySQL::Storage/sql_maker> stashed it on this maker instance: a hashref
with C<share> (the keyword C<< for => 'share' >> renders as), C<of>, C<nowait>
and C<skip_locked> (whether this server has those parts of the clause at all --
the two modifiers separately, because MariaDB did not ship them together:
C<NOWAIT> in 10.3, C<SKIP LOCKED> in 10.6), and C<server> (a human label for
the exception messages).

The storage is the only side that can ask the server, so it decides and this
maker only renders -- the same split as L</_insert_row_alias>. A maker built
standalone has no server to ask and assumes a current MySQL: C<FOR SHARE> with
C<OF> and the modifiers available, which is what this class emitted
unconditionally before.

=head2 _lock_select

Generates the locking clause appended to C<SELECT> statements. Accepts
either a plain string (C<'update'>, C<'share'>) or a hashref
for fine-grained control:

  $rs->search({}, { for => { type => 'update', of => ['tbl'], modifier => 'nowait' } });

Valid C<type> values: C<update>, C<share>.
Valid C<modifier> values: C<nowait>, C<skip_locked>.
The C<of> key takes a table name or arrayref of table names.

C<share> renders as C<FOR SHARE> or C<LOCK IN SHARE MODE>, and C<of> and
C<modifier> are honoured or refused, according to L</_lock_dialect> -- i.e.
according to the server, not to the DBD driver the connection came in through.
A refusal throws locally, before the statement is assembled, naming the version
boundary it hit; see L<DBIO::MySQL::Storage/_lock_dialect>.

=head1 SEE ALSO

=pod

=over 4

=item * L<DBIO::MySQL::Storage> - Storage class that uses this SQL maker

=item * L<DBIO::MySQL> - Schema component entry point

=back

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
