package DBIO::PostgreSQL::SQLMaker;
# ABSTRACT: PostgreSQL-specific SQL generation for DBIO

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::SQLMaker';

use JSON::MaybeXS ();
use DBIO::Util qw(is_literal_value);

my $JSON = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

my %JSONB_OP = (
  '@>' => '_where_op_jsonb_contains',
  '<@' => '_where_op_jsonb_contains',
  '@?' => '_where_op_jsonb_path',
  '@@' => '_where_op_jsonb_path',
  '?'  => '_where_op_jsonb_exists',
  '?|' => '_where_op_jsonb_exists',
  '?&' => '_where_op_jsonb_exists',
);

sub new {
  my $class = shift;
  my %opts  = ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;

  # Register the JSONB operators with the new-style expand_op mechanism (the
  # base DBIO::SQLMaker disables the old special_ops system). Each handler
  # keeps its original ($self, $col, $op, $val) -> ($sql, @bind) signature; we
  # wrap its output in a -literal node.
  for my $op (keys %JSONB_OP) {
    my $meth = $JSONB_OP{$op};
    $opts{expand_op}{$op} ||= sub {
      my ($self, $op, $v, $k) = @_;
      return +{ -literal => [ $self->$meth($k, $op, $v) ] };
    };
  }

  $class->next::method( \%opts );
}


sub _where_op_jsonb_contains {
  my ( $self, $col, $op, $val ) = @_;

  my $quoted = $self->_quote($col);

  if ( ref $val eq 'SCALAR' ) {
    return ( sprintf( '%s %s %s', $quoted, $op, $$val ), () );
  }

  my $json =
      ( ref $val eq 'HASH' || ref $val eq 'ARRAY' )
    ? $JSON->encode($val)
    : $val;    # already a JSON string

  return ( sprintf( '%s %s ?::jsonb', $quoted, $op ), $json );
}


sub _where_op_jsonb_path {
  my ( $self, $col, $op, $val ) = @_;

  my $quoted = $self->_quote($col);
  # the ? of the operator is no placeholder: written \?
  my $written = $op eq '@?' ? '@\?' : $op;
  return ( sprintf( '%s %s ?::jsonpath', $quoted, $written ), $val );
}


sub _where_op_jsonb_exists {
  my ( $self, $col, $op, $val ) = @_;

  my $quoted = $self->_quote($col);

  # the ? of the operator is no placeholder: written \?
  if ( $op eq '?' ) {
    return ( sprintf( '%s \? ?', $quoted ), $val );
  }

  my @keys = ref $val eq 'ARRAY' ? @$val : ($val);
  my $arr  = 'ARRAY[' . join( ', ', ('?') x scalar @keys ) . ']';

  return ( sprintf( '%s \%s %s', $quoted, $op, $arr ), @keys );
}


sub insert {
  my ($self, $table, $data, $options) = @_;

  # ADR 0036: the conflict structure MUST be consumed here. If it survives
  # into the generic DBIO::SQLMaker::ClassicExtensions::insert that path
  # throws -- deliberately, so "storage declares supports_upsert but its SQL
  # generator does not render the clause" fails loud instead of silently
  # emitting a plain INSERT.
  my $on_conflict = ref $options eq 'HASH'
    ? delete $options->{on_conflict}
    : undef;

  return $self->next::method($table, $data, $options) unless $on_conflict;

  # PostgreSQL grammar is INSERT ... ON CONFLICT ... RETURNING, but the
  # generic insert appends the RETURNING tail last. So hold the key back over
  # the call to the base, then append the two tails in engine order.
  #
  # It is put BACK afterwards: DBIO::Storage::DBI::insert reads
  # $sqla_opts->{returning} again after execution to know which columns the
  # statement handed back. Dropping it would silently cost the upsert its
  # identity (ADR 0036 section 4).
  my $returning = delete $options->{returning};

  my ($sql, @bind) = $self->next::method($table, $data, $options);

  my ($conflict_sql, @conflict_bind) = $self->_insert_on_conflict($on_conflict, $table);
  $sql .= $conflict_sql;
  push @bind, @conflict_bind;

  if (defined $returning) {
    $options->{returning} = $returning;
    my ($returning_sql, @returning_bind) = $self->_insert_returning($options);
    $sql .= $returning_sql;
    push @bind, @returning_bind;
  }

  return wantarray ? ($sql, @bind) : $sql;
}


sub _insert_on_conflict {
  my ($self, $on_conflict, $table) = @_;

  $self->throw_exception(
    'on_conflict must be a hashref of { target, action, set } (ADR 0036)'
  ) unless ref $on_conflict eq 'HASH';

  my $action = defined $on_conflict->{action} ? $on_conflict->{action} : 'update';
  $self->throw_exception(
    "on_conflict action must be 'update' or 'nothing', not '$action'"
  ) unless $action eq 'update' or $action eq 'nothing';

  # The conditional conflict branch rides on the update branch. Core refuses
  # the combination up front, so a structure that still carries both is
  # broken -- and dropping the condition here would produce a valid
  # statement, which is precisely the silent failure mode ADR 0036 section 3
  # gave this part of the structure its own capability for.
  #
  # exists, not defined: core sets the key only when it has a condition, so a
  # key that arrives here in ANY state -- undef included -- comes from a
  # structure that is already broken, and answering it with a valid DO NOTHING
  # is the one outcome with no symptom of its own.
  $self->throw_exception(
    "on_conflict where has no meaning with action 'nothing': there is no "
  . 'update branch to condition'
  ) if $action eq 'nothing' and exists $on_conflict->{where};

  my $target = $on_conflict->{target};
  my $target_sql;

  if (ref $target eq 'ARRAY') {
    $self->throw_exception('on_conflict target is an empty column list')
      unless @$target;
    $target_sql = '(' . join(', ', map { $self->_quote($_) } @$target) . ')';
  }
  elsif (ref $target eq 'HASH') {
    my $name    = $target->{constraint};
    my $columns = $target->{columns};

    $self->throw_exception(
      'on_conflict target hashref must be { constraint => $name }, '
    . '{ columns => \@columns } or both (ADR 0036)'
    ) unless ! grep { $_ ne 'constraint' and $_ ne 'columns' } keys %$target
         and ( defined $name or defined $columns )
         and ( ! defined $name    or ! length ref $name )
         and ( ! defined $columns or ref $columns eq 'ARRAY' );

    # key => $constraint arrives as BOTH halves (ADR 0036 section 2): the name
    # the caller used and the columns core resolved it to. Render the columns.
    #
    # A DBIO constraint name is client-side metadata from
    # add_unique_constraint and need not name anything PostgreSQL knows --
    # 'primary', which unique_constraint_names returns for the primary key,
    # exists in no database, so ON CONSTRAINT "primary" is a guaranteed
    # runtime error. The resolved columns name the very index the constraint
    # names, and they are correct whether or not the schema was deployed from
    # this metadata. ON CONSTRAINT stays reachable for the caller who really
    # means a server-side constraint (below), but it is not how a resolved
    # target is read.
    if (defined $columns) {
      $self->throw_exception('on_conflict target is an empty column list')
        unless @$columns;
      $target_sql = '(' . join(', ', map { $self->_quote($_) } @$columns) . ')';
    }
    else {
      # Name and no columns: nothing here can resolve it -- a SQLMaker gets
      # ($table, $data, $options) and no ResultSource -- so the name is taken
      # at face value as a server-side constraint. That is the opt-in the
      # paragraph above leaves open, and it is what an older core
      # (pre core k104, which passed the name alone) still sends.
      $target_sql = $self->_sqlcase('on constraint ') . $self->_quote($name);
    }
  }
  elsif (defined $target and ! length ref $target and $target eq 'any') {
    # 'any' is MySQL's target-less ON DUPLICATE KEY UPDATE. PostgreSQL's
    # grammar has no such thing for DO UPDATE -- the arbiter index has to be
    # named -- so this is an error rather than a guess at which constraint the
    # caller meant. DO NOTHING is fine without a target, and that combination
    # is the portable "insert unless it is already there" (ADR 0036 section 1).
    $self->throw_exception(
      "PostgreSQL cannot DO UPDATE on an unspecified conflict target: "
    . "ON CONFLICT DO UPDATE requires the arbiter index to be named. Pass "
    . "conflict_target => \\\@columns or key => \$constraint_name. "
    . "conflict_target => 'any' is only portable together with "
    . "on_conflict => 'nothing'"
    ) if $action eq 'update';
  }
  else {
    $self->throw_exception(
      "on_conflict target must be an arrayref of columns, "
    . "{ constraint => \$name, columns => \\\@columns }, or the string 'any'"
    );
  }

  my $sql = $self->_sqlcase(' on conflict');
  $sql .= " $target_sql" if defined $target_sql;

  return ($sql . $self->_sqlcase(' do nothing')) if $action eq 'nothing';

  my $set = $on_conflict->{set};
  $self->throw_exception(
    'on_conflict action update needs a non-empty set of columns to write'
  ) unless ref $set eq 'HASH' and keys %$set;

  my (@set_sql, @bind);
  for my $col (sort keys %$set) {
    my $lhs = $self->_quote($col);
    my $val = $set->{$col};

    if (ref $val eq 'HASH') {
      # -attempted is the engine-neutral core token for "the value this
      # statement tried to insert". On PostgreSQL that is the EXCLUDED
      # pseudo-row. The value names the source column, which need not be the
      # column being written.
      my ($key, @extra) = keys %$val;
      my $src = $val->{'-attempted'};

      $self->throw_exception(
        "on_conflict set for '$col' must be { -attempted => \$column }, a "
      . 'literal, or a plain value'
      ) unless ! @extra and defined $key and $key eq '-attempted'
           and defined $src and ! length ref $src;

      push @set_sql, sprintf '%s = %s',
        $lhs, $self->_upsert_attempted_sql($src);
    }
    elsif (my $literal = is_literal_value($val)) {
      my ($literal_sql, @literal_bind) = @$literal;
      push @set_sql, "$lhs = $literal_sql";
      push @bind, @literal_bind;
    }
    else {
      push @set_sql, "$lhs = ?";
      # The maker's own bindtype shapes the bind: [ $col => $val ] under
      # 'columns' (the sync driver), the bare value under 'normal' (the
      # future_io and ev transports build their maker without one). A pair
      # pushed by hand among bare values reaches the driver as an array
      # (karr k122).
      push @bind, $self->_bindtype($col, $val);
    }
  }

  $sql .= $self->_sqlcase(' do update set ') . join(', ', @set_sql);

  # ADR 0036 section 1 (core k105): the conditional conflict branch. The key
  # exists only when the caller passed update_where, so every call written
  # before the option existed still renders byte-identical SQL. PostgreSQL
  # wants the condition after the SET list and before RETURNING, and its
  # binds go in at that same position.
  #
  # exists, not defined: the key being there at all is the caller asking for a
  # conditional branch, and every state of it that cannot become a condition
  # has to end in the throw below rather than in an unconditional DO UPDATE.
  if (exists $on_conflict->{where}) {
    my $where = $on_conflict->{where};

    # undef is not a condition, so it never reaches the renderer -- whether
    # SQL::Abstract tolerates it, warns or dies is a dependency's business, and
    # the message below is not going to be left to it. It falls through to the
    # same throw with an empty render.
    my ($where_sql, @where_bind) = defined $where
      ? $self->_upsert_condition_sql($where, $table)
      : ()
    ;

    $self->throw_exception(
      'on_conflict where rendered to an empty condition -- an unconditional '
    . 'DO UPDATE is the overwrite the condition exists to prevent'
    ) unless defined $where_sql and length $where_sql;

    $sql .= $self->_sqlcase(' where ') . $where_sql;
    push @bind, @where_bind;
  }

  return ($sql, @bind);
}


sub _upsert_attempted_sql {
  my ($self, $col) = @_;
  return $self->_sqlcase('excluded') . '.' . $self->_quote($col);
}



sub select {
  my $self = shift;

  # The base _lock_select only receives $rs_attrs->{for}, but the PostgreSQL
  # row-lock modifiers ride on the sibling attributes skip_locked / nowait.
  # Stash the whole rs_attrs (4th positional: table, fields, where, rs_attrs)
  # for the duration of the base call so our _lock_select override can read
  # them. local restores it afterwards and keeps nested selects independent.
  local $self->{_pg_row_lock_attrs} = $_[3];

  return $self->next::method(@_);
}

sub _lock_select {
  my ($self, $type) = @_;

  my $sql = $self->next::method($type);

  my $attrs       = $self->{_pg_row_lock_attrs} || {};
  my $skip_locked = $attrs->{skip_locked};
  my $nowait      = $attrs->{nowait};

  $self->throw_exception(
    "The row-lock options 'skip_locked' and 'nowait' are mutually exclusive"
  ) if $skip_locked && $nowait;

  $sql .= ' SKIP LOCKED' if $skip_locked;
  $sql .= ' NOWAIT'      if $nowait;

  return $sql;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::SQLMaker - PostgreSQL-specific SQL generation for DBIO

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

L<DBIO::SQLMaker> subclass for PostgreSQL. Extends standard SQL generation
with native support for PostgreSQL JSONB operators.

Used automatically by L<DBIO::PostgreSQL::Storage> — the C<sql_maker_class>
is set on the storage and this class is instantiated transparently whenever a
PostgreSQL connection is opened.

=head2 Containment: C<@>> and C<<@>

Tests whether a JSONB value contains (or is contained by) another JSONB
value. The RHS hashref or arrayref is JSON-encoded automatically.

  $rs->search({ 'me.data' => { '@>' => { status => 'active' } } });
  # WHERE "me"."data" @> '{"status":"active"}'::jsonb

  $rs->search({ 'me.tags' => { '<@' => ['a', 'b'] } });
  # WHERE "me"."tags" <@ '["a","b"]'::jsonb

=head2 Key existence: C<?>, C<?|>, C<?&>

Tests whether a JSONB object has a specific key (or any/all keys from a list).
These operators are rewritten as C<jsonb_exists*()> functions to avoid
conflicts with DBI's C<?> placeholder syntax.

  $rs->search({ 'me.data' => { '?'  => 'email' } });
  # WHERE jsonb_exists("me"."data", ?)

  $rs->search({ 'me.data' => { '?|' => [qw(email phone)] } });
  # WHERE jsonb_exists_any("me"."data", ARRAY[?, ?])

  $rs->search({ 'me.data' => { '?&' => [qw(name email)] } });
  # WHERE jsonb_exists_all("me"."data", ARRAY[?, ?])

=head2 JSONPath: C<@?> and C<@@> (PostgreSQL 12+)

Evaluates a JSONPath expression against a JSONB value.

  $rs->search({ 'me.data' => { '@?' => '$.status == "active"' } });
  # WHERE "me"."data" @\? ?::jsonpath

  $rs->search({ 'me.data' => { '@@' => '$.score > 10' } });
  # WHERE "me"."data" @@ ?::jsonpath

The jsonpath is a bind value. The C<?> of the operator C<@?> is written
C<\?>, a question mark that is no placeholder: C<as_query> shows C<@\?>, the
server gets C<@?>. Literal SQL that uses the operator writes it the same way
wherever the statement is prepared; C<< $dbh->do >> without bind values sends
a statement as it is, backslash included.

=head2 Path extraction

For comparing individual fields within a JSONB value, see
L<DBIO::PostgreSQL::JSONB> which provides the C<jsonb()> path expression
helper:

  use DBIO::PostgreSQL::JSONB qw(jsonb);
  $rs->search( jsonb('me.data', 'status')->eq('active') );
  # WHERE (me.data->>?) = ?

=head1 METHODS

=head2 new

Extends the base constructor to register the JSONB operators (C<< @> >>,
C<< <@ >>, C<@?>, C<@@>, C<?>, C<?|>, C<?&>) as C<expand_op> handlers. Called
automatically by L<DBIO::PostgreSQL::Storage> — no need to instantiate this
class directly.

=head2 _where_op_jsonb_contains

Handles the C<@>> (contains) and C<<@> (contained by) operators.

The RHS may be:

=over 4

=item * B<hashref or arrayref> — JSON-encoded automatically and bound with a
C<::jsonb> cast:

  { 'me.data' => { '@>' => { status => 'active' } } }
  # WHERE "me"."data" @> '{"status":"active"}'::jsonb

  { 'me.tags' => { '@>' => ['admin', 'user'] } }
  # WHERE "me"."tags" @> '["admin","user"]'::jsonb

  { 'me.data' => { '<@' => { role => 'guest' } } }
  # WHERE "me"."data" <@ '{"role":"guest"}'::jsonb

=item * B<plain string> — treated as a pre-encoded JSON string, bound as-is:

  { 'me.data' => { '@>' => '{"status":"active"}' } }
  # WHERE "me"."data" @> '{"status":"active"}'::jsonb

=item * B<scalar ref> — embedded as literal SQL without binding (use for
sub-selects or other column references):

  { 'me.data' => { '@>' => \'other_col' } }
  # WHERE "me"."data" @> other_col

=back

=head2 _where_op_jsonb_path

Handles C<@?> (jsonpath predicate) and C<@@> (jsonpath match) operators
(PostgreSQL 12+). The RHS is bound with a C<::jsonpath> cast.

  { 'me.data' => { '@?' => '$.status == "active"' } }
  # WHERE "me"."data" @\? ?::jsonpath

  { 'me.data' => { '@@' => '$.score > 10' } }
  # WHERE "me"."data" @@ ?::jsonpath

The operator C<@?> is written C<@\?>, and that is what C<as_query> shows. A
C<?> in a statement is a placeholder; C<\?> is a question mark that is none.
L<DBD::Pg> reads it so and sends C<@?> to the server, and a transport that
numbers the placeholders itself reads it the same way
(L<DBIO::PostgreSQL::Util/number_placeholders>). The statement has one
placeholder for its one bind on every way it is sent.

=head2 _where_op_jsonb_exists

Handles the C<?> (key exists), C<?|> (any key exists), and C<?&> (all keys
exist) operators. They are written as the operators, not as the functions
behind them (C<jsonb_exists()>, C<jsonb_exists_any()>, C<jsonb_exists_all()>):
the planner answers an operator from a GIN index over the column and does not
see through a function call. The C<?> of the operator is written C<\?>, as
that of C<@?> is and for the same reason (see L</_where_op_jsonb_path>).

  { 'me.data' => { '?'  => 'email' } }
  # WHERE "me"."data" \? ?

  { 'me.data' => { '?|' => [qw(email phone)] } }
  # WHERE "me"."data" \?| ARRAY[?, ?]

  { 'me.data' => { '?&' => [qw(name email)] } }
  # WHERE "me"."data" \?& ARRAY[?, ?]

A single string is accepted for C<?|> and C<?&> as a convenience (treated as
a one-element list):

  { 'me.data' => { '?|' => 'email' } }
  # WHERE "me"."data" \?| ARRAY[?]

=head2 insert

Extends the generic insert with the atomic-upsert conflict clause (ADR 0036).
When C<< $options->{on_conflict} >> is present it is consumed here and rendered
by L</_insert_on_conflict>; the clause is placed between the C<VALUES> list and
the C<RETURNING> tail, which is where PostgreSQL's grammar wants it. A
conditional C<DO UPDATE> puts its C<WHERE> inside that clause, after the
C<SET> list and still before C<RETURNING>.

A plain insert (no C<on_conflict> key) is passed straight through untouched.

=head2 _insert_on_conflict

  my ($sql_tail, @bind) = $sqlmaker->_insert_on_conflict(\%on_conflict);

Renders the normalized conflict structure that L<DBIO::ResultSet/upsert> builds
into a PostgreSQL C<ON CONFLICT> tail. Mirrors C<_insert_returning>: it returns
a leading-space SQL fragment plus its bind values, and appends nothing to the
statement itself.

The structure is C<< { target => ..., action => ..., set => ..., where => ... } >>,
where C<where> is present only when the caller passed C<update_where>:

=over 4

=item * C<< target => \@columns >> — C<ON CONFLICT ("a", "b")>

=item * C<< target => { constraint => $name, columns => \@columns } >> — the
shape C<< key => $constraint >> resolves to. B<The columns are rendered>:
C<ON CONFLICT ("a", "b")>. A DBIO constraint name is client-side metadata from
C<add_unique_constraint> and need not name anything the server knows —
C<'primary'> never does — while the resolved columns name the same index and
are correct in every case (ADR 0036 section 2).

=item * C<< target => { constraint => $name } >> — a name and no columns, which
nothing here can resolve, is taken at face value as a I<server-side> constraint:
C<ON CONFLICT ON CONSTRAINT "name">. Core no longer sends this shape; it is the
explicit opt-in for a caller who really means a named constraint (and what a
core that still sends the constraint name passes).

=item * C<< target => 'any' >> — no target. Valid only with
C<< action => 'nothing' >>; with C<< action => 'update' >> it throws, because
PostgreSQL requires the arbiter index to be named for C<DO UPDATE>.

=item * C<< action => 'nothing' >> — C<DO NOTHING>

=item * C<< action => 'update' >> — C<DO UPDATE SET ...> from C<set>

=item * C<< where => $cond >> — C<DO UPDATE SET ... WHERE $cond>, rendered by
L</_upsert_condition_sql> after the C<SET> list and before C<RETURNING>.
Absent unless the caller asked for a condition.

=back

Every route to a I<dropped> condition throws instead of rendering, because the
statement left behind is a perfectly valid unconditional C<DO UPDATE> — the
overwrite C<update_where> exists to prevent, and the one failure mode with no
symptom of its own. Those routes are a C<where> on the
C<< action => 'nothing' >> branch (there is no update branch for it to
condition), an undef one (core sets the key only when it has a condition, so
the key alone is enough to mean one was asked for), and one that renders to an
empty string (C<< { -and => [] } >>, which core does not walk).

Each value in C<set> is one of:

=over 4

=item * C<< { -attempted => $column } >> — the value the statement tried to
insert, rendered as C<< EXCLUDED."$column" >>

=item * a literal (C<< \'count + 1' >> or C<< \['count + ?', 1] >>) — inlined
verbatim, its bind values passed through

=item * anything else — a placeholder plus a bind value, in the shape of the
maker's C<bindtype>: C<< [ $column => $value ] >> under C<columns> (the sync
driver), the bare value under C<normal> (the future_io and ev transports)

=back

=head2 _upsert_attempted_sql

  my $sql = $sqlmaker->_upsert_attempted_sql('updated_at');
  # EXCLUDED."updated_at"

The engine-specific half of the upsert condition (ADR 0036): renders core's
engine-neutral C<< { -attempted => $column } >> marker as the PostgreSQL
C<EXCLUDED> pseudo-row reference. This is the hook the core helper
L<DBIO::SQLMaker::ClassicExtensions/_upsert_attempted_sql> calls for the
token — core has no default for it and throws, because the pseudo-row
spelling is engine grammar. One method for both places the marker can appear —
the C<set> list and the conditional branch — so the two halves of the same
statement can never spell it differently.

=head2 _upsert_condition_sql

  my ($sql, @bind) = $sqlmaker->_upsert_condition_sql(\%cond, $table);

The C<where> half of the conflict structure — the condition of the
C<DO UPDATE> branch (ADR 0036 section 1). This is the core
helper L<DBIO::SQLMaker::ClassicExtensions/_upsert_condition_sql>, inherited
from L<DBIO::SQLMaker>; the substitution mechanics — registering the marker
as an SQL::Abstract operator for the duration of the call, and why a
C<-literal> is right in every position — live there, not here. The helper
returns the bare condition without the C<WHERE> keyword, like C<_recurse_where>
does, plus its bind values; L</_insert_on_conflict> splices both in after the
C<SET> list.

C<$table> is the target table the statement inserts into; L</insert> threads it
through so the stored-side columns can be qualified with it (see below). It is
optional, and omitting it renders the pre-k205 unqualified condition.

Two vocabularies, both engine-neutral:

=over 4

=item * an B<unqualified column> is the B<stored> row — the row the statement
collided with. In an C<ON CONFLICT DO UPDATE> branch that row shares the scope
with the attempted-values pseudo-row (C<EXCLUDED>), so a bare column is
B<ambiguous> to the engine — PostgreSQL rejects it outright ("column reference
is ambiguous"). Given C<$table>, every bare (single-part) column is
therefore qualified with the target table, at B<any> depth; an already-qualified
column (it carries its own table part) and the C<< { -attempted } >> marker are
left exactly as they are.

=item * C<< { -attempted => $column } >> is the value the statement B<tried to
insert>, rendered as C<< EXCLUDED."$column" >> — the same marker the C<set>
list uses, but here it may appear at any depth.

=back

  # with $table = 'artist':
  { updated_at => { '<' => { -attempted => 'updated_at' } } }
  # "artist"."updated_at" < EXCLUDED."updated_at"   -- the last-write-wins guard

A literal (C<< \'excluded.rank > artist.rank' >> or C<< \[ $sql, @bind ] >>)
passes through untouched, for conditions the abstract form cannot express.

=head2 select

Extends the base C<select> only to stash the resolved search attributes so the
L</_lock_select> override below can see the C<skip_locked> / C<nowait> siblings
of the C<for> attribute. The SQL is otherwise generated entirely by the base.

=head2 _lock_select

Renders the row-locking tail. The C<FOR UPDATE> / C<FOR SHARE> keyword still
comes from the base; this override appends the PostgreSQL wait-policy modifier
when the search carries one:

  $rs->search({}, { for => 'update', skip_locked => 1 });
  # ... FOR UPDATE SKIP LOCKED

  $rs->search({}, { for => 'update', nowait => 1 });
  # ... FOR UPDATE NOWAIT

  $rs->search({}, { for => 'shared', skip_locked => 1 });
  # ... FOR SHARE SKIP LOCKED

C<skip_locked> and C<nowait> are mutually exclusive — PostgreSQL rejects both
on one lock clause — so setting both throws.

=head1 SEE ALSO

=over 4

=item * L<DBIO::PostgreSQL::Storage> — PostgreSQL storage (uses this SQL maker)

=item * L<DBIO::PostgreSQL::JSONB> — path expression DSL for JSONB columns

=item * L<DBIO::SQLMaker> — base SQL maker class

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
