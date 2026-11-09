package DBIO::ClickHouse::SQLMaker;
# ABSTRACT: ClickHouse-specific SQL generation for DBIO

use strict;
use warnings;

our $VERSION = '0.900004';

use base qw( DBIO::SQLMaker );


# ClickHouse has no SELECT ... FOR UPDATE (no row locks, no transactions).
sub _lock_select () { '' }


sub new {
  my $self = shift;
  my %opts = (ref $_[0] eq 'HASH') ? %{$_[0]} : @_;

  # exists(), not truthiness: an explicit undef means "emit no SETTINGS clause"
  # and must survive, and 0 is a legal value.
  $opts{mutations_sync} = 1 unless exists $opts{mutations_sync};

  $self->throw_exception(sprintf
    q{Invalid mutations_sync value '%s': ClickHouse accepts 0 (queue the }
  . 'mutation and return), 1 (wait for it on this server) or 2 (wait for it on '
  . 'all replicas). Pass undef to emit no SETTINGS clause and leave the setting '
  . 'to the session or the server profile',
    $opts{mutations_sync}
  ) if defined $opts{mutations_sync} and $opts{mutations_sync} !~ /\A[012]\z/;

  # ClickHouse spells the assignment list without a SET keyword, which is what
  # SQL::Abstract's generic clause renderer would prepend.
  $opts{render_clause}{'update.set'} ||= '_render_update_clause_set';

  return $self->next::method(\%opts);
}


sub update {
  my ($self, $table, $set, $where, $options) = @_;

  $self->_assert_mutation_target(update => $table);

  $self->throw_exception(
    'An UPDATE on ClickHouse renders as ALTER TABLE ... UPDATE col = ..., '
  . 'which has no form without an assignment: update() needs a non-empty '
  . 'hashref of columns to set'
  ) unless ref $set eq 'HASH' and keys %$set;

  my ($sql, @bind) = $self->next::method(
    $table, $set, $self->_mutation_where($where), $options
  );
  $sql .= $self->_mutations_sync_clause;

  return wantarray ? ($sql, @bind) : $sql;
}


sub delete {
  my ($self, $table, $where, $options) = @_;

  $self->_assert_mutation_target(delete => $table);

  my ($sql, @bind) = $self->next::method(
    $table, $self->_mutation_where($where), $options
  );
  $sql .= $self->_mutations_sync_clause;

  return wantarray ? ($sql, @bind) : $sql;
}

# ALTER TABLE names exactly one real table. Everything else core can hand a
# storage as an "ident" -- a from-list, a virtual view's literal SQL -- has no
# ALTER form at all, and would otherwise reach the server as nonsense.
sub _assert_mutation_target {
  my ($self, $op, $table) = @_;

  return unless my $ref = ref $table;

  $self->throw_exception(sprintf
    'ClickHouse renders %s as ALTER TABLE ... %s, which can only name a single '
  . 'real table -- but this one was given a %s target (a virtual view or other '
  . 'literal-SQL result source, or a join list). Run the %s against the '
  . 'underlying MergeTree table instead; if the rows are identified through '
  . 'another table, keep the target table as the result source and put the '
  . 'other one in the WHERE clause as a subquery, e.g. '
  . q{$rs->search({ id => { -in => $other_rs->get_column('id')->as_query } })},
    uc($op), uc($op), $ref, $op
  );
}

# A ClickHouse mutation must carry a filter expression: 'ALTER TABLE t DELETE'
# is a syntax error, not a delete-everything. WHERE 1 is how ClickHouse spells
# what an unrestricted $rs->delete means everywhere else.
sub _mutation_where {
  my ($self, $where) = @_;

  return \'1' unless defined $where;

  my $ref = ref $where;

  return \'1' if $ref eq 'HASH'  and ! keys %$where;
  return \'1' if $ref eq 'ARRAY' and ! @$where;

  # \'literal SQL'
  return \'1' if $ref eq 'SCALAR'
    and (! defined ${$where} or ${$where} !~ /\S/);

  # \[ $sql, @bind ] -- the shape DBIO::ResultSet::_rs_update_delete builds,
  # which is empty SQL for a resultset with no condition.
  return \'1' if $ref eq 'REF'
    and ref ${$where} eq 'ARRAY'
    and (! defined ${$where}->[0] or ${$where}->[0] !~ /\S/);

  return $where;
}

# Setting *names* are case-sensitive in ClickHouse, so only the keyword goes
# through _sqlcase. The value is 0/1/2, validated in new().
sub _mutations_sync_clause {
  my $self = shift;

  my $sync = exists $self->{mutations_sync} ? $self->{mutations_sync} : 1;
  return '' unless defined $sync;

  return $self->_sqlcase(' settings ') . "mutations_sync = $sync";
}


sub _render_update_clause_target {
  my ($self, undef, $target) = @_;
  return $self->join_query_parts(' ',
    { -keyword => 'alter_table' }, $target, { -keyword => 'update' }
  );
}


sub _render_update_clause_set {
  my ($self, undef, $set) = @_;
  return $self->render_aqt($set, 1);
}


sub _render_delete_clause_target {
  my ($self, undef, $target) = @_;
  return $self->join_query_parts(' ',
    { -keyword => 'alter_table' }, $target, { -keyword => 'delete' }
  );
}


sub insert_multi {
  my ($self, $table, $cols, $rows) = @_;

  $self->throw_exception(
    'insert_multi() needs a non-empty arrayref of column names'
  ) unless ref $cols eq 'ARRAY' and @$cols;

  $self->throw_exception(
    'insert_multi() needs a non-empty arrayref of rows'
  ) unless ref $rows eq 'ARRAY' and @$rows;

  my @tuples;
  for my $idx (0 .. $#$rows) {
    my $row = $rows->[$idx];

    $self->throw_exception(sprintf
      'insert_multi() row %d is not an arrayref: rows are positional and '
    . 'must line up with the %d supplied column names (%s)',
      $idx, scalar @$cols, join ', ', @$cols
    ) unless ref $row eq 'ARRAY';

    $self->throw_exception(sprintf
      'insert_multi() row %d has %d value(s) but there are %d columns (%s): '
    . 'a multi-row INSERT is a single statement with a single column list, so '
    . 'every row must fill all of them',
      $idx, scalar @$row, scalar @$cols, join ', ', @$cols
    ) unless @$row == @$cols;

    push @tuples, { -row => [
      map { $self->_insert_multi_value($cols->[$_], $row->[$_]) } 0 .. $#$cols
    ] };
  }

  return $self->render_statement({ -insert => {
    target => $table,
    fields => [ @$cols ],
    from   => { -values => \@tuples }
  }});
}

# One VALUES cell as an SQL::Abstract AQT node.
sub _insert_multi_value {
  my ($self, $col, $value) = @_;

  my $ref = ref $value;

  # \'literal SQL'
  return { -literal => [ $$value ] } if $ref eq 'SCALAR';

  # \[ 'literal SQL with ?', @binds ]
  return { -literal => [ @$$value ] } if $ref eq 'REF' and ref $$value eq 'ARRAY';

  # A bare arrayref is never a value. ClickHouse does have Array(T) columns,
  # which makes this a likely mistake rather than an exotic one, and no
  # MySQL-wire DBD can bind a Perl list -- so say what to write instead.
  $self->throw_exception(sprintf
    q{insert_multi(): column '%s' was given a plain arrayref. There is no bind }
  . 'type for a list: write an Array(T) value as literal SQL with binds, '
  . q{\[ '[?, ?]', $a, $b ], or hand in the ClickHouse array literal as a }
  . 'string'
  , $col) if $ref eq 'ARRAY';

  return { -bind => [ $col, $value ] };
}


sub _render_bind {
  my ($self, $type, $bind) = @_;
  my ($col, $value) = @$bind;

  if (defined $value and !ref $value and $value =~ /\x1A/) {
    my $n = 0;
    $n++ while index($value, "ch1a${n}x") >= 0;
    my $marker = "ch1a${n}x";
    (my $marked = $value) =~ s/\x1A/$marker/g;
    return [ "replaceAll(?, '$marker', char(26))", $self->_bindtype($col, $marked) ];
  }

  return $self->next::method($type, $bind);
}


sub select {
  my ($self, $table, $fields, $where, $rs_attrs, @rest) = @_;

  my $ch = ref $rs_attrs eq 'HASH' ? $rs_attrs : {};
  local $self->{_clickhouse_final}    = $ch->{final} ? 1 : 0;
  local $self->{_clickhouse_prewhere} = $ch->{prewhere};

  return $self->next::method($table, $fields, $where, $rs_attrs, @rest);
}


sub _assemble_binds {
  my $self = shift;
  return map { @{ (delete $self->{"${_}_bind"}) || [] } } (
    qw/pre_select select from clickhouse_prewhere where group having order clickhouse_limit_by limit/
  );
}


sub _table {
  my $self = shift;

  my $sql = $self->next::method(@_);

  # A from-list goes through _gen_from_blocks, which has already attached FINAL
  # to the primary block and consumed the flag; a bare table name does not, so
  # it is picked up here instead.
  $sql .= $self->_clickhouse_final_sql;

  my $prewhere = $self->{_clickhouse_prewhere};
  if (defined $prewhere) {
    my ($frag, @bind) = $self->_recurse_where($prewhere);
    if (defined $frag and length $frag) {
      push @{$self->{clickhouse_prewhere_bind}}, @bind;
      $sql .= $self->_sqlcase(' prewhere ') . $frag;
    }
  }

  return $sql;
}


sub _gen_from_blocks {
  my $self = shift;

  # Consumed *before* recursing: _recurse_from re-enters this method for nested
  # join groups, and FINAL belongs to the primary table of the outermost list
  # only.
  my $final = $self->_clickhouse_final_sql;

  my @blocks = $self->next::method(@_);
  $blocks[0] .= $final if @blocks and length $final;

  return @blocks;
}

# Returns ' FINAL' the first time it is asked within one statement, '' after
# that -- the modifier applies to exactly one table reference.
sub _clickhouse_final_sql {
  my $self = shift;
  return '' unless $self->{_clickhouse_final};
  $self->{_clickhouse_final} = 0;
  return $self->_sqlcase(' final');
}


sub _parse_rs_attrs {
  my $self = shift;
  my ($rs_attrs) = @_;

  my $sql = $self->next::method(@_);

  if (ref $rs_attrs eq 'HASH' and defined $rs_attrs->{limit_by}) {
    my ($limit_by_sql, @limit_by_bind) = $self->_limit_by($rs_attrs->{limit_by});
    push @{$self->{clickhouse_limit_by_bind}}, @limit_by_bind;
    $sql .= $limit_by_sql;
  }

  return $sql;
}


sub _limit_by {
  my ($self, $spec) = @_;

  $self->throw_exception(
    q{The 'limit_by' attribute must be a hashref of { rows => $n, by => $columns }}
  ) unless ref $spec eq 'HASH';

  my $rows = $spec->{rows};
  $self->throw_exception(
    q{The 'limit_by' attribute needs a positive integer 'rows' value}
  ) if ! defined $rows or $rows =~ /\D/ or $rows <= 0;

  $self->throw_exception(
    q{The 'limit_by' attribute needs a 'by' column specification}
  ) unless defined $spec->{by};

  my ($by_sql, @bind) = $self->_recurse_fields($spec->{by});
  $self->throw_exception(
    q{The 'limit_by' attribute needs a 'by' column specification}
  ) unless defined $by_sql and length $by_sql;

  return (
    $self->_sqlcase(' limit ') . $rows . $self->_sqlcase(' by ') . $by_sql,
    @bind
  );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::ClickHouse::SQLMaker - ClickHouse-specific SQL generation for DBIO

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

ClickHouse-specific subclass of L<DBIO::SQLMaker>. ClickHouse is reached over
the MySQL wire protocol and uses backtick identifier quoting; the quote
character is applied by L<DBIO::ClickHouse::Storage> (via C<sql_quote_char> and
its C<sql_maker> post-processing), not set here.

This class turns off the bits ClickHouse does not do:

=over 4

=item * C<SELECT ... FOR UPDATE> is not supported -- disabled via
C<_lock_select>.

=back

re-renders C<UPDATE> and C<DELETE> as the asynchronous mutations ClickHouse
actually has -- see L</MUTATIONS> -- adds the ClickHouse C<SELECT> extensions
that have no ANSI equivalent and are therefore not reachable through any core
attribute -- see L</CLICKHOUSE RESULTSET ATTRIBUTES> -- and renders the
multi-row C<INSERT> that L<DBIO::ClickHouse::Storage/_insert_bulk> needs, see
L</insert_multi>.

All other SQL generation is inherited unchanged from L<DBIO::SQLMaker>.

This class is set as the C<sql_maker_class> by L<DBIO::ClickHouse::Storage> and
is not normally instantiated directly.

=head1 METHODS

=head2 new

Defaults and validates the C<mutations_sync> option (see L</mutations_sync>),
and registers the renderer that drops the C<SET> keyword from an C<UPDATE>.

=head2 update

    my ($sql, @bind) = $sqlmaker->update('hit', { hits => 1 }, { id => $id });
    # ALTER TABLE `hit` UPDATE `hits` = ? WHERE `id` = ? SETTINGS mutations_sync = 1

Renders the C<ALTER TABLE ... UPDATE> mutation. See L</MUTATIONS>.

=head2 delete

    my ($sql, @bind) = $sqlmaker->delete('hit', { id => $id });
    # ALTER TABLE `hit` DELETE WHERE `id` = ? SETTINGS mutations_sync = 1

Renders the C<ALTER TABLE ... DELETE> mutation. See L</MUTATIONS>.

=head2 _render_update_clause_target

Renders C<ALTER TABLE `t` UPDATE> where core renders C<UPDATE `t`>.

=head2 _render_update_clause_set

Renders the assignment list B<without> the C<SET> keyword -- ClickHouse writes
C<ALTER TABLE t UPDATE a = 1, b = 2>, not C<... UPDATE SET a = 1>. Registered
as the C<update.set> clause renderer in L</new>; the assignment list itself is
rendered by the inherited machinery, so literal SQL and per-column bind
attributes behave exactly as on any other driver.

=head2 _render_delete_clause_target

Renders C<ALTER TABLE `t` DELETE> where core renders C<DELETE FROM `t`>.

=head2 insert_multi

    my ($sql, @bind) = $sqlmaker->insert_multi(
      'hit', [qw( id url )], [ [ 1, '/a' ], [ 2, '/b' ] ],
    );
    # INSERT INTO `hit` (`id`, `url`) VALUES (?, ?), (?, ?)
    # binds: [ id => 1 ], [ url => '/a' ], [ id => 2 ], [ url => '/b' ]

Renders B<one> C<INSERT> statement carrying every row as its own C<VALUES>
tuple. This is the shape ClickHouse wants -- an INSERT is a part write, and one
statement per row produces one tiny part per row, which is the classic way to
melt a MergeTree table. L<DBIO::ClickHouse::Storage/_insert_bulk> routes the
whole C<populate> dataset through here as a single statement.

C<$cols> is a positional column list; C<$rows> is an arrayref of arrayrefs,
each of the same length. A cell is a plain bind value, C<\'literal SQL'>, or
C<< \[ 'literal SQL with ?', @binds ] >> -- the same value vocabulary as core's
single-row insert.

Binds come back in statement order (row by row, left to right) as
C<< [ $column_name => $value ] >> pairs, the C<bindtype =E<gt> 'columns'> form
core's C<_resolve_bindattrs> expects, so per-column type attributes are applied
to every row.

Unlike core's C<_insert_bulk> -- which prepares B<one> statement and executes
it once per row, and therefore requires the literal SQL of a given column to be
identical in every row -- each row is rendered separately here. Rows may mix
literals and plain values freely, e.g. C<\'generateUUIDv4()'> in one row and an
explicit id in the next.

What every row must share is the B<column list>: one statement has one
C<(col, col, ...)> header, so a row of the wrong length is a hard error rather
than a silently padded tuple.

The rendered statement grows with the dataset (one placeholder per cell). A
populate large enough to exceed the server's C<max_allowed_packet> has to be
chunked by the caller; nothing here splits it.

=head2 _render_bind

Renders every bound value, and changes exactly one kind: a string that contains
the byte C<0x1A> (C<SUB>, C<Ctrl-Z>) is bound as
C<replaceAll(?, 'ch1aE<lt>nE<gt>x', char(26))>, with the value's C<0x1A> bytes
replaced by that marker.

The reason is the transport. C<DBD::mysql> substitutes the placeholders itself
and escapes C<0x1A> as C<\Z>; ClickHouse's parser does not know that escape
and stores the backslash and the C<Z>, so a text or blob value grew by one
character per C<0x1A> and read back as something else
(C<bind-binary>, C<bind-lob-empty-and-large>). Server-side
preparation, which would send the bytes untouched, is not available: the server
reports no parameters for a prepared statement (C<mysql_server_prepare>,
measured). C<unhex(?)> over the hex of the value is exact, but doubles the
statement, and a 100000-byte blob then exceeds the server's C<max_query_size>
(262144, measured). The marker is the smaller change: the value goes as it was
with nothing but the C<0x1A> bytes replaced, one placeholder, no re-encoding.
C<E<lt>nE<gt>> is the first number for which the marker does not occur in the
value, so the replacement cannot touch anything else.

B<Measured with C<DBD::mysql> only.> C<DBD::MariaDB> does not connect to a stock
server (it sends C<SET character_set_server>, rejected with C<UNKNOWN_SETTING>;
see L<DBIO::ClickHouse::Storage>), so how it escapes C<0x1A> and whether the
marker arrives intact there has not been measured and is not claimed.

Nothing else is rewritten: a value without C<0x1A>, C<undef>, a reference
(literal SQL) and a number are bound as they are. The bind keeps its column, so
its attributes are resolved as for any other.

=head2 select

Stashes the ClickHouse dialect attributes for the duration of the statement so
L</_table> and L</_gen_from_blocks> -- which are handed only the C<from> spec by
L<SQL::Abstract> -- can reach them, then defers to the inherited implementation.

=head2 _assemble_binds

The inherited bind order with two ClickHouse slots spliced in: C<PREWHERE>
binds between the C<FROM> and the C<WHERE> binds, C<LIMIT n BY> binds between
the C<ORDER BY> and the C<LIMIT> binds -- i.e. each in the position its clause
occupies in the emitted statement.

=head2 _table

Appends the C<PREWHERE> clause (which follows the whole C<FROM> and C<JOIN>
list) and, for a bare table name, the C<FINAL> modifier.

=head2 _gen_from_blocks

Attaches C<FINAL> to the primary (leftmost) table block of the outermost
C<FROM> list, after its alias.

=head2 _parse_rs_attrs

Appends C<LIMIT n BY columns> after the inherited C<GROUP BY> / C<HAVING> /
C<ORDER BY> rendering, which is exactly where ClickHouse expects it: after
C<ORDER BY> and before the ordinary C<LIMIT> that C<apply_limit> adds.

=head2 _limit_by

    my ($sql, @bind) = $sqlmaker->_limit_by({ rows => 3, by => 'user_id' });

Renders the C<limit_by> attribute. See L</limit_by>.

=head1 CLICKHOUSE RESULTSET ATTRIBUTES

C<final>, C<prewhere> and C<limit_by> are ordinary resultset attributes:
C<DBIO::ResultSet::_resolved_attrs> copies the attribute hash wholesale and
C<DBIO::Storage::DBI::_select_args> hands that whole hash to L</select> as its
fourth argument, so unknown keys reach the SQL maker untouched. No core change,
no registration and no whitelist is involved -- the same route
L<DBIO::Oracle::SQLMaker> uses for C<connect_by> / C<start_with>.

=head2 final

    $schema->resultset('Hit')->search(undef, { final => 1 });
    # SELECT `me`.`id` FROM `hit` `me` FINAL

Emits the C<FINAL> modifier, which makes a C<MergeTree>-family table return
fully merged rows -- the only correct way to read a C<ReplacingMergeTree> or
C<CollapsingMergeTree> without doing the deduplication by hand. There is no
core attribute that produces it, hence real API surface rather than a
documented escape hatch.

C<FINAL> is a modifier on a I<single> table reference and must follow that
table's alias (C<FROM t AS me FINAL>; putting it before the alias is a syntax
error). With joins it is therefore attached to the primary (leftmost) table
only and join targets are left alone; ClickHouse does not propagate C<FINAL>
across a join either. Use literal SQL if a joined table needs it too.

=head2 prewhere

    $schema->resultset('Hit')->search({ url => $url }, {
      prewhere => { event_date => $day },
    });
    # ... FROM `hit` `me` PREWHERE `event_date` = ? WHERE ( `url` = ? )

Emits ClickHouse's C<PREWHERE> filter, which is read and evaluated before the
remaining columns of the granule are fetched. The value is an ordinary
L<SQL::Abstract> condition with exactly the same bind semantics as C<where> --
it is rendered through C<_recurse_where>, not passed through as literal SQL --
and its bind values are assembled into their own slot so they land between the
C<FROM> binds and the C<WHERE> binds.

Because C<PREWHERE> is applied while reading the primary table, the condition
should only reference columns of that table.

Note that the condition is rendered without the extra parentheses core wraps
around C<WHERE>; this follows the C<HAVING> precedent in
C<DBIO::SQLMaker::ClassicExtensions::_parse_rs_attrs>.

=head2 limit_by

    $schema->resultset('Hit')->search(undef, {
      order_by => { -desc => 'ts' },
      limit_by => { rows => 3, by => 'user_id' },
      rows     => 100,
    });
    # ... ORDER BY `ts` DESC LIMIT 3 BY `user_id` LIMIT ?

Emits C<LIMIT n BY columns> -- "the first n rows per distinct value of
columns", ClickHouse's top-N-per-group without a window function. It has no
ANSI equivalent and slots between C<ORDER BY> and the ordinary
C<LIMIT>/C<OFFSET>, which no combination of core attributes can express.

The signature is a hashref reusing two names that already mean this elsewhere
in a DBIO attribute hash: C<rows> is the row count (as in the core C<rows>
attribute that becomes C<LIMIT>) and C<by> takes the same column spec as
C<group_by> (a name, an arrayref of names, or a C<\'literal'> scalar ref), fed
through the same C<_recurse_fields>. A flat arrayref such as
C<< [ 3, 'user_id' ] >> was rejected because it hides which element is the
count.

C<rows> is validated as a positive integer and rendered B<inline>, not as a
placeholder. ClickHouse wants a constant expression in the C<LIMIT> family, and
placeholder behaviour there over the MySQL wire protocol is not yet verified
against a live server; an integer that has passed C<< /\D/ >> carries no
injection surface. Revisit once the live suite has confirmed how the wire
handles bound C<LIMIT> arguments.

The C<LIMIT offset, n BY columns> form is not exposed -- use literal SQL if you
need the offset variant.

=head1 NOT IMPLEMENTED: SAMPLE

C<SAMPLE k> is deliberately B<not> given an attribute. It only works on tables
declared with a C<SAMPLE BY> expression in their engine definition (which the
DDL layer does not emit yet), and on any other table it is an error rather than
a no-op -- too little payoff for sugar that would look universally available.

Reach it with literal SQL instead, either through a result source whose name is
a literal-SQL scalar ref:

    __PACKAGE__->name(\'(SELECT * FROM hit SAMPLE 0.1)');

or by running the statement directly:

    $schema->storage->dbh_do(sub {
      $_[1]->selectall_arrayref('SELECT ... FROM hit SAMPLE 0.1 WHERE ...', undef, @bind);
    });

=head1 MUTATIONS

ClickHouse has no C<UPDATE> and no C<DELETE> statement. Row modification is an
B<asynchronous mutation>, spelled as an C<ALTER>:

    UPDATE `hit` SET `hits` = ? WHERE `id` = ?    # every other driver
    ALTER TABLE `hit` UPDATE `hits` = ? WHERE `id` = ? SETTINGS mutations_sync = 1

    DELETE FROM `hit` WHERE `id` = ?
    ALTER TABLE `hit` DELETE WHERE `id` = ? SETTINGS mutations_sync = 1

L</update> and L</delete> render that form, so C<< $rs->update >>,
C<< $rs->delete >>, C<< $row->update >> and C<< $row->delete >> work through
the ordinary DBIO API. Note the two differences from ANSI beyond the leading
C<ALTER TABLE>: there is B<no C<SET> keyword> (the assignment list follows
C<UPDATE> directly), and the C<WHERE> clause is B<mandatory> -- an unrestricted
resultset renders C<WHERE 1>, ClickHouse's spelling of "every row", rather than
omitting the clause and producing a syntax error.

Everything about the C<WHERE> clause itself is inherited: the same conditions,
the same operators, the same bind order. Only the surrounding statement changes.

What does B<not> change here is the semantics -- a mutation is not
transactional, is not atomic across statements, and is applied by rewriting
whole parts in the background. See L<DBIO::ClickHouse::Storage/MUTATIONS> for
the cost, the return value, and C<docs/adr/0005-mutations-sync-by-default.md>
for the C<mutations_sync> decision.

=head2 mutations_sync

Every rendered mutation carries a trailing C<SETTINGS mutations_sync = N>,
which is what makes the statement wait for the mutation instead of merely
queueing it. C<N> defaults to B<1> ("wait until the mutation is done on the
server we are talking to") and is a connect-time option:

    MyApp::Schema->connect($dsn, $user, $pass, { mutations_sync => 2 });

=over 4

=item * B<1> (the default) -- wait for completion on the current server. A
following C<SELECT> over the same connection sees the change.

=item * B<2> -- wait for completion on all replicas. Needed only when reads may
land on a different replica than the write; slower, and it blocks on every
replica being reachable.

=item * B<0> -- do not wait. The statement returns as soon as the mutation is
queued; a later error is never reported to the caller and a read straight
afterwards may still see the old rows.

=item * B<C<undef>> -- emit no C<SETTINGS> clause at all, so the server's own
setting applies. This is the escape hatch for setting the value per session
(C<< on_connect_do => ['SET mutations_sync = 2'] >>) or globally in the server
profile: with an explicit clause on every statement, a session-level C<SET>
would be silently overridden.

=back

Any other value throws at construction time rather than being sent to the
server.

=head1 SEE ALSO

=over 4

=item * L<DBIO::SQLMaker> - Base SQL generation class

=item * L<DBIO::ClickHouse::Storage> - Storage driver that uses this SQL maker

=item * L<DBIO::ClickHouse> - Top-level ClickHouse schema component

=back

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
