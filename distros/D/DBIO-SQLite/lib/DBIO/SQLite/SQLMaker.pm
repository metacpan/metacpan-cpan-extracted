package DBIO::SQLite::SQLMaker;
# ABSTRACT: SQLite-specific SQL generation for DBIO

use warnings;
use strict;

our $VERSION = '0.900004';

use base qw( DBIO::SQLMaker );


#
# SQLite does not understand SELECT ... FOR UPDATE
# Disable it here
sub _lock_select () { '' };

# ADR 0036 -- atomic upsert. The conflict clause sits between the VALUES list
# and RETURNING, so it cannot simply be appended to whatever the generic
# insert() produced; the statement is assembled here in grammar order instead.
#
# $options->{on_conflict} MUST be consumed (deleted) before delegating: the
# generic DBIO::SQLMaker::insert throws when the structure reaches it, which is
# what keeps a driver that declares supports_upsert without implementing the
# clause loud instead of silently dropping it.
sub insert {
  my ($self, $table, $data, $options) = @_;

  # SQLite's OR-conflict clause -- INSERT OR IGNORE / INSERT OR REPLACE (karr
  # k38). It sits between the INSERT keyword and INTO, a DIFFERENT mechanism
  # from the statement-tail ON CONFLICT clause below. It rides the same
  # $options transport: consumed (deleted) here before delegating, then spliced
  # into the finished statement, so a plain insert without it is byte-for-byte
  # unchanged.
  my $insert_or = ( ref $options eq 'HASH' )
    ? delete $options->{insert_or}
    : undef
  ;

  my $on_conflict = ( ref $options eq 'HASH' )
    ? delete $options->{on_conflict}
    : undef
  ;

  my ($sql, @bind);

  if (! $on_conflict) {
    ($sql, @bind) = $self->next::method($table, $data, $options);
  }
  else {
    # Build the statement without its RETURNING tail, then append both tails:
    # INSERT INTO ... VALUES ( ... ) ON CONFLICT ( ... ) DO ... RETURNING ...
    my $returning = delete $options->{returning};

    ($sql, @bind) = $self->next::method($table, $data, $options);

    # Put it back -- DBIO::Storage::DBI::insert reads $sqla_opts->{returning}
    # after the statement ran, to know which columns the handle hands back.
    $options->{returning} = $returning if defined $returning;

    my ($conflict_sql, @conflict_bind) = $self->_insert_on_conflict($on_conflict, $table);
    $sql .= $conflict_sql;
    push @bind, @conflict_bind;

    if (defined $returning) {
      my ($returning_sql, @returning_bind) = $self->_insert_returning($options);
      $sql .= $returning_sql;
      push @bind, @returning_bind;
    }
  }

  $sql = $self->_insert_or_clause($sql, $insert_or) if defined $insert_or;

  return wantarray ? ($sql, @bind) : $sql;
}


# Splices SQLite's OR-conflict clause (INSERT OR IGNORE / INSERT OR REPLACE)
# into a finished statement, between the INSERT keyword and INTO. Only 'ignore'
# and 'replace' are exposed (karr k38); an unknown mode throws rather than
# emitting something the engine would reject or, worse, silently accept.
sub _insert_or_clause {
  my ($self, $sql, $insert_or) = @_;

  my $mode = lc $insert_or;

  $self->throw_exception(
    "insert_or must be 'ignore' or 'replace', not '$insert_or'"
  ) unless $mode eq 'ignore' or $mode eq 'replace';

  my $clause = $self->_sqlcase("or $mode");   # OR IGNORE / OR REPLACE

  # The generic insert always emits the INSERT keyword first; splice the clause
  # in right after it, without assuming its letter case. If the statement does
  # not start with INSERT, something upstream changed -- fail loud rather than
  # mangle it.
  $sql =~ s/\A(\s*insert)\b/$1 $clause/i
    or $self->throw_exception(
      "expected the generated statement to start with INSERT, got '$sql'"
    );

  return $sql;
}


# Renders the ON CONFLICT tail from core's engine-neutral structure:
#
#   { target => \@cols | { constraint => $name, columns => \@cols } | 'any',
#     action => 'update' | 'nothing',
#     set    => { $col => { -attempted => $col } | \'literal' | $scalar },
#     where  => $cond }        # only when the caller passed update_where
#
# Returns ($sql_tail, @bind), mirroring _insert_returning.
sub _insert_on_conflict {
  my ($self, $on_conflict, $table) = @_;

  $self->throw_exception(
    'on_conflict must be a hashref of { target => ..., action => ..., set => ... }'
  ) unless ref $on_conflict eq 'HASH';

  my $action = defined $on_conflict->{action} ? $on_conflict->{action} : 'update';
  my $target = $on_conflict->{target};

  my @target_cols;

  if (ref $target eq 'ARRAY') {
    $self->throw_exception(
      'ON CONFLICT needs at least one conflict target column'
    ) unless @$target;

    @target_cols = @$target;
  }
  elsif (ref $target eq 'HASH') {
    # core's upsert(..., { key => $constraint }), resolved: the hashref carries
    # the constraint *name* and the columns core resolved it to (ADR 0036 s2).
    # SQLite takes the columns -- its grammar has no ON CONSTRAINT form, and a
    # DBIO constraint name is client-side add_unique_constraint metadata that
    # need not name anything the server knows anyway.
    my $cols = $target->{columns};

    # A SQLMaker has no ResultSource, so it cannot resolve the name itself: if
    # the resolved half is missing there is nothing to render, and emitting
    # "ON CONFLICT ()" would be a syntax error at best and a wrongly targeted
    # write at worst. Fail here so a core that stops sending it is loud.
    $self->throw_exception(
      'ON CONFLICT target hashref carries no resolved columns -- core resolves '
    . 'key => $constraint once and passes '
    . '{ constraint => $name, columns => \@columns } (ADR 0036 section 2), and '
    . "SQLite's conflict target is that column list"
    . ( defined $target->{constraint} ? " (constraint '$target->{constraint}')" : '' )
    ) unless ref $cols eq 'ARRAY' and @$cols;

    @target_cols = @$cols;
  }
  elsif (defined $target and ! length ref $target and $target eq 'any') {
    # "whichever unique constraint collides" is MySQL's native shape. SQLite
    # can express it only as a targetless DO NOTHING -- DO UPDATE requires a
    # target, so the clause is left empty here and rejected below.
    $self->throw_exception(
      "conflict_target => 'any' cannot be combined with on_conflict => 'update' "
    . "on SQLite: the ON CONFLICT grammar requires a conflict target for DO "
    . "UPDATE. Name the columns with conflict_target => \\\@columns, or use "
    . "on_conflict => 'nothing', which needs no target"
    ) if $action eq 'update';
  }
  else {
    $self->throw_exception(
      'ON CONFLICT target must be an arrayref of columns, '
    . "{ constraint => \$name, columns => \\\@columns } or the string 'any'"
    );
  }

  my $target_sql = @target_cols
    ? ' (' . join(', ', map { $self->_quote($_) } @target_cols) . ')'
    : ''
  ;

  if ($action eq 'nothing') {
    # Core refuses update_where together with on_conflict => 'nothing' before
    # the structure ever gets here, and sets the key only when it has a
    # condition. If one arrives anyway -- in any state, hence exists and not
    # defined -- dropping it is the one mistake this whole feature is guarded
    # against, so say so.
    $self->throw_exception(
      'ON CONFLICT DO NOTHING takes no condition -- there is no update branch '
    . 'for a WHERE to gate'
    ) if exists $on_conflict->{where};

    return ' ' . $self->_sqlcase('on conflict') . $target_sql
         . ' ' . $self->_sqlcase('do nothing');
  }

  $self->throw_exception(
    "unknown ON CONFLICT action '$action' -- SQLite has DO UPDATE and DO NOTHING"
  ) unless $action eq 'update';

  my $set = $on_conflict->{set};
  $self->throw_exception(
    'ON CONFLICT DO UPDATE needs a non-empty set of column => value pairs'
  ) unless ref $set eq 'HASH' and keys %$set;

  my (@set_sql, @bind);

  for my $col (sort keys %$set) {
    my $label = $self->_quote($col);
    my $value = $set->{$col};

    $self->_SWITCH_refkind($value, {

      # { -attempted => $col } is core's engine-neutral "the value that was
      # attempted to be inserted". _upsert_attempted_sql spells it for this
      # engine, and both halves of the statement go through that one method so
      # they can never diverge.
      HASHREF => sub {
        my ($op, $arg, @rest) = %$value;

        $self->throw_exception(
          "the only operator an ON CONFLICT update set understands is "
        . "-attempted (the value that was attempted to be inserted), not '$op'"
        ) if @rest or ! defined $op or $op ne '-attempted';

        $self->throw_exception('-attempted takes a plain column name')
          if ! defined $arg or length ref $arg;

        push @set_sql, "$label = " . $self->_upsert_attempted_sql($arg);
      },

      ARRAYREFREF => sub {   # \[ 'literal SQL', @bind ]
        my ($literal, @literal_bind) = @$$value;
        $self->_assert_bindval_matches_bindtype(@literal_bind);
        push @set_sql, "$label = $literal";
        push @bind, @literal_bind;
      },

      ARRAYREF => sub {      # [ 'literal SQL', @bind ], as update() takes it
        my ($literal, @literal_bind) = @$value;
        $self->_assert_bindval_matches_bindtype(@literal_bind);
        push @set_sql, "$label = $literal";
        push @bind, @literal_bind;
      },

      SCALARREF => sub {     # \'literal SQL'
        push @set_sql, "$label = $$value";
      },

      SCALAR_or_UNDEF => sub {
        push @set_sql, "$label = ?";
        push @bind, $self->_bindtype($col, $value);
      }

    });
  }

  my $sql = ' ' . $self->_sqlcase('on conflict') . $target_sql
          . ' ' . $self->_sqlcase('do update set') . ' ' . join(', ', @set_sql);

  # The conditional conflict branch (ADR 0036, core k105). The key is present
  # only when the caller passed update_where, so an unconditional upsert still
  # renders byte for byte what it rendered before the option existed.
  #
  # Placement: after the SET list, before RETURNING -- which follows from where
  # this tail is appended, since insert() holds RETURNING back over the call to
  # the generic insert and appends it after this.
  if (exists $on_conflict->{where}) {
    my $where = $on_conflict->{where};

    my ($where_sql, @where_bind) = defined $where
      ? $self->_upsert_condition_sql($where, $table)
      : ()
    ;

    # Every route that would leave the clause without a condition ends here,
    # because emitting it anyway is an UNCONDITIONAL DO UPDATE -- the
    # last-write-wins overwrite update_where exists to prevent, and the one
    # failure mode with no symptom of its own. Core rejects the empty forms it
    # can see ({} / []) and sets the key only when it has a condition, but it
    # deliberately does not walk the condition, so { -and => [] } and friends
    # arrive here.
    $self->throw_exception(
      'the ON CONFLICT DO UPDATE condition rendered to nothing -- emitting the '
    . 'clause without it would be an unconditional overwrite, which is exactly '
    . 'what update_where is there to prevent'
    ) unless defined $where_sql and length $where_sql;

    $sql .= ' ' . $self->_sqlcase('where') . ' ' . $where_sql;
    push @bind, @where_bind;
  }

  return ($sql, @bind);
}


# The one engine-specific piece of an atomic upsert (ADR 0036): the token for
# the pseudo-row that holds the value the statement tried to insert. Core's
# engine-neutral { -attempted => $col } marker becomes excluded.<col> here. The
# update set and the conditional branch both render through this single method,
# so the two halves of one statement can never write the pseudo-row
# differently. Core's _upsert_condition_sql (DBIO::SQLMaker::ClassicExtensions)
# does the condition-half substitution and is parameterized over this method.
sub _upsert_attempted_sql {
  my ($self, $col) = @_;
  return 'excluded.' . $self->_quote($col);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQLite::SQLMaker - SQLite-specific SQL generation for DBIO

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

SQLite-specific subclass of L<DBIO::SQLMaker>. Disables C<SELECT ... FOR UPDATE>
locking syntax, which SQLite does not support, and renders the
C<INSERT ... ON CONFLICT> clause of the atomic upsert (ADR 0036). All other SQL
generation is inherited from L<DBIO::SQLMaker>.

This class is set as the C<sql_maker_class> by L<DBIO::SQLite::Storage> and
is not normally instantiated directly.

=head1 METHODS

=head2 insert

Overrides L<DBIO::SQLMaker/insert> to render two SQLite-specific pieces, both
carried on the same C<$options> transport as C<returning>:

=over

=item * C<< $options->{on_conflict} >> -- the C<ON CONFLICT> tail of an atomic
upsert (ADR 0036):

  INSERT INTO ... VALUES ( ... ) ON CONFLICT ( ... ) DO ... [ RETURNING ... ]

=item * C<< $options->{insert_or} >> -- SQLite's OR-conflict clause,
C<'ignore'> or C<'replace'>, which sits between the C<INSERT> keyword and
C<INTO>. This is a I<different> mechanism from C<on_conflict>:

  INSERT OR IGNORE  INTO ... VALUES ( ... )
  INSERT OR REPLACE INTO ... VALUES ( ... )

It is an option of this method only: L<DBIO::Storage::DBI/insert> builds the
options it hands down itself (C<returning>, and C<on_conflict> for
L<DBIO::ResultSet/upsert>) and passes nothing else on from its caller, so no
ORM call (C<< $rs->create >>, C<< $row->insert >>) can reach C<insert_or> -- it
is for a caller that generates the statement through the SQL maker and executes
it itself.

=back

Both keys are consumed (deleted from C<$options>) before delegating to the
generic insert. Without either, the call is passed straight through, so a plain
insert is byte-for-byte what it was before.

=head2 _insert_or_clause

    my $sql = $sql_maker->_insert_or_clause($insert_sql, 'ignore');

Splices SQLite's OR-conflict clause into a finished C<INSERT> statement,
turning C<INSERT INTO ...> into C<INSERT OR IGNORE INTO ...> or
C<INSERT OR REPLACE INTO ...>. Only C<'ignore'> and C<'replace'> are accepted;
any other value throws.

=head2 _insert_on_conflict

    my ($sql_tail, @bind) = $sql_maker->_insert_on_conflict(\%on_conflict);

Renders the C<ON CONFLICT> tail from the engine-neutral structure core builds
in L<DBIO::ResultSet/upsert>, mirroring C<_insert_returning>:

    { target => \@cols | { constraint => $name, columns => \@cols } | 'any',
      action => 'update' | 'nothing',
      set    => { $col => { -attempted => $col } | \'literal' | $scalar },
      where  => $cond }

C<< { -attempted => $col } >> is rendered as C<< excluded.<col> >> -- the value
the statement tried to insert. Literal C<\'...'>, literal-with-bind
C<\[ '...', @bind ]> and plain scalars (bound) are accepted as written.

C<where> is L<DBIO::ResultSet/upsert>'s C<update_where>, the conditional
conflict branch, and is present only when the caller passed one. It is rendered
B<after the C<SET> list and before C<RETURNING>>, with its bind values spliced
in at that position, and it accepts everything a
L<SQL::Abstract> condition accepts. See L<DBIO::SQLMaker/_upsert_condition_sql>
for the one thing that is not plain C<_recurse_where>.

Every route to a I<dropped> condition throws instead, because silently dropping
one is the mistake this feature exists to prevent -- it leaves a perfectly
valid unconditional C<DO UPDATE> behind, with no symptom of its own. That is
a C<where> on the C<< action => 'nothing' >> branch (there is no update branch
for a condition to gate), an undef one (the key is set only when there is a
condition), and one that renders to an empty string (C<< { -and => [] } >>).

The hashref target is C<< upsert(..., { key => $constraint }) >>: core resolves
the constraint name once and hands down both halves. SQLite renders the
B<columns> -- its grammar has no C<ON CONSTRAINT> form, and a DBIO constraint
name is client-side C<add_unique_constraint> metadata that need not name
anything the server knows. C<key> and the equivalent
C<< conflict_target => \@columns >> therefore produce identical SQL.

Two shapes throw here rather than emit something wrong:

=over

=item * a hashref target whose C<columns> are absent or empty -- a SQLMaker has
no ResultSource of its own to resolve the name against, so there is nothing to
render and C<ON CONFLICT ()> would be the alternative.

=item * C<< target => 'any' >> together with C<< action => 'update' >> --
C<DO UPDATE> requires a conflict target. C<< 'any' >> with
C<< action => 'nothing' >> is fine and emits a targetless C<DO NOTHING>.

=back

=head2 _upsert_attempted_sql

    my $sql = $sql_maker->_upsert_attempted_sql('rank');

Spells core's engine-neutral C<< { -attempted => $column } >> marker -- the value
the statement B<tried to insert> -- as this engine's reference to the attempted
row: C<< excluded.<column> >>.

It is the one engine-specific piece of the atomic upsert: core's
C<L<DBIO::SQLMaker/_upsert_condition_sql>> has no default for it and is
parameterized over it (ADR 0036 pins the token to the driver). Both halves of
the statement use this method -- the C<set> list and the conditional branch --
so the pseudo-row is spelled identically wherever it appears.

=head1 SEE ALSO

=pod

=over

=item * L<DBIO::SQLMaker> - Base SQL generation class

=item * L<DBIO::SQLite::Storage> - Storage driver that uses this SQL maker

=item * L<DBIO::SQLite> - Top-level SQLite schema component

=item * L<DBIO::ResultSet/upsert> - The user-facing atomic upsert

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
