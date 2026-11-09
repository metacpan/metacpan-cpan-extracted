package DBIO::ClickHouse::Storage;
# ABSTRACT: ClickHouse storage driver for DBIO (MySQL wire protocol)

use strict;
use warnings;

our $VERSION = '0.900004';

use base qw/DBIO::Storage::DBI/;
use mro 'c3';

use DBIO::Carp;
use DBIO::Storage::BlockRunner;
use DBIO::ClickHouse::Storage::TxnScopeGuard;
use Crypt::URandom ();
use Math::BigInt ();
use DBIO::ClickHouse::DDL ();
use DBIO::ClickHouse::Util ();
use Scalar::Util ();
use Try::Tiny;
use namespace::clean;

__PACKAGE__->register_driver('ClickHouse' => __PACKAGE__);

__PACKAGE__->sql_maker_class('DBIO::ClickHouse::SQLMaker');
__PACKAGE__->sql_quote_char('`');

# F02 / F10: ClickHouse has no transactions at all (ADR 0003), so DDL cannot
# be transactional either. Core's default for an undeclared capability is
# already 0, but leaving it undeclared would make the deploy path depend on
# that default rather than on a statement by this driver: DBIO::Deploy::Base
# ::_execute_ddl brackets its DDL loop in $storage->txn_do only when this
# reports true, and our txn_do neither brackets nor rolls back (L</txn_do>,
# L</txn_rollback>). A truthy value here would therefore buy a promise of
# atomicity we cannot keep. Declared, and pinned by t/17-capabilities.t.
__PACKAGE__->_use_transactional_ddl(0);

# F12: ClickHouse parses IF EXISTS / IF NOT EXISTS on the object kinds this
# driver emits DDL for -- CREATE/DROP DATABASE, CREATE/DROP TABLE,
# ALTER TABLE ADD/DROP COLUMN and ADD/DROP INDEX -- so a re-applied diff can
# no-op instead of erroring after a partial failure; probed against a live
# server by t/38-ddl-if-exists-live.t. Core's
# DBIO::Diff::Op::should_emit_if_exists reads this declaration, which
# t/17-capabilities.t pins. Declaring it still changes no rendered statement:
# the diff ops here never call that helper, and DBIO::ClickHouse::DDL::Emit's
# drop_table / alter_table_* forms take no if_exists. This is the engine fact,
# not a claim about what the diff currently emits.
__PACKAGE__->_use_supports_if_exists(1);

# ADR 0037: ClickHouse accepts core's base rendering of _exists_value_sql
#
#   SELECT CASE WHEN EXISTS (<subquery>) THEN 1 ELSE 0 END
#
# unchanged, so this driver declares the capability and overrides nothing.
# Checked against the documentation rather than assumed -- the capability
# defaults to 0 exactly so an unchecked engine is never handed that SQL, and
# ADR 0037 listed ClickHouse among the unchecked. All three assumptions the
# fragment stacks hold:
#
#   1. EXISTS used as a *value*, not only as a predicate. ClickHouse
#      documents it as returning 0 or 1 ("If it is empty, then the operator
#      returns 0. Otherwise, it returns 1") and its own example selects two
#      of them straight into a select list -- sql-reference/operators/exists.
#      Available since 21.11 ("Support EXISTS(subquery)", CH #29731).
#   2. A SELECT with no FROM: that same documented example is literally
#      "SELECT EXISTS(...), EXISTS(...)" with no FROM clause.
#   3. CASE WHEN ... THEN ... ELSE ... END: documented under Conditional
#      Functions / "CASE statement", lowered internally to multiIf().
#
# The one thing left to check was the space core leaves between EXISTS and
# the subquery -- the documentation only ever writes EXISTS(subquery), and
# ClickHouse parses it through its *function* layer (ExistsLayer, in
# src/Parsers/ExpressionListParsers.cpp), not as a prefix operator. It parses
# either way: whitespace never reaches the parser (src/Parsers/TokenIterator.h
# -- "All whitespace and comment tokens are transparently skipped"). So no
# override, and none for ADR 0037's third assumption either: "AS" before a
# derived-table alias is unreachable since that ADR dropped the wrapper.
#
# Not covered by a live test (the karr k15 suite run passed, but no live file
# asserts an EXISTS subquery) and one documented limit is deliberately NOT
# hidden by this declaration: the subquery may not reference the outer query
# (L</EXISTS QUERIES>).
__PACKAGE__->_use_supports_exists_query(1);


sub sql_maker {
  my $self = shift;
  my $sm = $self->next::method(@_);
  $sm->{quote_char} //= $self->sql_quote_char;
  $sm->{name_sep}   //= $self->sql_name_sep;
  $sm;
}


__PACKAGE__->register_access_path_dbd(qw( mysql MariaDB ));


sub _determine_supports_insert_returning { 0 }


sub _prefetch_autovalues {
  my ($self, $source, $colinfo, $to_insert) = @_;

  my $values = $self->next::method($source, $colinfo, $to_insert);

  for my $col (keys %$colinfo) {
    next unless $colinfo->{$col}{is_auto_increment};
    next unless _is_uuid_type($colinfo->{$col});

    # An explicitly supplied value always wins, literal SQL included. undef
    # counts as "not supplied", the same reading core applies in insert().
    next if defined $to_insert->{$col};

    $values->{$col} = $self->_generate_uuid;
  }

  return $values;
}

# Must stay in lockstep with DBIO::ClickHouse::DDL::_is_uuid_type: the DDL
# layer emits DEFAULT generateUUIDv4() for exactly the columns this driver
# generates a UUID for. t/13-insert.t asserts the two agree.
sub _is_uuid_type {
  my ($info) = @_;
  return (($info->{data_type} // '') =~ /\A(?:uuid|guid|uniqueidentifier)\z/i) ? 1 : 0;
}


sub _generate_uuid {
  my $bytes = Crypt::URandom::urandom(16);

  # RFC 4122 section 4.4: version nibble in byte 6, variant bits in byte 8.
  vec($bytes, 6, 8) = (vec($bytes, 6, 8) & 0x0f) | 0x40;
  vec($bytes, 8, 8) = (vec($bytes, 8, 8) & 0x3f) | 0x80;

  return join '-', unpack 'H8H4H4H4H12', $bytes;
}


sub last_insert_id {
  my ($self, $source, @cols) = @_;

  my $where = ( ref $source and $source->can('source_name') )
    ? $source->source_name
    : 'this result source';

  $self->throw_exception(sprintf
    'ClickHouse has no auto-increment and no last_insert_id(), so the primary '
  . 'key of the row just inserted into %s (column%s %s) cannot be read back -- '
  . 'the row itself was written. Supply the key as a plain value, or, for a '
  . q{surrogate key, declare the column as data_type => 'uuid', }
  . 'is_auto_increment => 1: this driver then generates a UUID client-side and '
  . 'sends it, so the stored row and the value you get back are the same. '
  . 'is_auto_increment on any other type is refused by the DDL layer -- '
  . 'ClickHouse has no server-side generator for it. A key left to a DEFAULT or written as '
  . q{literal SQL (\'generateUUIDv4()') is computed by the server, which is }
  . 'the same unreadable case: use populate(), which never needs the key back',
    $where,
    (@cols == 1 ? '' : 's'),
    (@cols ? join(', ', map { "'$_'" } @cols) : '(none named)')
  );
}


sub _insert_bulk {
  my ($self, $source, $cols, $data) = @_;

  $self->throw_exception(
    'Calling _insert_bulk without a dataset to process makes no sense'
  ) unless @{ $data || [] };

  return $self->_execute('insert_multi', $source, $cols, $data);
}


sub _prep_for_execute {
  my ($self, $op, $ident, $args) = @_;

  my ($sql, $bind) = $self->next::method($op, $ident, $args);

  $self->_refuse_non_numeric_binds($ident, $bind)
    if $op eq 'insert' or $op eq 'insert_multi' or $op eq 'update';

  return ($sql, $bind);
}

my $NUMBER = {
  integer => qr/\A[+-]?\d+\z/,
  float   => qr/\A(?:[+-]?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?|[+-]?(?:inf|nan))\z/i,
  decimal => qr/\A[+-]?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?\z/,
};

# The numeric family of a column's data_type, or undef: portable names
# (integer, bigint, double, numeric ...) and the native ones (Int32, UInt8,
# Float64, Decimal(10, 2), Nullable(Int64) ...).
sub _numeric_kind {
  my ($data_type) = @_;
  return undef unless defined $data_type;
  my $t = lc $data_type;
  1 while $t =~ s/\A\s*(?:nullable|lowcardinality)\s*\((.*)\)\s*\z/$1/;
  $t =~ s/\s+unsigned\z//;
  return 'integer' if $t =~ /\A(?:u?int(?:8|16|32|64|128|256)?|tinyint|smallint|mediumint|integer|bigint|serial|bigserial)\z/;
  return 'float'   if $t =~ /\A(?:float(?:32|64)?|real|double(?:\s+precision)?)\z/;
  return 'decimal' if $t =~ /\A(?:decimal(?:32|64|128|256)?|numeric|number|money)\s*(?:\(.*\))?\z/;
  return undef;
}

# The native integer type of the bind's column (Int8 .. UInt256), or undef:
# the column's own info when the statement's source has it (so extra =>
# { unsigned => 1 } counts), else the bind's data type -- through the one type
# map the DDL deploys with, Nullable and LowCardinality looked through.
sub _integer_type {
  my ($ident, $attrs) = @_;

  my $col  = $attrs->{dbic_colname};
  my $info = Scalar::Util::blessed($ident) && $ident->can('has_column')
    && $ident->has_column($col) ? $ident->column_info($col) : undef;
  $info = { data_type => $attrs->{sqlt_datatype} } unless $info and defined $info->{data_type};

  my %info = %$info;
  $info{extra} = { %{ $info{extra} || {} }, unsigned => 1 }
    if $info{data_type} =~ s/\s+unsigned\z//i;

  my $type = DBIO::ClickHouse::DDL->column_type(\%info);
  1 while $type =~ s/\A(?:Nullable|LowCardinality)\((.*)\)\z/$1/;
  return $type =~ /\AU?Int(?:8|16|32|64|128|256)\z/ ? $type : undef;
}

my %RANGE;

# True when the integer string $value does not fit the native type.
sub _outside_range {
  my ($value, $type) = @_;

  my ($min, $max) = @{ $RANGE{$type} ||= do {
    my ($u, $bits) = $type =~ /\A(U?)Int(\d+)\z/;
    $u ? [ Math::BigInt->bzero, Math::BigInt->new(2)->bpow($bits)->bdec ]
       : [ Math::BigInt->new(2)->bpow($bits - 1)->bneg,
           Math::BigInt->new(2)->bpow($bits - 1)->bdec ];
  } };

  my $n = Math::BigInt->new($value =~ s/\A\+//r);
  return ($n < $min or $n > $max) ? 1 : 0;
}

sub _refuse_non_numeric_binds {
  my ($self, $ident, $bind) = @_;

  for my $item (@{ $bind || [] }) {
    my ($attrs, $value) = @$item;
    next unless defined $value and not ref $value;
    next unless ref $attrs eq 'HASH' and defined $attrs->{dbic_colname};

    my $kind = _numeric_kind($attrs->{sqlt_datatype}) or next;
    my $table = Scalar::Util::blessed($ident) && $ident->can('name') ? $ident->name : undef;

    if ($value =~ $NUMBER->{$kind}) {
      next unless $kind eq 'integer';

      my $native = _integer_type($ident, $attrs);
      next unless defined $native and _outside_range($value, $native);

      $self->throw_exception(sprintf
        'DBIO::ClickHouse: table %s, column %s: the value is refused, it is '
      . 'outside the range of %s. ClickHouse accepts such a number and stores '
      . 'NULL (a Nullable column) or a wrapped-around number (any other) '
      . 'without an error. Nothing was sent',
        (defined $table and not ref $table) ? $table : '(statement)',
        $attrs->{dbic_colname},
        $native,
      );
    }

    $self->throw_exception(sprintf
      'DBIO::ClickHouse: table %s, column %s: the value is refused, it is not '
    . 'a%s number. ClickHouse accepts such a string for a %s column and stores '
    . 'NULL without an error. Nothing was sent',
      (defined $table and not ref $table) ? $table : '(statement)',
      $attrs->{dbic_colname},
      $kind eq 'integer' ? 'n integer' : '',
      $attrs->{sqlt_datatype},
    );
  }
}


sub update {
  my $self = shift;
  $self->next::method(@_);
  return -1;
}

sub delete {
  my $self = shift;
  $self->next::method(@_);
  return -1;
}


sub _dbio_sql_maker_option_names {
  my $self = shift;
  return ($self->next::method(@_), 'mutations_sync');
}


sub _adjust_select_args_for_complex_prefetch {
  my $self = shift;
  my $outer_attrs = $self->next::method(@_);
  delete @{$outer_attrs}{qw( final prewhere limit_by )};
  return $outer_attrs;
}


# ADR 0039. This is the case ADR 0037 section 3 predicted and ADR 0039
# recorded as never having turned up -- a second engine that *spells* a set
# operation differently rather than lacking it. It is not one operation but
# three, and the reason is sharper than Oracle's MINUS: ClickHouse does not
# disagree about the word for an operation, it disagrees about what the word
# without a modifier means. A bare keyword there is resolved from a session
# setting -- union_default_mode ships empty (a bare UNION throws, changed to
# throw in 21.1), intersect_default_mode and except_default_mode ship 'ALL'
# (a bare INTERSECT/EXCEPT keeps duplicates). So core's ANSI spelling is a
# hard error for one operation and a silently different result set for two.
# Spelling all three explicitly is also what makes the statement immune to
# those settings.
my %SET_OPERATION_KEYWORD = (
  union     => 'UNION DISTINCT',
  intersect => 'INTERSECT DISTINCT',
  except    => 'EXCEPT DISTINCT',
);

sub _set_operation_keyword {
  my ($self, $op) = @_;

  return $SET_OPERATION_KEYWORD{$op}
    if defined $op and exists $SET_OPERATION_KEYWORD{$op};

  # Everything this driver has no opinion about -- including an unknown $op,
  # which is a core programming error and belongs to core's throw.
  return $self->next::method($op);
}


# The value this returns is never seen by anyone: core drops the string into
# an order_by literal and nowhere else, so only the induced ORDER is
# observable and a uniform UInt32 orders as uniformly as randCanonical()'s
# Float64 would -- while working on every ClickHouse back to 1.1 instead of
# 22.11. The trap the choice has to avoid is randConstant(), documented as one
# value for the whole query: ORDER BY that is a non-shuffle with no error at
# all. rand() is a regular function and random numbers are the documented
# exception to constant folding, i.e. per row. See L</RANDOM ORDERING>.
sub _random_function { 'rand()' }

# _explain_query is deliberately NOT overridden (ADR 0040). ClickHouse's bare
# EXPLAIN *is* EXPLAIN PLAN -- one statement, executed with the query's own
# binds, answering with the plan as rows -- which is precisely core's base
# implementation, so an override could only re-spell what is already right.
# The non-override is pinned by t/43-random-and-explain.t so it cannot decay
# into a half-considered EXPLAIN AST / PIPELINE / ESTIMATE later. See
# L</QUERY PLANS>.


sub _exec_txn_begin  { shift->_warn_no_transactions }

sub _exec_txn_commit { shift->_warn_no_transactions }

sub _warn_no_transactions {
  carp_once(
    'ClickHouse has no transactions: txn_begin() and txn_commit() are no-ops. '
  . 'Nothing this storage writes is atomic, and nothing can be rolled back'
  );
}


sub txn_do {
  my $self = shift;

  carp_once(
    'ClickHouse has no transactions: txn_do() runs its coderef without '
  . 'BEGIN/COMMIT. The block is not atomic -- a failure part-way through '
  . 'leaves every completed statement in place'
  );

  # take a ref instead of a copy, to preserve @_ aliasing semantics within the
  # coderef (same trick as core's dbh_do)
  my $args = @_ ? \@_ : [];

  my $runner = DBIO::Storage::BlockRunner->new(
    storage       => $self,
    wrap_txn      => 0,
    retry_handler => sub { 0 },
  );

  return try {
    $runner->run(@$args);
  }
  catch {
    my $err = $_;
    carp(
      'txn_do() failed on ClickHouse and NOTHING WAS ROLLED BACK: every '
    . 'statement the block completed before the failure is permanent. '
    . 'Check your data for consistency'
    );
    die $err;
  };
}


sub txn_rollback {
  my $self = shift;

  # Unwind core's depth bookkeeping before refusing. Nothing was begun on the
  # server, but a stuck transaction_depth would make every later statement
  # believe it runs inside a transaction. The rest of core's rollback state is
  # dead here: savepoints always throw, and this is the only rollback path, so
  # the deferred-rollback machinery is never armed.
  my $depth = $self->transaction_depth;
  $self->transaction_depth($depth - 1) if $depth;

  $self->throw_exception(
    'ClickHouse has no transactions: txn_rollback() cannot undo anything -- '
  . 'every statement issued so far is already permanent. Remove the rollback '
  . 'or handle the partial write explicitly'
  );
}


sub txn_scope_guard {
  my $self = shift;
  return DBIO::ClickHouse::Storage::TxnScopeGuard->new($self);
}


sub _exec_svp_begin {
  my ($self, $name) = @_;
  $self->throw_exception('ClickHouse does not support savepoints');
}

sub _exec_svp_release {
  my ($self, $name) = @_;
  $self->throw_exception('ClickHouse does not support savepoints');
}

sub _exec_svp_rollback {
  my ($self, $name) = @_;
  $self->throw_exception('ClickHouse does not support savepoints');
}


sub _ping {
  my $self = shift;
  my $dbh = $self->_dbh or return undef;
  return undef unless $dbh->FETCH('Active');
  return try { $dbh->do('SELECT 1'); 1 } catch { undef };
}


sub clickhouse_version {
  my $self = shift;
  my ($v) = $self->_get_dbh->selectrow_array('SELECT version()');
  return $v;
}


sub _mask_error_values {
  my ($self, $text, $values, $statement) = @_;

  return $text unless defined $text and !ref $text;

  $text = DBIO::ClickHouse::Util::mask_error_details($text);

  return $self->next::method($text, $values, $statement);
}


sub dbio_deploy_class { 'DBIO::ClickHouse::Deploy' }


sub deployment_statements {
  my ($self, $schema) = @_;

  return $schema->clickhouse_install_ddl
    if defined $schema && $schema->can('clickhouse_install_ddl');

  $self->throw_exception(
    'Cannot generate ClickHouse DDL: '
  . (defined $schema ? ref($schema) || $schema : 'the schema')
  . ' has no clickhouse_install_ddl(). Load the ClickHouse component into your '
  . "schema class (__PACKAGE__->load_components('ClickHouse')) or declare it "
  . 'with the -ch shortcut (use DBIO Schema => -ch). There is no generic '
  . 'fallback here: a ClickHouse connection reports its DBD name '
  . '(MariaDB/mysql) as sqlt_type, so the generic path would deploy MySQL DDL '
  . '-- InnoDB, FOREIGN KEY, AUTO_INCREMENT -- which ClickHouse cannot execute'
  );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::ClickHouse::Storage - ClickHouse storage driver for DBIO (MySQL wire protocol)

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

ClickHouse storage driver for DBIO. Extends L<DBIO::Storage::DBI> with
ClickHouse-specific behavior.

ClickHouse is a column-oriented OLAP database that speaks the B<MySQL wire
protocol> on server port B<9004>. There is no native C<DBD::ClickHouse> on
CPAN, so this storage sits on top of L<DBD::mysql> or L<DBD::MariaDB> over
that wire protocol. B<L<DBD::mysql> is the standard>: it sends no
SQL on connect at all, so it works against a stock ClickHouse server -- and
therefore ClickHouse Cloud -- with no server-side accommodation, verified live
against 25.3.14.14 (the full suite over a C<dbi:mysql:> DSN). Connect it with
C<< mysql_enable_utf8mb4 => 1 >> or character data comes back as bytes.
L<DBD::MariaDB> is supported for servers whose config you control: it sends
C<SET character_set_server> on every connect and therefore needs
C<custom_settings_prefixes> registered on the server -- impossible on
ClickHouse Cloud -- but decodes character data unconditionally. See
L<DBIO::ClickHouse/Transport: the MySQL wire protocol> and
C<docs/adr/0001-mysql-wire-protocol-transport.md>.

Unlike other drivers, this storage is B<not> resolved by DSN autodetection: a
ClickHouse DSN is C<dbi:MariaDB:...> and is indistinguishable from a real MySQL
DSN. It is registered under the C<ClickHouse> driver name for the component /
C<-ch> shortcut path, and must be pinned explicitly (see L<DBIO::ClickHouse>).

=head1 METHODS

=head2 _determine_supports_insert_returning

Returns 0 -- ClickHouse has no C<INSERT ... RETURNING>.

=head2 _prefetch_autovalues

Generates the client-side UUID for every C<is_auto_increment> UUID column the
insert did not supply, so that the value is B<sent> rather than retrieved. See
L</PRIMARY KEYS AND IDENTITY>.

Core merges the returned hash into the row before building the statement and
once more into what C<insert> hands back, which is what makes C<< $row->id >>
the value this process generated.

=head2 _generate_uuid

    my $uuid = $storage->_generate_uuid;

Returns a fresh RFC 4122 version 4 UUID in the canonical hyphenated form, from
16 bytes of L<Crypt::URandom> entropy -- the same shape ClickHouse's
C<generateUUIDv4()> produces, generated on this side of the wire.

This is the override point for a different identity scheme (UUIDv7 for a
time-ordered sorting key, an application-wide id service): subclass the storage
and return your own value.

=head2 last_insert_id

Always throws a L<DBIO::Exception>. ClickHouse has no identity column and no
C<last_insert_id>, so there is nothing to return; core reaches this hook when a
primary key was left unset, and the honest answer is a message saying how to
set it rather than a fabricated or C<undef> key silently landing in
C<< $row->id >>.

Note that the row I<has> been inserted by the time this throws -- there is no
transaction to undo it with. See L</PRIMARY KEYS AND IDENTITY>.

=head2 _insert_bulk

    $storage->_insert_bulk($source, \@columns, \@rows);

Writes the whole dataset as B<one> multi-row C<INSERT>, rendered by
L<DBIO::ClickHouse::SQLMaker/insert_multi>. This is where a void-context
C<< $rs->populate(\@rows) >> ends up.

Core's implementation prepares a single-row statement and runs it once per row
via C<execute_for_fetch>; on ClickHouse that would write one part per row (see
L</INSERTS AND BATCHING>). One statement also removes the reason core wraps the
loop in a C<txn_scope_guard> -- with nothing to make atomic across statements,
the guard could only add the refusal from L</txn_rollback> on top of whatever
error actually occurred, so this path takes no guard.

The per-row consistency checks core performs (every row must repeat the same
literal SQL, because there is only one prepared statement) do not apply either:
each row is rendered on its own. What is still checked, in C<insert_multi>, is
that every row fills the same column list.

=head2 _prep_for_execute

Renders the statement as core does, then refuses -- before anything is sent --
a value that the server would store as something else than was written. The
cases:

=over 4

=item * B<A string that is not a number, bound to a numeric column.> The server
stores it as C<NULL>, without an error, in a C<Nullable> integer column
(C<''>, C<'abc'>, C<'5x'>, C<' 5'>, and also C<'1.5'> and C<'1e3'>, which are
numbers but not integers), and a C<Float> or C<Decimal> column does the same for
a value with a blank around it. Measured on a stock server through
C<DBD::mysql> (conformance case C<bind-empty-string>). The driver
throws instead, naming table and column and never the value. The test is the
server's own number format per type: an integer column takes C<[+-]?\d+>, a
float column the decimal forms with an optional exponent and C<inf>/C<nan>, a
decimal column the same without them. C<'007'> is a number and goes through.

The column is the one the bind belongs to (its type read from the column info,
C<Nullable(...)> and C<LowCardinality(...)> looked through). It applies to
C<insert>, C<insert_multi> and C<update> -- the statements that store a value;
a search condition stores nothing and is left to the server. A reference
(literal SQL) and C<undef> are not looked at.

=item * B<An integer outside the range of its column's type.> C<300> or C<-3>
at a C<UInt8>, C<128> at an C<Int8>, C<2**64> at a C<UInt64>: the server stores
C<NULL> in a C<Nullable> column and a wrapped-around number (C<300> becomes
C<44>) in any other, without an error. Measured on a stock server through
C<DBD::mysql>. No session setting turns that into an error --
C<input_format_null_as_default>, C<input_format_values_interpret_expressions>,
C<input_format_values_accurate_types_of_literals>, C<insert_null_as_default>
change nothing, and the template settings only make it worse (the value wraps
to C<0>, or every insert fails) -- so the driver checks the range of every
C<Int8> .. C<Int256> / C<UInt8> .. C<UInt256> column (portable names and
C<< extra => { unsigned => 1 } >> included) before sending, and throws, naming
table and column and never the value.

=back

The byte C<0x1A> needs no refusal; see L<DBIO::ClickHouse::SQLMaker/_render_bind>.

=head2 update

=head2 delete

    my $rv = $storage->update($source, \%values, \%condition);
    my $rv = $storage->delete($source, \%condition);

Issue the C<ALTER TABLE ... UPDATE> / C<ALTER TABLE ... DELETE> mutation
rendered by L<DBIO::ClickHouse::SQLMaker>, and B<return -1>.

C<-1> is DBI's "number of rows is unknown", and that is the honest answer here.
A mutation reports nothing about how many rows it matched: the server
acknowledges the C<ALTER>, not the row set, so the affected-rows count on the
wire is 0 whether the mutation changed a million rows or none. Every other
driver returns a real count from C<< $rs->update >> / C<< $rs->delete >>; this
one cannot, and returns a value that is visibly not a count rather than a
plausible-looking C<1> or a C<0> that would read as "nothing matched".

So:

    my $n = $rs->search({ stale => 1 })->delete;   # -1, always
    if ($n > 0) { ... }                            # never true -- do not write this

Count first if you need the number (C<< $rs->count >> before the mutation), or
count after it -- the default C<mutations_sync = 1> means the rows really are
gone by the time the statement returns.

The row-level path is the reason the value is C<-1> and not C<'0E0'>:
C<DBIO::Row::update> throws C<"row not found"> on a 0 return and
C<"updated more than one row"> above 1, so a truthful "unknown" has to sit
between them. C<< $row->update >> and C<< $row->delete >> therefore behave
normally -- but note that they cannot detect a row that is no longer there.
A mutation whose C<WHERE> matches nothing is a successful mutation.

=head2 _dbio_sql_maker_option_names

Adds C<mutations_sync> to the connect-info attributes that are routed to the
SQL maker instead of to C<< DBI->connect >>, which is what makes
C<< ->connect($dsn, $user, $pass, { mutations_sync => 2 }) >> work. See
L</MUTATIONS>.

The setting is rendered into each statement rather than held on the storage, so
the SQL maker is where it belongs -- and unlike core's storage-option list
(which C<DBIO::Storage::DBI> captures into a file-scoped lexical at compile
time), the SQL-maker list is looked up as a method on the live storage and can
therefore be extended by a driver at all.

=head2 _adjust_select_args_for_complex_prefetch

Drops the ClickHouse dialect attributes (C<final>, C<prewhere>, C<limit_by> --
see L<DBIO::ClickHouse::SQLMaker/CLICKHOUSE RESULTSET ATTRIBUTES>) from the
B<outer> half of a complex-prefetch rewrite. Core copies the whole attribute
hash into both halves, but the outer query selects from the generated subquery,
where C<FINAL> and C<PREWHERE> are not valid at all and C<LIMIT n BY> would
apply to the joined result instead of the table rows. The inner half keeps
them.

=head2 _set_operation_keyword

    my $keyword = $storage->_set_operation_keyword('except');   # EXCEPT DISTINCT

Spells C<union>, C<intersect> and C<except> with an explicit C<DISTINCT>,
which is what those three mean in ANSI SQL and B<not> what the bare keyword
means on ClickHouse. The other three -- C<union_all>, C<intersect_all>,
C<except_all> -- are already spelled the ClickHouse way by core's base map
and reach it through C<< $self->next::method >>. Nothing is refused: this
engine has all six. See L</SET OPERATIONS> for the settings behind it and the
22.9 version floor.

A static class fact, as ADR 0039 section 7 requires: no C<$dbh>, no version
probe, because L<DBIO::ResultSet/_set_operation> bakes the keyword into the
query at construction time.

=head2 _random_function

    my $func = $storage->_random_function;   # rand()

The function L<DBIO::ResultSet/rand> orders by. C<rand()>, and not core's
inherited C<RANDOM()> (ClickHouse has no such function), and not
C<randCanonical()> (its C<Float64> buys nothing at this hook's only call site
and costs a 22.11 version floor). See L</RANDOM ORDERING>, including why
C<randConstant()> -- the variant that would silently stop shuffling -- is the
wrong answer.

A static class fact: no C<$dbh>, no version probe.

=head2 _exec_txn_begin

=head2 _exec_txn_commit

No-ops -- there is no C<BEGIN> / C<COMMIT> to send. The public C<txn_begin> /
C<txn_commit> keep working (and keep core's C<transaction_depth> bookkeeping
correct), they simply do not make anything atomic. The first of the two to run
in an interpreter warns once. See L</TRANSACTIONS>.

=head2 txn_do

    my @rows = $storage->txn_do(sub { ... }, @args);

Runs the coderef B<without> a C<BEGIN>/C<COMMIT> bracket (warns once), passing
C<@args> through and preserving calling context. If the coderef dies, the
original exception propagates unchanged -- there is no rollback that could mask
it -- preceded by a loud warning that everything the block managed to write is
permanent.

The block is never retried: core retries a C<txn_do> whose connection went
stale, which is only safe because the transaction guarantees the failed attempt
left nothing behind. Without a transaction a retry would re-apply whatever the
first attempt already wrote.

=head2 txn_rollback

Always throws a L<DBIO::Exception> via C<throw_exception>: ClickHouse cannot
undo anything, and silently accepting a rollback would leave the caller
believing the changes are gone while they are still in the table.

Core's C<transaction_depth> is unwound first, so the storage is not left
believing it is inside a transaction after the throw. See L</TRANSACTIONS>.

=head2 txn_scope_guard

    my $guard = $storage->txn_scope_guard;   # or $schema->txn_scope_guard

Returns a L<DBIO::ClickHouse::Storage::TxnScopeGuard>: core's guard with its
C<DESTROY> replaced by one that C<carp>s instead of rolling back. Taking one is
still allowed -- core takes them on your behalf all over the ORM -- it simply
cannot make anything atomic, and says so when it unwinds.

C<< $guard->rollback >> is untouched and still throws. See L</TRANSACTIONS>.

=head2 _exec_svp_begin

=head2 _exec_svp_release

=head2 _exec_svp_rollback

ClickHouse has no savepoints (and no transactions); all three throw a
L<DBIO::Exception> via C<throw_exception>.

=head2 _ping

Liveness check via C<SELECT 1> on the active dbh.

=head2 clickhouse_version

    my $v = $storage->clickhouse_version;

Returns the ClickHouse server version string via C<SELECT version()>.

=head2 _mask_error_values

    my $text = $storage->_mask_error_values($text, \@values, $statement);

The one seam through which the text of the engine passes before it is thrown
(L<DBIO::Storage::DBI/_mask_error_values>). ClickHouse writes the value it
choked on into its message -- also a bound one, because the MySQL-wire driver
puts the bind values into the statement on the client and the engine quotes
what it received -- in sentences of its own (C<Cannot parse string 'x' as
Int32>, C<Column values:>, the statement after C<In scope>, the plan after
C<while executing>). The text goes through
L<DBIO::ClickHouse::Util/mask_error_details> first, which knows those
sentences and keeps the error code, the type, the column, the constraint and
the position; then through core's masking of the bound values, which catches
the values of at least four characters wherever else they stand.

Core calls it for every error of a handle, of a statement run through
C<_dbh_execute> and of a bulk C<populate>; C<update>, C<delete> and the
multi-row insert of this driver run through the same path. C<< $dbh->errstr >>
keeps the raw text.

=head2 dbio_deploy_class

    my $class = $storage->dbio_deploy_class;   # DBIO::ClickHouse::Deploy

Names the native deploy class, which is how L<DBIO::Schema/deploy> finds it:
core probes C<< $storage->can('dbio_deploy_class') >> and, when the storage
answers, runs C<< $class->new(schema => $schema)->install >> instead of its own
generic path.

The declaration is what makes C<< $schema->deploy >> B<fail loud>. Undeclared,
core falls through to L<DBIO::Storage::DBI/deploy>, whose statement loop wraps
every statement in a C<try>/C<catch> that C<carp>s the error as a warning and
B<continues with the next statement>, then reports success regardless. On this
engine that is a realistic outcome rather than a theoretical one -- a
C<CREATE TABLE> whose type or sorting key ClickHouse rejects fails on its own
while its neighbours succeed -- and the caller would be handed a true return
value over a half-deployed schema. Routing through L<DBIO::ClickHouse::Deploy>
runs the same DDL through L<DBIO::Deploy::Base/_execute_ddl>, which lets the
first failure propagate and never reaches the statements behind it.

That is a loud failure, not a clean one: ClickHouse has no transactional DDL
(see L</TRANSACTIONS> and ADR 0003), so the tables created before the failing
statement stay created either way. The difference is being told which statement
broke, instead of finding out later.

The class name is only a name here -- core C<require>s it at deploy time -- so
declaring it does not pull L<DBIO::ClickHouse::DDL>,
L<DBIO::ClickHouse::Introspect> or L<DBIO::ClickHouse::Diff> into every
connection.

=head2 deployment_statements

    my $sql = $storage->deployment_statements($schema);

Returns the ClickHouse-native install DDL for C<$schema>, by delegating to
C<< $schema->clickhouse_install_ddl >> (see L<DBIO::ClickHouse/clickhouse_install_ddl>,
which renders through L<DBIO::ClickHouse::DDL>). The remaining arguments core
passes -- C<$type>, C<$version>, C<$dir>, C<$sqltargs> -- are ignored: the DDL
is rendered from the schema itself and has no dialect or version variants.

This is the SQL-inspection entry point, not the deploy path: C<< $schema->deploy >>
routes through L</dbio_deploy_class> and renders the same DDL there.

Unlike the MySQL and PostgreSQL storages there is deliberately B<no fallback>
for a schema without the component -- it throws. The generic path keys off
C<sqlt_type>, and C<sqlt_type> is the B<DBD driver name>, which for a
ClickHouse connection is C<MariaDB> / C<mysql>. Anything that resolves against
that name is MySQL DDL: InnoDB engines, C<FOREIGN KEY>, C<AUTO_INCREMENT> --
all of which ClickHouse rejects -- and none of it carries the C<ENGINE> and
C<ORDER BY> that a ClickHouse C<CREATE TABLE> cannot do without. Falling
through would not degrade gracefully, it would deploy the wrong database's
schema, so the missing component is reported as the error it is.

=head1 CLICKHOUSE SEMANTICS

ClickHouse shares the wire protocol with MySQL but almost none of the
semantics:

=over 4

=item * B<No transactions and no savepoints.> C<txn_begin> / C<txn_commit> are
no-ops and L</txn_do> runs its coderef unwrapped (each warns once), while
L</txn_rollback> and the savepoint hooks below throw. See
L</TRANSACTIONS> and C<docs/adr/0003-no-transactions-policy.md>.

=item * B<No C<SELECT ... FOR UPDATE>> -- disabled in
L<DBIO::ClickHouse::SQLMaker>.

=item * B<No C<INSERT ... RETURNING>> -- L</_determine_supports_insert_returning>
returns 0.

=item * B<No auto-increment / C<last_insert_id>.> The primary key is the
MergeTree C<ORDER BY> sorting key; surrogate identity is done with UUIDs. See
L</PRIMARY KEYS AND IDENTITY>.

=item * B<C<UPDATE> / C<DELETE> are asynchronous mutations>
(C<ALTER TABLE ... UPDATE/DELETE>), non-transactional and applied in the
background by rewriting parts. L</update> / L</delete> render and wait for them;
neither returns a row count. See L</MUTATIONS>.

=item * B<Identifier quoting is the backtick> C<`> (MySQL-wire compatible).

=back

Native DDL generation lives in L<DBIO::ClickHouse::DDL> and is reachable
through L</deployment_statements>; introspection, diff and desired-state deploy
live in L<DBIO::ClickHouse::Introspect>, L<DBIO::ClickHouse::Diff> and
L<DBIO::ClickHouse::Deploy>, reached via L</dbio_deploy_class>.

=head1 PRIMARY KEYS AND IDENTITY

ClickHouse has no identity columns, no sequences and no C<last_insert_id>.
There is also no C<INSERT ... RETURNING>, so nothing the server computes during
an insert can be read back in the same round-trip. That fixes the policy:

B<a row's primary key is always the value the client sent.> This driver never
hands back a database-generated key, because it has no way to learn one.

=head2 UUID primary keys

The one surrogate identity ClickHouse offers natively is a generated UUID, and
that is what C<< is_auto_increment => 1 >> means here -- but only on a
UUID-family column (C<uuid>, C<guid>, C<uniqueidentifier>):

    __PACKAGE__->add_columns(
      id   => { data_type => 'uuid', is_auto_increment => 1 },
      url  => { data_type => 'varchar', size => 2048 },
    );
    __PACKAGE__->set_primary_key('id');

    my $hit = $schema->resultset('Hit')->create({ url => '/a' });
    $hit->id;   # the UUID this process generated and sent

Two halves, deliberately kept in sync:

=over 4

=item * B<Client side.> L</_prefetch_autovalues> generates an RFC 4122 version
4 UUID (from L<Crypt::URandom>) for every such column that the insert did not
supply, B<before> the statement is built. It goes out as an ordinary bind
value, so C<< $row->id >> afterwards is exactly what was written -- no
retrieval, no extra round-trip, no guess.

=item * B<Server side.> L<DBIO::ClickHouse::DDL> emits
C<DEFAULT generateUUIDv4()> on the same column. Because the client always
supplies a value, that default never fires for a DBIO insert; it is the safety
net for rows written by anything else (C<clickhouse-client>, a Kafka engine, a
C<INSERT ... SELECT>), so the column still fills itself.

=back

Supplying the column explicitly always wins -- the generator only fills in what
the insert left unset.

Supplying it as B<literal SQL> is a different thing, and does not work with
C<create>:

    $rs->create({ id => \'generateUUIDv7()', url => '/a' });   # throws

A literal is computed by the server, so it lands in exactly the hole this
driver cannot climb out of: the row is written, and there is no C<RETURNING>
and no C<last_insert_id> to learn the resulting key from. C<create> promises a
usable row object, so it throws (from L</last_insert_id>) rather than handing
back the unevaluated literal ref. Use L<DBIO::ResultSet/populate> in void
context when you want the server to compute keys -- it never needs them back.

=head2 Anything else must be supplied

C<< is_auto_increment => 1 >> on a non-UUID column is B<refused> by the DDL
layer (there is no server-side generator to call), so a table with such a
key can only come from hand-written DDL, and an
insert that leaves such a primary key unset cannot be completed honestly. The
identity-retrieval hook L</last_insert_id> therefore throws instead of
returning a fabricated or C<undef> key.

Note also that C<retrieve_on_insert> costs a full extra C<SELECT> here -- there
is no C<RETURNING> to piggyback on -- and that this follow-up read is not
reliable under C<async_insert> (see L</INSERTS AND BATCHING>). Introspection
deliberately never sets it.

=head1 INSERTS AND BATCHING

An C<INSERT> into a MergeTree table writes a new I<part>, which background
threads then merge. Row-at-a-time inserts create one part per row and are the
standard way to bring a ClickHouse table to its knees; the engine wants few,
large inserts. So:

=over 4

=item * B<C<populate> is one statement.> L</_insert_bulk> -- the method
C<< $rs->populate(\@rows) >> in void context ends in -- renders the whole
dataset as a single multi-row C<INSERT INTO t (...) VALUES (...), (...), ...>
through L<DBIO::ClickHouse::SQLMaker/insert_multi>, rather than core's
"prepare once, execute per row". One statement, one part, one round-trip.

=item * B<Prefer C<populate> over a loop of C<create>.> Each C<create> is its
own C<INSERT> and its own part.

=item * B<Very large datasets must be chunked by the caller.> The statement
carries one placeholder per cell, so a big enough C<populate> will hit the
server's C<max_allowed_packet>. Nothing here splits it; feed C<populate> in
slices of a few tens of thousands of rows.

=back

=head2 async_insert / wait_for_async_insert

ClickHouse can do the batching itself: with C<async_insert> the server collects
incoming inserts in a buffer and flushes them as one part. That turns a stream
of small inserts into acceptable write behaviour without restructuring the
application. Both are session settings, so they belong in the connect
information:

    MyApp::Schema->connect($dsn, $user, $pass, {
      on_connect_do => [
        'SET async_insert = 1',
        'SET wait_for_async_insert = 1',
      ],
    });

C<wait_for_async_insert> decides what the C<INSERT> statement means:

=over 4

=item * B<1 (the ClickHouse default)> -- the statement returns once the buffer
was flushed. Slower, but an insert error still reaches the client as an
exception, and a subsequent C<SELECT> sees the rows.

=item * B<0> -- fire and forget. The statement returns as soon as the server
has buffered the data. Nothing downstream can be trusted: a failure during the
flush is B<never reported to the client>, and a read immediately after the
write may not see the rows. Only set it where losing an insert silently is
acceptable.

=back

This driver does not set either of them, and does not second-guess them: they
are a durability trade-off only the application can make.

=head1 MUTATIONS

C<< $rs->update >>, C<< $rs->delete >>, C<< $row->update >> and
C<< $row->delete >> all work, and all of them issue something that is not DML:

    ALTER TABLE `hit` UPDATE `hits` = ? WHERE `id` = ? SETTINGS mutations_sync = 1
    ALTER TABLE `hit` DELETE WHERE `id` = ? SETTINGS mutations_sync = 1

ClickHouse has no C<UPDATE> and no C<DELETE> statement; changing stored rows is
a B<mutation>, an asynchronous background job that rewrites every data part
containing a matching row. L<DBIO::ClickHouse::SQLMaker/MUTATIONS> renders the
statement -- including the row-level form, where the C<WHERE> clause is the
row's primary key, exactly as on any other driver.

Four consequences the ORM cannot hide:

=over 4

=item * B<A mutation is not a transaction.> It is not atomic with anything
around it -- not with the statement before it, not with the one after it, and
(for a multi-part table) not internally: other readers can see a partly-applied
mutation. There is nothing to roll it back with. See L</TRANSACTIONS>.

=item * B<A mutation is heavyweight.> A single-row C<< $row->update >> rewrites
whole parts, not one row. It is a schema-maintenance operation wearing DML
clothing: fine for a correction or a GDPR erasure, wrong for a per-request
write path. If rows need to change often, model it instead -- append the new
version and read through a C<ReplacingMergeTree> (or C<FINAL>, see
L<DBIO::ClickHouse::SQLMaker/final>), which is what the engine is built for.

=item * B<Neither call returns a row count.> See L</update> below.

=item * B<An unrestricted C<< $rs->delete >> deletes everything>, rendered as
C<WHERE 1> -- a mutation must carry a filter expression, so the clause cannot
simply be omitted the way C<DELETE FROM t> omits it.

=back

=head2 mutations_sync: synchronous by default

Left alone, a mutation is fire-and-queue: the statement returns immediately and
the rows change at some later point. That breaks the one thing every piece of
ORM code assumes -- that a write is visible to the read after it. So this driver
appends C<SETTINGS mutations_sync = 1> to every mutation, which makes the
statement wait until the mutation has been applied on the server it was sent to.

Override it at connect time:

    MyApp::Schema->connect($dsn, $user, $pass, { mutations_sync => 2 });

C<2> waits for all replicas (needed when reads may land on a different replica
than the write), C<0> restores ClickHouse's asynchronous default, and C<undef>
emits no C<SETTINGS> clause at all so a session-level or profile-level setting
is the one that applies. Values are validated when the SQL maker is built. The
full option is documented in L<DBIO::ClickHouse::SQLMaker/mutations_sync>, the
reasoning in C<docs/adr/0005-mutations-sync-by-default.md>.

The default is not free: waiting is exactly as slow as the part rewrite it
waits for. It buys predictable ORM semantics, not throughput -- which is the
same reason the second bullet above says not to put mutations in a hot path.

=head1 TRANSACTIONS

ClickHouse has no transactions, so this storage cannot honour DBIO's
transaction API. Rather than pretending, it splits the API in two:

=over 4

=item * B<Everything that only I<promises> atomicity is a no-op>, so ordinary
schema code keeps working: C<txn_begin> and C<txn_commit> send nothing to the
server (L</_exec_txn_begin> / L</_exec_txn_commit>), L</txn_do> runs its coderef
without a C<BEGIN>/C<COMMIT> bracket, and a scope guard
(L</txn_scope_guard>) neither brackets nor rolls back. Each of the two emits a
B<one-time warning> per interpreter (C<carp_once>) saying that nothing is
atomic. Core's C<transaction_depth> bookkeeping is kept intact, so nesting stays
predictable.

=item * B<Everything that I<claims work was undone> throws>: L</txn_rollback>
always throws, because a silent no-op there would be an active lie -- the
caller would believe the changes are gone while every statement is in fact
still in the table. C<< $guard->rollback >> is the same statement written on a
guard, and throws for the same reason. This is also why a failing L</txn_do>
carps loudly (every time, not once) that nothing was rolled back before
re-throwing the B<original> exception unchanged.

=back

=head2 Scope guards

L<DBIO::Storage::TxnScopeGuard> is not just a user-facing tool -- core takes one
on your behalf in C<delete_all>, C<update_all>, multi-create
(C<< $rs->create >> with related rows), cascade delete, and C<populate> in
non-void context or with related data. Its C<DESTROY> rolls back, and that path
is structurally indistinguishable from a caller writing C<< $guard->rollback >>.

L</txn_scope_guard> therefore hands out
L<DBIO::ClickHouse::Storage::TxnScopeGuard>, which is core's guard with C<DESTROY>
replaced: it unwinds C<transaction_depth> and B<carps> that nothing was rolled
back, rather than throwing from inside someone else's stack unwind. So:

=over 4

=item * B<The guarded operations run> -- unguarded in effect, exactly like
L</txn_do>. A failure part-way through C<delete_all> leaves the rows it already
deleted deleted. That is true of every mutation on this engine, guard or no
guard.

=item * B<The original exception arrives untouched.> Core's C<DESTROY> catches
the refusal from L</txn_rollback> and folds it into the in-flight error --
mutating a L<DBIO::Exception> B<in place> to C<"Transaction aborted: <original>
Rollback failed: ...">, once per guard on the stack. A C<delete_all> inside a
caller's own guard nests three deep, so the real error used to arrive behind
three such prefixes. It no longer does.

=item * B<Every abnormal unwind carps> (not once -- each is its own partial
write), naming the only fact that matters: nothing was rolled back. A guard
that reaches C<< ->commit >> normally is silent.

=item * B<< $guard->rollback >> still throws. Inherited unchanged from core, it
routes to L</txn_rollback>.

=back

One bulk path takes no guard at all any more: L</_insert_bulk> issues a single
multi-row statement, which no rollback could improve on, so a void C<populate>
of plain column data never touches the transaction machinery -- no warning, and
an insert error propagates as itself. (A C<populate> carrying B<related> rows
still falls back to per-row C<create>, and is guarded like any other
multi-create.)

See C<docs/adr/0003-no-transactions-policy.md>.

=head1 EXISTS QUERIES

L<DBIO::ResultSet/results_exist> and its two siblings work on this driver:
the storage declares the C<supports_exists_query> capability (ADR 0037) and
inherits core's rendering of L<DBIO::Storage::DBI/_exists_value_sql>
unchanged, because ClickHouse accepts it as written:

    SELECT CASE WHEN EXISTS (SELECT 42 FROM `hit` `me` WHERE `url` = ?)
           THEN 1 ELSE 0 END

ClickHouse documents C<EXISTS(subquery)> as an operator that B<returns 0 or
1>, not merely a predicate, and its own example selects two of them into a
select list of a C<FROM>-less C<SELECT> -- which is exactly the shape above.
It needs ClickHouse B<21.11 or newer> ("Support EXISTS(subquery)"); C<CASE
WHEN ... THEN ... ELSE ... END> is older than that and is lowered internally
to C<multiIf()>.

=head2 The subquery may not be correlated

The one restriction, and it is the engine's, not this driver's: ClickHouse's
C<EXISTS> documentation states that B<references to main query tables and
columns are not supported in a subquery>. So
L<DBIO::ResultSet/results_exist_as_query> is usable here as a B<standalone>
scalar subquery, but not in the correlated role core's own documentation
suggests for it -- C<< $rs->correlate(...)->results_exist_as_query >> builds
a fragment this engine will reject. (Newer servers carry a
C<allow_experimental_correlated_subqueries> setting; nothing here relies on
it.) Use L<DBIO::ResultSet/has_rows> or a join if you need the correlation.

The declaration itself is a class fact and needs no connection, so the
statement is rendered without one, like every other engine-specific fragment
this storage answers for.

=head1 SET OPERATIONS

All six of L<DBIO::ResultSet>'s set operations work on this driver -- nothing
is refused -- but B<three of them are spelled differently here>, through the
L<DBIO::Storage::DBI/_set_operation_keyword> hook (ADR 0039):

    $rs->union          # UNION DISTINCT       (not UNION)
    $rs->union_all      # UNION ALL
    $rs->intersect      # INTERSECT DISTINCT   (not INTERSECT)
    $rs->intersect_all  # INTERSECT ALL
    $rs->except         # EXCEPT DISTINCT      (not EXCEPT)
    $rs->except_all     # EXCEPT ALL

ClickHouse has every one of these operators. What it does not share is
B<what the bare keyword means>. In ANSI SQL, C<UNION>, C<INTERSECT> and
C<EXCEPT> without a modifier are the duplicate-eliminating forms; on
ClickHouse a bare keyword carries no fixed meaning of its own at all -- it is
resolved from a session setting:

=over 4

=item * B<A bare C<UNION> is an error by default.> C<union_default_mode>
ships as the empty string, and the C<UNION> documentation states that "if you
use C<UNION> with C<union_default_mode> setting to empty string, it will
throw an exception" -- the default was deliberately changed to throw in 21.1.
Core's ANSI keyword would not merely mean the wrong thing here, it would not
run.

=item * B<A bare C<INTERSECT> or C<EXCEPT> means C<ALL>.>
C<intersect_default_mode> and C<except_default_mode> both default to
C<'ALL'>, which is why the C<EXCEPT> documentation warns that "the result of
C<EXCEPT> can contain duplicate rows. Use C<EXCEPT DISTINCT> if this is not
desirable". Core's ANSI keyword would run and quietly hand back duplicates
from an operation that promised distinct rows -- the silent kind of wrong,
and the reason this is a spelling and not a refusal.

=back

Spelling all six explicitly also makes the emitted statement B<independent of
those three settings>: a deployment that sets C<union_default_mode = 'ALL'>
in its profile does not thereby turn C<< $rs->union >> into a C<UNION ALL>
behind the application's back.

=head2 Version floor

C<UNION ALL> is as old as ClickHouse; C<UNION DISTINCT> arrived with
C<union_default_mode> in B<21.1>; C<INTERSECT> and C<EXCEPT> in B<21.10>. The
C<ALL> / C<DISTINCT> modifiers on C<INTERSECT> and C<EXCEPT>, and the two
settings that go with them, arrived in B<22.9> -- before that the parser
accepted C<INTERSECT> and C<EXCEPT> with no modifier at all. So four of the
six operations as this driver spells them need B<ClickHouse 22.9 or newer>.
The last release without them, 22.8 LTS, left support in 2023.

That floor is unconditional on purpose. The hook must answer without a
connection (ADR 0039 section 7) -- the keyword is baked into the query at
construction time -- so it cannot ask which server version it is talking to.
A driver that hedged downwards would emit the ANSI spelling, which is wrong
on B<every> ClickHouse version, in order to be right on none.

=head1 RANDOM ORDERING

L<DBIO::ResultSet/rand> works on this driver, ordering by C<rand()> through
the L<DBIO::Storage::DBI/_random_function> hook:

    $schema->resultset('Artist')->rand(3);
    # SELECT ... FROM `artist` `me` ORDER BY rand() LIMIT 3

Core's inherited default is C<RANDOM()>, which ClickHouse does not have.
Its random functions are C<rand> (alias C<rand32>), C<rand64>,
C<randCanonical>, C<randConstant> and the distribution family
(C<randUniform>, C<randNormal>, ...) -- there is no C<random> among them, so
inheriting the default would throw an unknown-function error naming
C<RANDOM>. Loud rather than silent, but still an outage for a feature this
engine has.

=head2 Why C<rand()> and not C<randCanonical()>

C<rand()> returns a C<UInt32>; C<randCanonical()> returns the C<Float64> in
C<[0, 1)> that the name C<RANDOM()> suggests elsewhere. The hook has exactly
one consumer in core -- L<DBIO::ResultSet/rand>, which drops the string into
an C<order_by> literal and does nothing else with it -- so the B<value is
never selected, never compared against a threshold and never handed to the
caller>. Only the induced I<order> is observable, and a uniform C<UInt32>
orders rows exactly as uniformly as a uniform C<Float64> does.

What differs is the price. C<randCanonical> arrived in B<22.11>; C<rand> has
been there since B<1.1>. Choosing the float would put a version floor under
C<< $rs->rand >> to buy a property nothing at the call site can observe --
unlike L</SET OPERATIONS>, where the floor buys a statement that is otherwise
wrong. Should a caller ever need this hook's value B<as a number> (a
C<WHERE rand() E<lt> 0.01> sampling predicate, say), that is a different hook
and the floor gets paid then.

The one visible consequence of C<UInt32>: it has 2**32 distinct values, so
past roughly 77,000 rows a tie is more likely than not, and tied rows sort in
an unspecified order relative to each other. For a random pick that is not a
defect.

=head2 It is evaluated per row -- which is the thing that had to be checked

This hook is worth nothing if the engine computes the function once per
B<statement> instead of once per B<row>: C<ORDER BY> over a per-statement
constant is a B<silent non-shuffle> -- the same rows in the same order, no
error anywhere. (That is a real finding elsewhere in this family, on Sybase
ASE.) ClickHouse documents the opposite, in three independent places:

=over 4

=item * C<rand> is a B<regular function>, and regular functions "work as if
they are applied to each row separately (for each row, the result of the
function does not depend on the other rows)".

=item * Random numbers are B<the> documented exception to constant folding:
"Almost all functions return a constant for constant arguments. The exception
is functions that generate random numbers." C<now()> is named right there as
the counter-example that I<is> treated as constant within one query --
C<rand()> explicitly is not.

=item * ClickHouse ships the per-statement variant as a B<separate, separately
named> function, C<randConstant()>: "a single random value that remains
constant across all rows in the current query execution". The non-shuffle has
to be asked for by name; it cannot be walked into.

=back

Common subexpression elimination does apply: two textually identical
C<rand()> calls in one query are one expression, evaluated once B<per row>,
which is what the optional ignored argument (C<rand(1)>) exists to break. It
does not touch C<< $rs->rand >>, which emits exactly one call.

B<Unverified against a live server> -- none was reachable when this was
written -- so the above is ClickHouse's documented behaviour, not observed
behaviour.

=head2 Cost

C<ORDER BY rand()> sorts the whole result set before the C<LIMIT>, which on a
MergeTree table of any size is the expensive way to take a few rows.
ClickHouse's cheap alternative is C<SAMPLE>, which needs a sampling expression
in the table's own definition and which this driver deliberately does not
implement -- use the literal-SQL escape hatch if you need it.

=head1 QUERY PLANS

L<DBIO::ResultSet/explain> works here through B<core's inherited
implementation>. This storage does not override
L<DBIO::Storage::DBI/_explain_query>, and the absence is a decision, not an
omission: ADR 0040 names ClickHouse as one of the engines the base fits, and
that was checked here rather than taken on trust.

    $schema->resultset('Artist')->search({ name => 'x' })->explain;
    # EXPLAIN SELECT `me`.`artistid`, ... FROM `artist` `me` WHERE `name` = ?

ClickHouse's C<EXPLAIN> takes an optional B<type>:

    EXPLAIN [AST | SYNTAX | QUERY TREE | PLAN | PIPELINE | ANALYZE | ESTIMATE
             | TABLE OVERRIDE] [setting = value, ...] SELECT ...

and the type this hook wants is the one you get by B<omitting> it. A bare
C<EXPLAIN> is C<EXPLAIN PLAN>: the query execution plan, one C<String> row per
plan line in a single column named C<explain>. That is exactly what core's
base implementation produces, so an override could only re-spell what is
already right. All four assumptions ADR 0040 section "the finding" lists hold
on this engine -- obtaining the plan is B<one> statement, it is B<executed>
with the query's own binds, it B<returns rows>, and those rows B<are> the
plan.

The other types answer other questions, and none of them is what C<explain>
promises: C<AST> and C<SYNTAX> dump the parsed / rewritten query rather than
its execution, C<QUERY TREE> the analyzer's tree, C<PIPELINE> the processor
graph below the plan, C<ESTIMATE> a row/mark/part count (and it is the one
type whose result is not a single C<explain> column), C<TABLE OVERRIDE> a
schema validation -- and C<ANALYZE> B<runs the query>, which C<explain> must
not.

So nothing here is silent the way SQLite's bare C<EXPLAIN> is, where the base
implementation is accepted and answers with VM bytecode. On ClickHouse the
base implementation asks for the plan and gets the plan.

The row I<contents> are engine-specific, as on every engine (ADR 0040 section
2): they are ClickHouse plan lines (C<Expression>, C<ReadFromMergeTree>, ...)
whose format has changed between releases -- 26.7 turned the C<pretty> /
C<actions> / C<compact> rendering on by default. Read them; do not parse them.

B<Unverified against a live server>, like L</RANDOM ORDERING>: established
from the C<EXPLAIN> documentation, not from a running ClickHouse.

=head1 ACCESS PATH: DBD::MYSQL AND DBD::MARIADB

Since core's ADR 0059 a declared storage is held against the DBD its DSN
names: when L<DBIO::Storage::DBI/register_driver> maps that DBD to a storage
class this one is not related to by inheritance, the DSN is taken to lead
through another driver, and that is reported through
L<DBIO::Storage::DBI/_driver_mismatch> -- a warning by default, an exception
under L<DBIO::Schema/driver_strict>. Core registers C<mysql> and C<MariaDB>
for the MySQL storages.

The transport of this driver B<is> another driver's DBD
(C<docs/adr/0001-mysql-wire-protocol-transport.md>), and the storage
deliberately does not inherit that driver's class
(C<docs/adr/0002-standalone-dist-not-mysql-subclass.md>). So the storage
declares both DBDs as its own through core's
L<DBIO::Storage::DBI/register_access_path_dbd>: they are accepted in silence,
also under C<driver_strict>, and nothing else is -- a C<dbi:Pg:> DSN on a
ClickHouse schema is still reported by core.

It is decided from the DBD name alone -- no connection, no query. Whether the
server behind a C<dbi:mysql:> DSN really is a ClickHouse is not asked here; a
DSN cannot tell (L<DBIO::ClickHouse/The storage must be pinned explicitly>).
C<t/07-transport-dbd.t> pins the behaviour and the declaration.

=head1 SEE ALSO

=over 4

=item * L<DBIO::ClickHouse> - Schema component that activates this storage

=item * L<DBIO::ClickHouse::SQLMaker> - SQL generation for ClickHouse

=item * L<DBIO::Storage::DBI> - Base DBI storage class

=item * L<DBD::MariaDB>, L<DBD::mysql> - MySQL-wire DBI drivers

=back

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
