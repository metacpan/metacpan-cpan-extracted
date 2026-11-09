package DBIO::PostgreSQL::Storage;
# ABSTRACT: PostgreSQL storage layer for DBIO

use strict;
use warnings;

our $VERSION = '0.900004';

use base qw/DBIO::Storage::DBI/;
use mro 'c3';

__PACKAGE__->register_driver('Pg' => __PACKAGE__);

sub dbio_deploy_class { 'DBIO::PostgreSQL::Deploy' }


__PACKAGE__->register_type('jsonb', {
  cake_options => [qw(inflate_json inflate_jsonb)],
  components   => ['InflateColumn::Serializer'],
  col_attrs    => { serializer_class => 'JSON' },
});


use DBIO::Util ();
use Scalar::Util ();
use DBIO::PostgreSQL::Util ();
use DBIO::PostgreSQL::Extension ();
use DBIO::PostgreSQL::DDL ();
use Context::Preserve 'preserve_context';
use DBIO::Carp;
use Try::Tiny;

# PostgreSQL defaults
__PACKAGE__->sql_maker_class('DBIO::PostgreSQL::SQLMaker');
__PACKAGE__->sql_quote_char('"');
__PACKAGE__->datetime_parser_type('DateTime::Format::Pg');
__PACKAGE__->_use_multicolumn_in(1);

# F02: PostgreSQL runs DDL inside an ordinary transaction -- CREATE TABLE and
# friends are rollbackable here, which is the exception among the engines, not
# the rule. DBIO::Deploy::Base::_execute_ddl brackets DDL in $storage->txn_do
# only when this reports true, so declaring it is what makes a multi-statement
# install or upgrade atomic: a failure on statement 7 of 12 rolls the preceding
# six back instead of leaving the schema half migrated.
#
# What it does NOT declare is one transaction per batch, and both limits are
# load-bearing enough to name here. Core groups the batch by
# _ddl_statement_is_transactional below, so an ALTER TYPE ... ADD VALUE runs on
# its own while the rest keeps its bracket (core k132); and core brackets only a
# handle this storage owns, so the temp-database deploy behind
# DBIO::PostgreSQL::Deploy->diff -- which runs on a handle TempDatabase opened
# itself -- stays unbracketed (core k131). Both arrived in DBIO 0.900004, which
# is why the cpanfile pins it: on an older core this declaration would put a
# transaction on the live connection around DDL executing somewhere else.
#
# Declared rather than left to core's default, which is 0. That default is the
# conservative answer for an engine nobody has checked, and inheriting it here
# meant this driver silently deployed statement-at-a-time -- while
# DBIO::PostgreSQL::EV::Storage::deploy_async already bracketed its own DDL for
# exactly the reason spelled out above. Pinned by t/43-capabilities.t.
__PACKAGE__->_use_transactional_ddl(1);

# ADR 0037: core's base rendering of _exists_value_sql is
#
#   SELECT CASE WHEN EXISTS <inner> THEN 1 ELSE 0 END
#
# and it is checked against PostgreSQL rather than assumed, because that is the
# whole content of this flag -- it asserts that somebody looked. The statement
# makes three demands and PostgreSQL documents all three:
#
#   * EXISTS used as a VALUE, not a predicate. "Subquery Expressions" opens
#     with "All of the expression forms documented in this section return
#     Boolean (true/false) results", EXISTS among them -- PostgreSQL has a real
#     boolean type, so the CASE condition is an ordinary boolean expression.
#   * A SELECT with no FROM. The SELECT reference states it outright under
#     Compatibility: "PostgreSQL allows one to omit the FROM clause. It has a
#     straightforward use to compute the results of simple expressions".
#   * Nothing else -- core adds only parentheses around the fragment for
#     results_exist_as_query, and a parenthesised scalar subquery is universal.
#
# So this driver does NOT override _exists_value_sql; it takes the base form.
# The three engines that do override it are the ones that also refuse a
# FROM-less SELECT (Oracle, DB2, Firebird), which PostgreSQL does not.
#
# Declaring it is what makes results_exist / results_exist_async /
# results_exist_as_query work at all: core's default is 0 and all three throw
# on an undeclared engine rather than ship SQL it may not parse. The
# declaration on this class is also the ONLY one the driver family needs --
# see the "Extensions and the async backends" note below and
# t/44-exists-query-seam.t, which pins both halves.
__PACKAGE__->_use_supports_exists_query(1);

# karr k48 / core ADR 0040: this driver does NOT override _explain_query. Core's
# base operation -- EXPLAIN <sql> through _execute_rendered, rows back -- is the
# right one for PostgreSQL, and taking it unchanged is a decision, not an
# omission, so it is recorded here where the override used to sit.
#
# What used to sit here was
#
#   sub _explain_sql { "EXPLAIN ANALYZE $_[1]" }
#
# and it is gone for two independent reasons.
#
# 1. It was already dead. ADR 0040 REMOVED the _explain_sql string hook and put
#    _explain_query in its slot -- not deprecated, not aliased -- so from DBIO
#    0.900004 on (the version the cpanfile already pins) core never called it
#    and $rs->explain here was silently already a plain EXPLAIN. Leaving the sub
#    in place would have kept claiming a behaviour the code no longer had.
#
# 2. It should not come back. explain must not have side effects, and on
#    PostgreSQL ANALYZE does not just add measured timings -- it EXECUTES the
#    query. Full runtime, plus everything the query touches: nextval() and other
#    volatile functions advance, a data-modifying CTE writes, triggers fire. A
#    caller asking what the planner intends does not expect its sequence counter
#    to move. Real timings are a thing to ask for, not to receive unasked.
#
# There is deliberately no option: the seam is a method. A caller who wants
# ANALYZE overrides _explain_query on a storage subclass and connects through it
# -- routing the statement through _execute_rendered as the contract requires,
# never $self->dbh. The POD above has the worked example. Pinned by
# t/46-explain-query-seam.t, which asserts on the statement the mock captured,
# not on a string.

# Async is an explicit, per-connection mode (core ADR 0030): a connection opened
# with connect(..., { async => 'ev' }) resolves the 'ev' mode through the mode
# registry to the native EV backend below. Registering on this driver storage
# class MRO-shadows the generic modes (forked/future_io) registered on the base
# storage, so 'ev' picks the PostgreSQL-specific backend. There is no auto-
# fallback and no silent degrade: a mode that is neither requested nor registered
# is simply unavailable, and requesting an unregistered/uninstalled mode croaks
# (see DBIO::Storage::DBI::_async_storage). This only stores the class name --
# DBIO::PostgreSQL::EV::Storage (the optional dbio-postgresql-ev dist) is loaded
# lazily on first use, so registering it here is safe when the dist is absent.
__PACKAGE__->register_async_mode( ev => 'DBIO::PostgreSQL::EV::Storage' );

# This is the ONLY async registration this driver needs, and it stays as-is
# under the storage-layer composition model (core karr k70): a mode maps to a
# transport BASE class, once, on this concrete driver storage. PostgreSQL
# EXTENSIONS (AGE, PostGIS, ...) no longer subclass storage_type nor add shadow
# register_async_mode / ::Async registrations -- they register plain storage
# LAYERS (DBIO::Schema::register_storage_layer) whose async mirrors compose ON
# TOP of the resolved transport via DBIO::Storage::Composed. Composition rides
# on top of this base; the mode->transport-base map does not grow per extension.


sub sql_maker {
  my $self = shift;
  # Core quotes by default (this class's sql_quote_char / sql_name_sep) and
  # leaves out what the connection turned off; it is not filled in again here.
  return $self->next::method(@_);
}

sub _determine_supports_insert_returning {
  return shift->_server_info->{normalized_dbms_version} >= 8.002
    ? 1
    : 0
  ;
}

sub _determine_supports_supports_upsert {
  my $self = shift;

  # INSERT ... ON CONFLICT exists since PostgreSQL 9.5; before that there is
  # no atomic upsert on this engine at all and DBIO::ResultSet::upsert has to
  # throw rather than emit a statement the server cannot parse.
  return 0 unless $self->_server_info->{normalized_dbms_version} >= 9.005;

  # ADR 0036 section 4: a driver may only declare the capability if the row it
  # hands back is provably the row that was written. On PostgreSQL that proof
  # is RETURNING. Without it, core falls back to last_insert_id -- and the
  # DO UPDATE branch still burns a nextval() from the column default, so that
  # id belongs to no row at all. Refusing the capability is the honest answer;
  # returning a confidently wrong row would not be.
  return $self->_use_insert_returning ? 1 : 0;
}

# ADR 0036 section 3 (core k134): the capability is DECLARED, not derived
# from supports_upsert. It answers about the conditional branch itself, and
# PostgreSQL has had the WHERE since 9.5, together with the ON CONFLICT
# grammar it hangs off -- there is no version that speaks the conflict clause
# but not its condition, so a static 1 loses nothing. Deriving would import
# supports_upsert's extra RETURNING demand, which is about naming the row
# that was written, a requirement the branch does not add to (a condition
# that does not hold writes no row by design) -- and core probes
# supports_upsert first and throws there, so a second 0 would carry no
# information and no better message.
#
# Declared through _determine_supports_* like the driver's other
# capabilities, rather than as _use_ class data, so the per-storage force
# slot stays the caller's.
sub _determine_supports_supports_upsert_where { 1 }

sub _ddl_statement_is_transactional {
  my ($self, $stmt) = @_;

  # ADR 0026 addendum (core k132). PostgreSQL's DDL is transactional with one
  # exception this driver can actually emit: ALTER TYPE ... ADD VALUE. Before
  # server 12 the engine rejects it outright inside a transaction block; from
  # 12 on it is accepted, but the new label stays unusable until that
  # transaction commits -- so a diff that adds an enum value and then
  # references it (a column default, a data migration) fails on every version,
  # just with a different error. Answering false here takes that one statement
  # out of the txn_do bracket and leaves the rest of the batch atomic.
  #
  # Anchored on the form DBIO::PostgreSQL::Diff::Type emits for
  # action => 'add_value' rather than on anything an ALTER TYPE could be. That
  # is the whole population: _execute_ddl only ever sees DDL this driver
  # generated. The narrowness is the point -- ALTER TYPE ... RENAME VALUE and
  # ALTER TYPE ... ADD ATTRIBUTE are transactional and must keep their
  # bracket, and a broad /ALTER\s+TYPE/ would quietly cost them it.
  return 0 if $stmt =~ /\A \s* ALTER \s+ TYPE \b [^;]*? \b ADD \s+ VALUE \b/xi;

  # karr k145: the VALIDATE CONSTRAINT behind an ADD CONSTRAINT ... NOT VALID
  # (DBIO::PostgreSQL::Diff::ForeignKey, action 'validate'). The statement is
  # transactional in itself; it is taken out of the bracket so that it runs
  # after the COMMIT of the add, in a transaction of its own: the lock the add
  # takes is not held over the reading of the rows, and a validation that
  # fails leaves the key NOT VALID (the next diff validates it again) instead
  # of taking the add back. Anchored on the form the op emits, two
  # identifiers (each bare or quoted, the quotes may hold ';' and '.') between
  # ALTER TABLE and VALIDATE CONSTRAINT; the other ALTER TABLE forms keep
  # their bracket.
  my $ident = qr/(?: "(?:[^"]|"")+" | [^\s".;]+ )/x;
  return 0 if $stmt =~ /\A \s* ALTER \s+ TABLE \s+ $ident (?: \. $ident )? \s+ VALIDATE \s+ CONSTRAINT \s/xi;

  return 1;
}


sub _ddl_sql_dialect { 'postgresql' }



sub _set_connection_schema {
  my ($self, $name, $activation) = @_;

  $self->_do_query('SET search_path TO ' . join ', ',
    map { DBIO::PostgreSQL::Util::quote_ident($_) }
    $self->_connection_search_path($name, $activation));

  return $self;
}


sub _connection_search_path {
  my ($self, $name, $activation) = @_;

  my $schema = $self->schema;
  my $declares = $schema
    && $schema->can('pg_extensions') && $schema->can('pg_extension_schemas');
  $activation //= $self->_extension_activation($name);

  my ($extensions, $given) = $declares
    ? ([ $schema->pg_extensions ], $schema->pg_extension_schemas) : ([], {});
  my @open = grep { !defined $given->{$_} } @$extensions;
  my %control;
  if (@open) {
    my $rows = $self->_pool_connect_rows(
      DBIO::PostgreSQL::DDL::control_schemas_sql(@open)) // [];
    %control = map { $_->[0] => $_->[1] } @$rows;
  }

  return DBIO::PostgreSQL::Util::connection_search_path(
    $name, $extensions, $given, $activation->{search_path}, \%control,
  );
}


sub _declared_search_path {
  my ($self, $activation) = @_;

  my $schema = $self->schema;
  return unless $schema && $schema->can('pg_search_path_declared')
    && $schema->pg_search_path_declared;
  $activation //= $self->_extension_activation(undef);

  return DBIO::PostgreSQL::Util::declared_search_path(
    [ $schema->pg_search_path ],
    [ $schema->pg_extensions ],
    $schema->pg_extension_schemas,
    $activation->{search_path},
  );
}


sub _extension_activation {
  my ($self, $name) = @_;
  my $none = { load => [], search_path => [] };

  my $list = DBIO::PostgreSQL::Extension->resolve_list($self->schema)
    or return $none;

  require DBIO::Extension::Protocol;
  return DBIO::Extension::Protocol->new(
    entries           => [ $list->entries ],
    driver            => DBIO::PostgreSQL::Extension->driver_helpers,
    connection_schema => $name,
    restricted        => 0,
  )->activation;
}


sub _apply_connection_schema {
  my ($self) = @_;
  my $name = $self->connection_schema;
  my $activation = $self->_extension_activation($name);

  $self->_do_query('LOAD ' . DBIO::PostgreSQL::Util::quote_literal($_))
    for @{ $activation->{load} };

  if (defined $name) {
    $self->_set_connection_schema($name, $activation);
  }
  elsif (my @declared = $self->_declared_search_path($activation)) {
    $self->_do_query('SET search_path TO ' . join ', ',
      map { DBIO::PostgreSQL::Util::quote_search_path_entry($_) } @declared);
  }
  elsif (my @path = @{ $activation->{search_path} }) {
    my $add = join ', ', map { DBIO::PostgreSQL::Util::quote_ident($_) } @path;
    $self->_do_query(
      q{SELECT pg_catalog.set_config('search_path', pg_catalog.current_setting('search_path') || }
      . DBIO::PostgreSQL::Util::quote_literal(", $add") . ', false)');
  }

  return $self;
}


sub _connect_params_dsn {
  my ($self, $driver, $params) = @_;

  my @parts;
  # A part without a value is as none given, as on the future_io transport.
  for my $key (grep { defined $params->{$_} && (ref $params->{$_} || length $params->{$_}) } qw(dbname host port)) {
    my $value = $params->{$key};
    $self->throw_exception(
      "Cannot build a DBD::Pg DSN from the connection parameter '$key': its "
    . 'value is a reference, not a value.'
    ) if ref $value;
    # The DSN is a C string from DBD::Pg on: it would end at the NUL, and the
    # parts behind this one would be gone with it.
    $self->throw_exception(
      "Cannot build a DBD::Pg DSN from the connection parameter '$key': its "
    . 'value contains a NUL character, which no connection string can carry.'
    ) if $value =~ /\0/;
    push @parts, "$key=" . DBIO::PostgreSQL::Util::quote_dsn_value($value);
  }

  # "dbi:Pg:" alone leaves the target to libpq's environment (PGHOST,
  # PGDATABASE, a service file): the credentials would go wherever it says.
  $self->throw_exception(
    'Cannot build a DBD::Pg DSN: the connection parameters name no dbname, '
  . 'host or port, so libpq would take the target from its environment '
  . '(PGHOST, PGDATABASE, ...). Give at least one of dbname, host or port.'
  ) unless @parts;

  return "dbi:$driver:" . join ';', @parts;
}


sub _refuse_dsn_without_target {
  my ($self, $dsn) = @_;

  return unless defined $dsn && !ref $dsn && length $dsn;
  return if $dsn !~ /\Adbi:Pg\b/i;
  return if DBIO::PostgreSQL::Util::dsn_names_target($dsn);

  $self->throw_exception(
    'Cannot connect with a DBD::Pg DSN that names no dbname, host or port, '
  . 'so libpq would take the target from its environment (PGHOST, '
  . 'PGDATABASE, ...). Give at least one of dbname, host or port (or '
  . 'service, hostaddr) in the DSN.'
  );
}


sub _connect {
  my $self = shift;

  $self->_refuse_dsn_without_target($self->_dbi_connect_info->[0])
    unless $self->access_broker;

  return $self->next::method(@_);
}


sub _access_broker_dbi_args {
  my ($self, $mode, %for) = @_;

  my ($args, $attrs) = $self->next::method($mode, %for);
  $self->_refuse_dsn_without_target($args->[0]) if $for{connecting};

  return ($args, $attrs);
}


sub _bind_host_into_dsn {
  my ($self, $driver, $dsn, $host, $port) = @_;

  if (defined $dsn and $dsn =~ /^(dbi:[^:]*:)(.*)\z/is) {
    my ($prefix, $rest) = ($1, $2);
    my @tokens = split /;/, $rest, -1;

    for my $token (@tokens) {
      next unless $token =~ /^(\w+)=(.*)\z/s;
      my ($key, $value, $lkey) = ($1, $2, lc $1);

      return (undef, "the key '$key' (a service file may name hostaddr)")
        if $lkey eq 'service';

      return (undef, "the key '$key' holding a connection string")
        if ($lkey eq 'dbname' or $lkey eq 'db' or $lkey eq 'database')
          and $value =~ m{^postgres(?:ql)?://}i || $value =~ /=/;

      return (undef, 'a port list without a port in the view')
        if $lkey eq 'port' and !defined $port and $value =~ /,/;
    }

    # libpq lets hostaddr win over host: with it gone, the host is the view's
    $dsn = $prefix . join ';', grep { !/^hostaddr=/i } @tokens;
  }

  return $self->next::method($driver, $dsn, $host, $port);
}


sub _dbi_error_fields {
  my ($self, $h) = @_;

  my $fields = $self->next::method($h);

  my $dbh = eval {
    Scalar::Util::blessed($h) && $h->can('pg_error_field') ? $h
      : Scalar::Util::blessed($h) ? scalar $h->{Database}
      : undef
  };
  return $fields
    unless Scalar::Util::blessed($dbh) && $dbh->can('pg_error_field');

  my %field = (
    constraint => 'constraint',
    table      => 'table',
    detail     => 'detail',
  );
  for my $key (sort keys %field) {
    my $value = eval { $dbh->pg_error_field($field{$key}) };
    next unless defined $value && length $value;
    $value = DBIO::PostgreSQL::Util::mask_detail_values($value) if $key eq 'detail';
    $fields->{$key} = $value;
  }

  return $fields;
}


sub _mask_error_values {
  my ($self, $text, $values, $statement) = @_;

  my $masked = $self->next::method($text, $values, $statement);
  return $masked unless defined $masked and !ref $masked;

  my $details = eval { DBIO::PostgreSQL::Util::mask_error_details($masked) };
  return defined $details ? $details : $masked;
}


sub with_deferred_fk_checks {
  my ($self, $sub) = @_;

  my $txn_scope_guard = $self->txn_scope_guard;

  $self->_do_query('SET CONSTRAINTS ALL DEFERRED');

  my $sg = DBIO::Util::scope_guard {
    $self->_do_query('SET CONSTRAINTS ALL IMMEDIATE');
  };

  return preserve_context { $sub->() } after => sub { $txn_scope_guard->commit };
}


sub pg_advisory_lock {
  my ($self, @keys) = @_;
  $self->_pg_advisory_run('pg_advisory_lock', @keys);
  return 1;
}


sub pg_advisory_lock_shared {
  my ($self, @keys) = @_;
  $self->_pg_advisory_run('pg_advisory_lock_shared', @keys);
  return 1;
}


sub pg_try_advisory_lock {
  my ($self, @keys) = @_;
  return $self->_pg_advisory_bool(
    $self->_pg_advisory_run('pg_try_advisory_lock', @keys)
  );
}


sub pg_try_advisory_lock_shared {
  my ($self, @keys) = @_;
  return $self->_pg_advisory_bool(
    $self->_pg_advisory_run('pg_try_advisory_lock_shared', @keys)
  );
}


sub pg_advisory_unlock {
  my ($self, @keys) = @_;
  return $self->_pg_advisory_bool(
    $self->_pg_advisory_run('pg_advisory_unlock', @keys)
  );
}


sub pg_advisory_unlock_shared {
  my ($self, @keys) = @_;
  return $self->_pg_advisory_bool(
    $self->_pg_advisory_run('pg_advisory_unlock_shared', @keys)
  );
}


sub pg_advisory_unlock_all {
  my ($self, @args) = @_;
  $self->throw_exception('pg_advisory_unlock_all takes no key arguments')
    if @args;
  $self->_execute_rendered('SELECT pg_advisory_unlock_all()', []);
  return 1;
}


sub pg_advisory_xact_lock {
  my ($self, @keys) = @_;
  $self->_pg_advisory_run('pg_advisory_xact_lock', @keys);
  return 1;
}


sub pg_advisory_xact_lock_shared {
  my ($self, @keys) = @_;
  $self->_pg_advisory_run('pg_advisory_xact_lock_shared', @keys);
  return 1;
}


sub pg_try_advisory_xact_lock {
  my ($self, @keys) = @_;
  return $self->_pg_advisory_bool(
    $self->_pg_advisory_run('pg_try_advisory_xact_lock', @keys)
  );
}


sub pg_try_advisory_xact_lock_shared {
  my ($self, @keys) = @_;
  return $self->_pg_advisory_bool(
    $self->_pg_advisory_run('pg_try_advisory_xact_lock_shared', @keys)
  );
}

# Shared body of the advisory-lock helpers. Each lock function takes either a
# single bigint key or a pair of int keys; the keys are bound as placeholders,
# never interpolated. The statement is a FROM-less SELECT that reads back the
# function's single-column result, so it goes down the rendered-statement path
# (_execute_rendered) exactly as results_exist does -- the same path the mock
# storage captures. Returns the function's single scalar return value.
sub _pg_advisory_run {
  my ($self, $func, @keys) = @_;

  $self->throw_exception(
    "$func requires either one bigint key or two int keys"
  ) unless @keys == 1 || @keys == 2;

  my $placeholders = join(', ', ('?') x @keys);
  my $bind = [ map { [ {}, $_ ] } @keys ];

  my (undef, $sth) = $self->_execute_rendered("SELECT $func($placeholders)", $bind);

  my $row = $sth->fetchall_arrayref->[0];
  return $row ? $row->[0] : undef;
}

# Normalise a PostgreSQL boolean column to a Perl boolean. DBD::Pg hands back
# either 't'/'f' (with pg_bool_tf on) or '1'/'0', so both spellings are folded
# to 1/0 here.
sub _pg_advisory_bool {
  my ($self, $val) = @_;
  return 0 if !defined $val || $val eq 'f' || $val eq '0' || $val eq '';
  return 1;
}


# only used when INSERT ... RETURNING is disabled
sub last_insert_id {
  my ($self, $source, @cols) = @_;

  my @values;
  my $col_info = $source->columns_info(\@cols);

  for my $col (@cols) {
    my $seq = ( $col_info->{$col}{sequence} ||= $self->dbh_do('_dbh_get_autoinc_seq', $source, $col) )
      or $self->throw_exception( sprintf(
        "Could not determine sequence for column '%s.%s', please consider adding a "
        . "schema-qualified sequence to its column info",
          $source->name,
          $col,
      ));

    push @values, $self->_dbh->last_insert_id(undef, undef, undef, undef, {sequence => $seq});
  }

  return @values;
}

sub _sequence_fetch {
  my ($self, $function, $sequence) = @_;

  $self->throw_exception('No sequence to fetch') unless $sequence;

  # The function is one of the two the sequence protocol knows; the sequence
  # name travels as a bind, cast to regclass, through the rendered-statement
  # path (trace, masking and statement hooks included).
  $self->throw_exception('Unknown sequence function')
    unless defined $function && $function =~ /\A(?:NEXTVAL|CURRVAL)\z/i;

  my (undef, $sth) = $self->_execute_rendered(
    sprintf('SELECT %s(?::regclass)', lc $function),
    [ [ {}, (ref $sequence eq 'SCALAR') ? $$sequence : $sequence ] ],
  );
  my $row = $sth->fetchall_arrayref->[0];

  return $row ? $row->[0] : undef;
}

sub _dbh_get_autoinc_seq {
  my ($self, $dbh, $source, $col) = @_;

  my $schema;
  my $table = $source->name;

  $table = $$table if ref $table eq 'SCALAR';

  if ($table =~ /^(.+)\.(.+)$/) {
    ($schema, $table) = ($1, $2);
  }

  my $seq_expr = $self->_dbh_get_column_default($dbh, $schema, $table, $col);

  unless (defined $seq_expr and $seq_expr =~ /^nextval\(+'([^']+)'::(?:text|regclass)\)/i) {
    $seq_expr = '' unless defined $seq_expr;
    $self->throw_exception( sprintf(
      "No sequence found for '%s%s.%s', check the RDBMS table definition or explicitly set the "
      . "'sequence' for this column in %s",
        $schema ? "$schema." : '',
        $table,
        $col,
        $source->source_name,
    ));
  }

  return $1;
}

sub _dbh_get_column_default {
  my ($self, $dbh, $schema, $table, $col) = @_;

  my $sqlmaker = $self->sql_maker;
  local $sqlmaker->{bindtype} = 'normal';

  my ($where, @bind) = $sqlmaker->where({
    'a.attnum'  => {'>', 0},
    'c.relname' => $table,
    'a.attname' => $col,
    -not_bool   => 'a.attisdropped',
    (defined $schema && length $schema)
      ? ('n.nspname' => $schema)
      : (-bool => \'pg_catalog.pg_table_is_visible(c.oid)')
  });

  my ($seq_expr) = $dbh->selectrow_array(<<"EOS", undef, @bind);

SELECT
  (SELECT pg_catalog.pg_get_expr(d.adbin, d.adrelid)
   FROM pg_catalog.pg_attrdef d
   WHERE d.adrelid = a.attrelid AND d.adnum = a.attnum AND a.atthasdef)
FROM pg_catalog.pg_class c
     LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
     JOIN pg_catalog.pg_attribute a ON a.attrelid = c.oid
$where

EOS

  return $seq_expr;
}


sub sqlt_type { 'PostgreSQL' }

sub _minmax_operator_for_datatype {
  #my ($self, $datatype, $want_max) = @_;

  return ($_[2] ? 'BOOL_OR' : 'BOOL_AND')
    if ($_[1] || '') =~ /\Abool(?:ean)?\z/i;

  shift->next::method(@_);
}


sub bind_attribute_by_data_type {
  my ($self, $data_type) = @_;

  if ($self->_is_binary_lob_type($data_type)) {
    unless ($DBD::Pg::__DBIO_DBD_VERSION_CHECK_DONE__) {
      if ($self->_server_info->{normalized_dbms_version} >= 9.0) {
        try { DBD::Pg->VERSION('2.17.2'); 1 } or carp(
          __PACKAGE__ . ': BYTEA columns are known to not work on Pg >= 9.0 with DBD::Pg < 2.17.2'
        );
      }
      elsif (not try { DBD::Pg->VERSION('2.9.2'); 1 }) { carp(
        __PACKAGE__ . ': DBD::Pg 2.9.2 or greater is strongly recommended for BYTEA column support'
      )}

      $DBD::Pg::__DBIO_DBD_VERSION_CHECK_DONE__ = 1;
    }

    return { pg_type => DBD::Pg::PG_BYTEA() };
  }
  else {
    return undef;
  }
}

# Savepoints via DBD::Pg native methods
# DBD::Pg writes the name into "savepoint %s" as it is, so the name is held
# to the plain form before it gets there; the message names the form, never
# the value.
sub _check_savepoint_name {
  my ($self, $name) = @_;
  $self->throw_exception(
    'A savepoint name is 1 to 63 characters of letters, digits and underscores, '
    . 'beginning with a letter or an underscore'
  ) unless defined $name && !ref $name && $name =~ /\A[A-Za-z_][A-Za-z0-9_]{0,62}\z/;
  return $name;
}

sub _exec_svp_begin {
  my ($self, $name) = @_;
  $self->_dbh->pg_savepoint($self->_check_savepoint_name($name));
}

sub _exec_svp_release {
  my ($self, $name) = @_;
  $self->_dbh->pg_release($self->_check_savepoint_name($name));
}

sub _exec_svp_rollback {
  my ($self, $name) = @_;
  $self->_dbh->pg_rollback_to($self->_check_savepoint_name($name));
}


sub is_replicating {
  my $self = shift;

  my $status = $self->_replication_status_row
    or return;

  return $self->_replication_status_streams($status);
}


sub lag_behind_master {
  my $self = shift;

  my $status = $self->_replication_status_row
    or return;

  return unless $self->_replication_status_streams($status);

  my $backlog = $status->{replay_backlog};
  return 0 if defined $backlog and $backlog <= 0;

  my $age = $status->{replay_age};
  return unless defined $age;

  return $age < 1 ? 0 : int $age;
}

# Whether a status row describes a standby that is streaming. The one reading
# both public methods share, so that lag_behind_master never reports a lag for
# a server is_replicating calls detached.
sub _replication_status_streams {
  my ($self, $status) = @_;

  return 0 unless $status->{in_recovery};
  return 0 unless defined $status->{receiver_pid};

  # pid without a state: the role is not in pg_read_all_stats. See the POD of
  # is_replicating for why that reads as streaming.
  my $state = $status->{receiver_status};
  return 1 unless defined $state;

  return $state eq 'streaming' ? 1 : 0;
}

# The engine seam: the facts both replication methods decide on, as a hashref,
# from one statement -- so that the two halves of an answer describe the same
# moment. Anything that needs replication state reads it here.
#
#   in_recovery      1 on a standby, 0 on a primary or a promoted standby
#   receiver_pid     the WAL receiver's pid; undef when pg_stat_wal_receiver
#                    has no row
#   receiver_status  its state; undef as well when the role may not read it
#   replay_backlog   bytes received but not yet replayed; 0 or less when
#                    caught up, undef when nothing was ever received by
#                    streaming
#   replay_age       seconds since the last replayed transaction was committed
#                    on the primary; undef when none has been replayed
#
# Every function in it is executable by PUBLIC and the view is readable by
# PUBLIC, so no role gets an error here -- only fewer columns. Returns nothing
# for a server older than PostgreSQL 10, where the pg_last_wal_*_lsn functions
# still had their xlog names; an unknown version is taken to be a current one.
sub _replication_status_row {
  my $self = shift;

  my $version = $self->_server_info->{normalized_dbms_version};
  return if $version and $version < 10;

  # By position, not selectrow_hashref: the key case of that one follows the
  # handle's FetchHashKeyName.
  my @row = $self->_get_dbh->selectrow_array(<<'EOS') or return;
SELECT pg_catalog.pg_is_in_recovery()::int,
       r.pid,
       r.status,
       pg_catalog.pg_wal_lsn_diff(
         pg_catalog.pg_last_wal_receive_lsn(),
         pg_catalog.pg_last_wal_replay_lsn()
       ),
       EXTRACT(EPOCH FROM
         pg_catalog.clock_timestamp() - pg_catalog.pg_last_xact_replay_timestamp()
       )
  FROM (SELECT 1) AS one
  LEFT JOIN pg_catalog.pg_stat_wal_receiver AS r ON true
EOS

  my %status;
  @status{qw( in_recovery receiver_pid receiver_status replay_backlog replay_age )} = @row;

  return \%status;
}



sub cake_defaults {
  return (
    inflate_jsonb     => 1,
    inflate_datetime  => 1,
    retrieve_defaults => 1,
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Storage - PostgreSQL storage layer for DBIO

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::PostgreSQL::Storage> is the DBI storage class for PostgreSQL. It
extends L<DBIO::Storage::DBI> with PostgreSQL-specific behaviour:

=over 4

=item *

C<INSERT ... RETURNING> for efficient last-insert-id retrieval (PostgreSQL 8.2+).

=item *

Atomic upsert (L<DBIO::ResultSet/upsert>) via C<INSERT ... ON CONFLICT>
(PostgreSQL 9.5+), rendered by L<DBIO::PostgreSQL::SQLMaker>. The
C<supports_upsert> capability is version-gated and additionally requires
C<INSERT ... RETURNING> to be in use, because that is what proves the returned
row is the row that was written.

=item *

The conditional conflict branch, C<< $rs->upsert(..., { update_where => ... }) >>
rendered as C<DO UPDATE ... WHERE> — the last-write-wins guard. Its own
C<supports_upsert_where> capability is B<declared, not derived> from
C<supports_upsert> (ADR 0036 section 3): it is a plain fact about the
conditional branch itself, and PostgreSQL has had the C<WHERE> since 9.5,
together with the clause it hangs off. Core probes C<supports_upsert> first
and throws there, so the declaration never sends a conditional branch to a
driver whose conflict clause it cannot render.

=item *

Boolean-valued C<EXISTS> queries (L<DBIO::ResultSet/results_exist> and its two
siblings) via the C<supports_exists_query> capability, core ADR 0037. This
driver declares the capability and does B<not> override
L<DBIO::Storage::DBI/_exists_value_sql>: PostgreSQL documents both things the
base rendering C<SELECT CASE WHEN EXISTS E<lt>innerE<gt> THEN 1 ELSE 0 END>
needs -- C<EXISTS> yielding a boolean I<value>, and a C<SELECT> with no
C<FROM>. Core defaults the capability to C<0> and all three methods throw
without it, so the declaration is what makes them work here; it is not a
formality.

=item *

Query plans (L<DBIO::ResultSet/explain>) B<without> C<ANALYZE>. This driver
takes core's base L<DBIO::Storage::DBI/_explain_query> unchanged, so
C<< $rs->explain >> issues a plain C<EXPLAIN> and returns PostgreSQL's
estimated plan as rows. See L</Query plans are planned, not run> for why
C<ANALYZE> is not the default and how to ask for it anyway.

=item *

Transactional DDL. PostgreSQL rolls C<CREATE TABLE> and friends back with the
transaction around them, so this class declares the C<transactional_ddl>
capability and L<DBIO::Deploy::Base> brackets the DDL of an install or upgrade
in C<< $storage->txn_do >>: a failure part way through takes the earlier
statements with it instead of leaving the schema half migrated. Many engines
cannot do this — MySQL, MariaDB, Oracle, Sybase and Informix force an implicit
C<COMMIT> on DDL — which is why core defaults the capability to off and each
driver states its own answer. Not a promise of one transaction per batch, though: the one
statement this driver emits that PostgreSQL cannot run usefully inside a
transaction, C<ALTER TYPE ... ADD VALUE>, is taken out of the bracket by
L</_ddl_statement_is_transactional>, and a batch containing one is split around
it rather than being atomic as a whole.

=item *

Deferred foreign key checks via C<SET CONSTRAINTS ALL DEFERRED>.

=item *

Sequence lookup via C<pg_catalog> when C<RETURNING> is not available.

=item *

C<BYTEA> column binding through C<DBD::Pg> native type constants.

=item *

Native savepoint support via C<pg_savepoint>, C<pg_release>, and
C<pg_rollback_to>.

=item *

Replication status for L<DBIO::Replicated::Pool>: L</is_replicating> and
L</lag_behind_master> answer for a streaming hot standby, so the pool takes a
standby out that has lost its primary, was promoted, or is further behind than
C<maximum_lag> (PostgreSQL 10+).

=item *

Deployment through L<DBIO::PostgreSQL::Deploy> and L<DBIO::PostgreSQL::DDL>.
This class names the deploy class in C<dbio_deploy_class>, and
C<< $schema->deploy >> and C<< $storage->deploy >> install through it whether
or not the schema has the L<DBIO::PostgreSQL> component loaded. See
L</Installing a schema>.

=item *

The connect key C<schema>: C<< MyApp::Schema->connect($dsn, $user, $pass,
{ schema => 'tenant_a' }) >> makes C<tenant_a> the namespace every connection
of the schema works in, by its C<search_path>
(L</_set_connection_schema>). One schema class serves any number of
namespaces; see L<DBIO::PostgreSQL/ONE SCHEMA CLASS IN SEVERAL NAMESPACES>.

=item *

Opt-in async via C<< MyApp::Schema->connect($dsn, $user, $pass, { async => 'ev' }) >>.
The C<ev> mode resolves (core ADR 0030 mode registry) to the native EV backend
from the optional L<DBIO::PostgreSQL::EV> dist, loaded lazily on first use. Without
that dist installed, requesting the mode croaks with a clear C<install> message —
there is no silent fallback or degrade.

=back

This class is registered as the driver for the C<Pg> DBD and is selected
automatically when L<DBIO::PostgreSQL> is loaded into a schema class.
Schema-introspection and migration planning live in
L<DBIO::PostgreSQL::Introspect>, L<DBIO::PostgreSQL::Diff>, and
L<DBIO::PostgreSQL::Deploy>; this class stays focused on the live DBI storage
behaviour.

=head2 Query plans are planned, not run

L<DBIO::ResultSet/explain> asks this storage for a plan through core's
L<DBIO::Storage::DBI/_explain_query> seam (core ADR 0040), and this driver
B<does not override it>. What you get is core's base operation, which is
already the correct one for PostgreSQL:

  EXPLAIN <the resultset's SELECT>

-- the planner's B<estimated> plan (node types, cost estimates, estimated row
counts), returned as an arrayref of row arrayrefs, one row per line of
PostgreSQL's plan output. The query itself is B<not executed>.

Earlier releases of this driver spelled the hook C<EXPLAIN ANALYZE>. That is
gone on purpose: C<explain> must not have side effects. On PostgreSQL,
C<ANALYZE> does not merely add real timings to the output -- it B<runs the
query>. That costs the query's full runtime, and it executes everything the
query touches: C<nextval()> and other volatile functions advance, a data-
modifying CTE writes, triggers fire. A caller asking what the planner intends
to do does not expect its sequence counters to move, so real timings have to be
asked for rather than handed out unasked.

There is no option for it, because the seam is a method, not a setting. A
caller who genuinely wants measured runtimes overrides the hook on a storage
subclass and connects through it:

  package MyApp::Storage::PgAnalyze;
  use base 'DBIO::PostgreSQL::Storage';

  # WARNING: this EXECUTES the query being explained.
  sub _explain_query {
    my ($self, $sql, $bind) = @_;
    my (undef, $sth) = $self->_execute_rendered("EXPLAIN ANALYZE $sql", $bind);
    return $sth->fetchall_arrayref;
  }

  MyApp::Schema->connect($dsn, $user, $pass,
    { storage_type => 'MyApp::Storage::PgAnalyze' });

Note C<_execute_rendered>: core's contract requires every statement an override
issues to go through the storage's statement path, never C<< $self->dbh >>.
That is what keeps tracing and therefore C<redact_bind_value> (core ADR 0025),
C<dbh_do> retry over a dropped connection, and -- on a
L<DBIO::Replicated::Storage> -- the read handler rather than the master's.

=head2 Extensions and the async backends see the capability declarations

Neither the PostgreSQL extension dists (C<dbio-postgresql-age>,
C<dbio-postgresql-postgis>) nor the async backends need to repeat a capability
this class declares, and for two different reasons -- which is worth stating,
because "the subclasses inherit it" is true of neither: neither is a subclass.

An extension is a storage B<layer>, composed by
L<DBIO::Storage::Composed> into a class whose C<@ISA> is
C<(@layers, DBIO::PostgreSQL::Storage)>. The capability accessors are
C<inherited>-type class data, resolved along the linearised C<@ISA>, so the
composed class answers with this class's declaration -- as a class method, and
without the layer knowing the capability exists.

The async backends -- C<DBIO::PostgreSQL::Storage::Async> (the C<future_io>
transport) and C<DBIO::PostgreSQL::EV::Storage> (the C<ev> backend) -- descend
from L<DBIO::Storage::Async>, not from this class, and therefore have no
capability accessors at all. They do not need them: async is a per-connection
mode on B<this> storage (ADR 0030), so L<DBIO::ResultSet/results_exist_async>
probes the capability and renders the statement here, and hands the backend
only the finished SQL for its C<_query_async> seam. One declaration, one
engine fact, every transport.

=head2 Installing a schema

This class has no C<deploy> and no C<deployment_statements> of its own. Both
are L<DBIO::Storage::DBI>'s (core ADR 0064).

C<< $storage->deploy($schema) >> connects and installs the schema through the
class L</dbio_deploy_class> names:
C<< $class->new(schema => $schema)->install >>, which is what
C<< $schema->deploy >> does. The two end in the same install, whether or not
the schema has the L<DBIO::PostgreSQL> component loaded. A L<DBIO::Replicated>
schema arrives there as well: its storage hands C<deploy> to the storage of
its master. The DDL is generated from the schema, so C<$type>, C<$sqltargs>
and C<$dir> are not read, and a DDL file in the deploy directory is not
executed.

C<< $storage->deployment_statements($schema, $type, $version, $dir) >> and
C<< $schema->deployment_statements >> generate no SQL. They return the
contents of a DDL file that is in C<$dir> already -- named by L</sqlt_type>
where no C<$type> is given -- and throw when there is none, for a schema with
the component as for one without. Neither asks the server anything. The
install DDL of a schema is what L<DBIO::PostgreSQL/pg_install_ddl> and
L<DBIO::PostgreSQL::DDL/install_ddl> return.

=head1 METHODS

=head2 dbio_deploy_class

    my $class = $storage->dbio_deploy_class;   # 'DBIO::PostgreSQL::Deploy'

Names this driver's native deploy class, L<DBIO::PostgreSQL::Deploy>, and is
the one place that does. Core asks for it: L<DBIO::Schema/deploy> and
L<DBIO::Storage::DBI/deploy> load the class and call
C<< $class->new(schema => $schema)->install >>, and
L<DBIO::DeploymentHandler::DeployMethod::Native> hands its deploy, upgrade and
diff to an object of it. All three do so whether or not the schema has the
L<DBIO::PostgreSQL> component loaded. L<DBIO::PostgreSQL/pg_deploy> returns an
object of the class named here. Only the name is given; the class is loaded
when it is first used.

The driver storage is its one owner. An extension does not name a deploy class
of its own: its rules reach the deploy through the list of extensions the
schema declares (L<DBIO::PostgreSQL::Deploy/EXTENSIONS>).

=head2 sql_maker

    my $sql_maker = $storage->sql_maker;

The SQL maker of L<DBIO::Storage::DBI/sql_maker>, a
L<DBIO::PostgreSQL::SQLMaker>, as the core builds it. Identifiers are quoted
with C<"> and separated by C<.> unless the connection says otherwise: nothing
given quotes, C<< quote_names => 0 >> alone writes them unquoted, and so does
an empty C<quote_char> alone. An explicit C<quote_char> or C<name_sep> is used
as given.

Quoting that was turned off stays off; PostgreSQL then folds an unquoted name
to lower case. The C<future_io> transport of the same connection takes its
C<quote_char> and C<name_sep> from this maker
(L<DBIO::PostgreSQL::Storage::Async/_sql_maker_args>), so both paths quote
alike.

=head2 _ddl_statement_is_transactional

    my $bool = $storage->_ddl_statement_is_transactional($ddl_statement);

The per-statement half of the C<transactional_ddl> capability (ADR 0026
addendum). False for C<ALTER TYPE ... ADD VALUE>, which PostgreSQL cannot run
usefully inside a transaction on any supported server version, and for
C<ALTER TABLE ... VALIDATE CONSTRAINT>, which is transactional but is kept
out of the bracket on purpose: it runs after the COMMIT of the
C<ADD CONSTRAINT ... NOT VALID> before it, so the lock of the add is not held
over the reading of the rows and a failed validation leaves the key
C<NOT VALID>. True for everything else this driver emits.
L<DBIO::Deploy::Base/_execute_ddl> groups a DDL batch by this answer, so
these statements run on their own while the rest of the diff keeps its
C<txn_do>. Core warns once that the batch was split; that is expected here.

=head2 _ddl_sql_dialect

    my $dialect = $storage->_ddl_sql_dialect;    # 'postgresql'

Names the SQL dialect this driver's DDL is written in, for the splitter
L<DBIO::Deploy::Base/_execute_ddl> cuts install and upgrade DDL with
(L<DBIO::Storage::DBI::Capabilities/_ddl_sql_dialect>). Declared,
the splitter reads what only PostgreSQL has: the body of
C<CREATE FUNCTION ... BEGIN ATOMIC ... END> and of a C<CREATE RULE ... DO ALSO
(...; ...)> as one statement, block comments that nest, and a backslash in a
string literal as a character (C<standard_conforming_strings>), so
C<'a\'> ends there. Undeclared, it takes both readings of the backslash and
none of the rest.

=head2 _set_connection_schema

    MyApp::Schema->connect($dsn, $user, $pass, { schema => 'tenant_a' });
    # every connection: SET search_path TO tenant_a, public

What the connect key C<schema> means on PostgreSQL (the seam of
L<DBIO::Storage::DBI/_set_connection_schema>, core ADR 0065): the namespace
the connection works in is the first schema of its C<search_path>. Core calls
this on every new connection that names the key -- the sync one and each
connection of an async pool -- ahead of C<on_connect_call> and
C<on_connect_do>, and the one statement written here,
C<SET search_path TO ...>, goes to that connection.

The path is L</_connection_search_path>. See
L<DBIO::PostgreSQL/ONE SCHEMA CLASS IN SEVERAL NAMESPACES> for what the key
does to a deploy.

PostgreSQL takes a C<search_path> that names a schema it does not have and
skips that schema when it looks a name up. A connection whose namespace is
not there yet therefore connects, and an unqualified name is looked for --
and an unqualified object created -- in the schemas behind it. The install of
such a connection creates the namespace before it creates anything else
(L<DBIO::PostgreSQL::DDL/install_ddl>).

=head2 _connection_search_path

    my @schemas = $storage->_connection_search_path('tenant_a');
    # ('tenant_a', 'public')

The schemas of the C<search_path> of a connection that works in the given
namespace, by the rule of
L<DBIO::PostgreSQL::Util/connection_search_path>: the namespace, then the
schemas of the extensions the schema class declares
(L<DBIO::PostgreSQL/pg_extensions>), for an extension that names none the
schema its control file fixes (asked of the server over
L<DBIO::Storage::DBI/_pool_connect_rows>, so on the sync handle and on a pool
connection alike, only for the extensions without a declared schema; a runner
that answers no rows, as the C<ev> one, leaves them at C<public>),
else C<public>, and C<public> when none is declared, then the C<search_path> entries of the
extensions' activation (L</_extension_activation>; given as the second
argument by L</_apply_connection_schema>, else asked for). A storage whose
schema class does not load the L<DBIO::PostgreSQL> component, and one that has
no schema class, declares no extension. L<DBIO::PostgreSQL/pg_search_path> is
not read.

=head2 _declared_search_path

    my @schemas = $storage->_declared_search_path($activation);

The schemas of the C<search_path> of a connection without the connect key
whose schema class declared L<DBIO::PostgreSQL/pg_search_path>, by the rule of
L<DBIO::PostgreSQL::Util/declared_search_path>: the declared entries, the
schemas the declared extensions name, the entries of the extensions'
activation (the second argument, else asked for). Empty -- nothing is set --
for a schema that declared no path, one that does not load the
L<DBIO::PostgreSQL> component, and a storage that has no schema class.

=head2 _extension_activation

    my $activation = $storage->_extension_activation($namespace);
    # { load => [ 'age' ], search_path => [ 'ag_catalog' ] }

What the declared extensions want of a new connection (ADR 0066, activation),
merged by core in the name order of the extensions
(L<DBIO::Extension::Protocol/activation>): the libraries to C<LOAD> and the
schemas for the C<search_path>. Core refuses what it cannot compose -- two
libraries for one name. The list is resolved here, at the first use of a
connection and so after the driver is resolved, never at C<connect>: the
classes are loaded, their interface version and their driver assertion
checked (L<DBIO::PostgreSQL::Extension/resolve_list>). A schema that declares
no extension has an empty activation and nothing is loaded.

The extensions see the state of the connection as far as it is known when it
opens: C<< $ctx->{peers}{$name}{installed} >> is false here, the installed
state is read by the deploy, not by a connect. C<< $ctx->{restricted} >> is
false likewise.

=head2 _apply_connection_schema

The one place a new connection is set up for the extensions and the namespace,
for the sync connection and for every connection of an async pool alike (core
runs it ahead of C<on_connect_call> and C<on_connect_do> on both paths). It
replaces core's, which only sets the namespace, and does what that does:

=over 4

=item 1.

C<LOAD 'library'> for every library of L</_extension_activation>, in the order
of the extensions' names.

=item 2.

With the connect key C<schema>: L</_set_connection_schema>, the C<search_path>
of L</_connection_search_path>.

=item 3.

Without it, when the schema class declared L<DBIO::PostgreSQL/pg_search_path>:
C<SET search_path TO ...> of L</_declared_search_path>, in one statement --
the declared entries, the schemas the declared extensions name, the entries of
the activation. It replaces the path the DSN or the role gave;
C<on_connect_call> and C<on_connect_do> run behind it and can replace it in
turn.

=item 4.

Without it and without a declaration: the entries of the activation, if any,
are appended to the C<search_path> the connection has (the server's default or
the role's), once each, in one statement. Without extensions with an
activation nothing is sent.

=back

An extension's activation does not change the C<search_path> of a connection
of a schema that declares none beyond that; the schemas of C<pg_extensions>
stay what they were: part of the path of a connection that names a namespace,
and of a declared path when they name a schema.

=head2 _connect_params_dsn

    my $dsn = $storage->_connect_params_dsn('Pg', { dbname => 'my db', host => 'db1', port => 5433 });
    # dbi:Pg:dbname='my db';host=db1;port=5433

The DSN seam of L<DBIO::Storage::DBI/_connect_params_dsn> (core ADR 0057),
asked when a schema is connected with connection parameters instead of a DSN
-- a connect-info hash with a C<dbname> and no C<dsn>, or a
L<DBIO::AccessBroker::Static>. The form is core's default,
C<dbi:Pg:dbname=...;host=...;port=...> with the parts not given left out; it
is overridden for what goes into it. Core's default writes a value as it
comes, and L<DBD::Pg> and libpq both read that text again: a blank ends the
value, an apostrophe takes the parameters behind it along, a backslash
disappears, and C<key=value> behind a name is a second parameter. Here every
value is written by L<DBIO::PostgreSQL::Util/quote_dsn_value>, so libpq reads
back what was given:

    MyApp::Schema->connect({ dbname => 'my db', host => 'db1', user => ..., password => ... });
    # the database "my db"

A value is a value, whatever is in it. C<< dbname => '"app"' >> is the
database C<"app">, quotes included, and C<< dbname => 'app sslmode=require' >>
is a database of that name -- neither the L<DBD::Pg> nor the libpq way of
quoting, and no further parameter, can be put into one. What the three parts
cannot say goes in as the whole DSN: as C<dsn>, or as a C<dbname> that starts
with C<dbi:Pg:>, which core takes as the DSN before this seam is asked.

The C<future_io> transport writes a broker's parameters through the same
function (L<DBIO::PostgreSQL::Storage::Async/_async_broker_conninfo>), so the
sync connection of a schema and its C<future_io> backend hold the same DSN
for the same C<dbname>, C<host> and C<port>, and open the same database.

The DSN names no C<sslmode>, and without it libpq connects with C<prefer>: a
server that does not offer TLS is then connected to in the clear. For a
connection over a network give the whole DSN with C<sslmode=verify-full> and
C<sslrootcert=/path/to/ca.crt>, which checks the certificate and the host
name.

A part that is undefined or empty is as none given. When none of C<dbname>,
C<host> and C<port> is given the DSN would be C<dbi:Pg:>, and libpq would take
the target from its environment (C<PGHOST>, C<PGDATABASE>, a service file):
that is refused, naming the three parameters. One of them is
enough.

Refused, naming the parameter and never its value: a value that is a
reference, and one containing a NUL character -- no connection string can
carry it. A value containing C<;> does not get here: core refuses it first,
for every driver.

=head2 _refuse_dsn_without_target

    $storage->_refuse_dsn_without_target($dsn);

Throws when C<$dsn> is a whole C<dbi:Pg:> DSN that names no C<dbname>, C<host>
or C<port> (nor C<hostaddr> or C<service>, which name a target themselves):
C<dbi:Pg:>, C<dbi:Pg:;>, C<dbi:Pg:sslmode=require>. Such a DSN leaves the
target to libpq's environment (C<PGHOST>, C<PGDATABASE>, a service file), so
the credentials would go wherever the process environment says -- the same
refusal as for connection parameters that name none (L</_connect_params_dsn>).
The message names the parameters, never the DSN, which may carry a password. A
connection coderef, an undefined or an empty DSN are not its business (core
refuses those). The rule is L<DBIO::PostgreSQL::Util/dsn_names_target>.

It is asked where a connection is made, not where connect info is given: a
schema that only generates SQL connects with C<connect('dbi:Pg:')> and never
opens one (L</_connect>).

=head2 _connect

Opens the connection as core does, after refusing a static DSN that names no
target (L</_refuse_dsn_without_target>). A storage with an AccessBroker asks
the broker's answer at L</_access_broker_dbi_args> instead, where the DSN of
this very connection is known.

=head2 _access_broker_dbi_args

The arguments of C<< DBI->connect >> from the broker's answer, as core forms
them; for the connection itself (C<< connecting => 1 >>) a DSN that names no
target is refused first (L</_refuse_dsn_without_target>). A plain read of the
answer is not a connection and refuses nothing.

=head2 _bind_host_into_dsn

    my $dsn = $storage->_bind_host_into_dsn('Pg', 'dbi:Pg:dbname=app;hostaddr=10.0.0.1', 'replica1', 5433);
    # dbi:Pg:dbname=app;host=replica1;port=5433

    my ($none, $form) = $storage->_bind_host_into_dsn('Pg', 'dbi:Pg:service=prod', 'replica1', undef);
    # ( undef, "the key 'service' (a service file may name hostaddr)" )

The seam of L<DBIO::Storage::DBI/_bind_host_into_dsn> (core ADR 0013, addendum
2026-10-09): what a L<DBIO::AccessBroker::HostBound> view -- a replicant of
L<DBIO::Replicated> -- asks to put its own host (and port) into the DSN a
broker answered, so one answer serves many servers. Core's default binds
C<host=> and C<port=> and declines C<hostaddr=>. libpq reads a C<hostaddr=>
before the C<host=>, so a replicant would have gone to the server the answer
named; this driver therefore

=over

=item * B<removes> every C<hostaddr=> token, whatever the case of its key and
however often it stands, and lets core bind C<host=> and C<port=> into what is
left. A view host that is an IP address is then connected to directly, as
C<hostaddr=> would have done, and a name is resolved by libpq. The server
list C<host=a,b> is replaced by the one host of the view, as core does;

=item * B<declines> a C<service=> -- a service file may name C<hostaddr>, and
no DSN says what is in the file: C<the key 'service' (a service file may name
hostaddr)>;

=item * B<declines> a C<dbname=>, C<db=> or C<database=> that begins with
C<postgresql://> or C<postgres://> or contains a C<=>: libpq reads that as a
whole connection string, which carries a host of its own and goes on top of
the keys around it;

=item * B<declines> a C<port=> that is a comma list when the view has no port
of its own, since a replicant then has no way to name the one port of its
host. A view that has a port replaces the whole token.

=back

Whatever else the DSN holds goes through core's default, which declines the
forms it does not know the same way. A declined form is named and no value of
the DSN is in it.

The environment is not read: a C<PGHOSTADDR> or C<PGSERVICE> in the process
that connects is libpq's own and applies to every connection of it.

=head2 _dbi_error_fields

    my $fields = $storage->_dbi_error_fields($handle);

Core's seam (L<DBIO::Storage::DBI/_dbi_error_fields>) for the machine-readable
part of a refused statement, the fields of the L<DBIO::Exception::Server>
core raises for it. The base answers C<sqlstate>; this adds, from DBD::Pg's
C<pg_error_field>, the C<constraint> the statement violated, the C<table> and
the C<detail> (C<Key (name)=(***) already exists.>: the values in it are
replaced by C<***> and the column names stay, as they do in the C<DETAIL:>
line of the message, which L</_mask_error_values> masks;
L<DBIO::PostgreSQL::Util/mask_detail_values>) -- the server's own
C<PG_DIAG_CONSTRAINT_NAME>, C<PG_DIAG_TABLE_NAME> and
C<PG_DIAG_MESSAGE_DETAIL>, not parsed out of the text, which depends on the
server's C<lc_messages>.

C<pg_error_field> is a method of the database handle. DBI hands
C<HandleError> the handle the error occurred on, a statement handle for a
failed C<execute>, and the database handle is then read from its C<Database>
attribute. A field the server did not report, or reported empty, is left out.
Nothing here connects or queries: C<pg_error_field> only reads the result the
failure left on the handle, which is why it is asked from within
C<HandleError>, before anything else runs on the connection.

The future_io transport (L<DBIO::PostgreSQL::Storage::Async>) raises a plain
string and has no such seam; its errors do not carry these fields (it masks the
values of the text by its own route, see L<DBIO::PostgreSQL::Storage::Async/ERRORS>).

=head2 _mask_error_values

    my $text = $storage->_mask_error_values($text, \@values, $statement);

Core's seam (L<DBIO::Storage::DBI/_mask_error_values>) through which the text
the server wrote into an error passes before it is thrown: from the error
handler of every handle, the statement C<_dbh_execute> runs and the statements
of the connection actions. The base replaces the values bound to the statement
in it, each one whole, wherever it stands. This replaces, behind it, the values
the server quotes, by the form of its text
(L<DBIO::PostgreSQL::Util/mask_error_details>): the value of an C<invalid input
syntax for type integer: "...">, of a C<DETAIL:> line (C<Key (a)=(...)>,
C<Failing row contains (...)>), of the C<CONTEXT:> of a bound parameter and of
a JSON excerpt. That covers what the base does not know: a value shorter than
four characters, a piece of a value (C<invalid value "gehe" for "YYYY">), a
value the statement did not bind (one of the row a constraint names) and every
error that reaches the handler with no values at hand. A value that is a name
in the text (C<relation "x" does not exist>) is replaced by the base only,
which knows the bound values.

A text with no known form is returned as it is, C<undef> and a reference as
they are. It never throws: a text the rules cannot read stays as the base
left it.

=head2 with_deferred_fk_checks

    $storage->with_deferred_fk_checks(sub { ... });

Wraps the given coderef in a transaction with C<SET CONSTRAINTS ALL DEFERRED>,
restoring immediate constraint checking afterwards. Use this when bulk-loading
data that temporarily violates referential integrity.

=head2 pg_advisory_lock

    $storage->pg_advisory_lock(42);         # SELECT pg_advisory_lock(?)
    $storage->pg_advisory_lock(10, 20);     # SELECT pg_advisory_lock(?, ?)

Acquires a session-level exclusive advisory lock, blocking until it is
available. The lock is identified either by a single C<bigint> key or by a
pair of C<int> keys; the keys are bound as placeholders, never interpolated.
Returns true once the lock is held. Session-level locks are held until
explicitly released (see L</pg_advisory_unlock>) or the session ends.

=head2 pg_advisory_lock_shared

    $storage->pg_advisory_lock_shared(42);

Like L</pg_advisory_lock> but acquires a I<shared> session-level advisory lock
(C<pg_advisory_lock_shared>). Returns true once the lock is held.

=head2 pg_try_advisory_lock

    my $got = $storage->pg_try_advisory_lock(42);

Non-blocking variant of L</pg_advisory_lock> (C<pg_try_advisory_lock>): returns
true if the lock was acquired, false if it could not be obtained immediately.

=head2 pg_try_advisory_lock_shared

    my $got = $storage->pg_try_advisory_lock_shared(42);

Non-blocking shared variant (C<pg_try_advisory_lock_shared>): returns true if
the shared lock was acquired, false otherwise.

=head2 pg_advisory_unlock

    my $released = $storage->pg_advisory_unlock(42);

Releases a session-level exclusive advisory lock previously acquired with
L</pg_advisory_lock> (C<pg_advisory_unlock>). Returns true if a lock held by
this session was released, false if no such lock was held.

=head2 pg_advisory_unlock_shared

    my $released = $storage->pg_advisory_unlock_shared(42);

Releases a session-level shared advisory lock (C<pg_advisory_unlock_shared>).
Returns true if a matching lock was released, false otherwise.

=head2 pg_advisory_unlock_all

    $storage->pg_advisory_unlock_all;

Releases every session-level advisory lock held by the current session
(C<pg_advisory_unlock_all>). Takes no key arguments. Returns true.

=head2 pg_advisory_xact_lock

    $storage->pg_advisory_xact_lock(42);
    $storage->pg_advisory_xact_lock(10, 20);

Acquires a transaction-level exclusive advisory lock
(C<pg_advisory_xact_lock>), blocking until it is available. Transaction-level
locks are released automatically at the end of the current transaction; there
is no corresponding manual unlock. Returns true once the lock is held.

=head2 pg_advisory_xact_lock_shared

    $storage->pg_advisory_xact_lock_shared(42);

Shared transaction-level advisory lock (C<pg_advisory_xact_lock_shared>),
released automatically at transaction end. Returns true once the lock is held.

=head2 pg_try_advisory_xact_lock

    my $got = $storage->pg_try_advisory_xact_lock(42);

Non-blocking transaction-level advisory lock (C<pg_try_advisory_xact_lock>):
returns true if the lock was acquired, false otherwise. Released automatically
at transaction end.

=head2 pg_try_advisory_xact_lock_shared

    my $got = $storage->pg_try_advisory_xact_lock_shared(42);

Non-blocking shared transaction-level advisory lock
(C<pg_try_advisory_xact_lock_shared>): returns true if the shared lock was
acquired, false otherwise. Released automatically at transaction end.

=head2 last_insert_id

    my @ids = $storage->last_insert_id($source, @cols);

Returns the last inserted value(s) for the given column(s) by querying the
associated sequence via C<pg_catalog>. Only called when C<INSERT ... RETURNING>
is unavailable (PostgreSQL older than 8.2). The sequence is determined from the
column default expression.

=head2 sqlt_type

    my $type = $storage->sqlt_type;   # 'PostgreSQL'

The name of this engine, C<PostgreSQL>, as a constant: unlike
L<DBIO::Storage::DBI/sqlt_type> it asks no connection for the DBD's name.
The inherited L<DBIO::Storage::DBI/deployment_statements> names a DDL file by
it, so reading that file needs no server (see L</Installing a schema>).

=head2 bind_attribute_by_data_type

    my $attr = $storage->bind_attribute_by_data_type($data_type);

Returns C<{ pg_type =E<gt> DBD::Pg::PG_BYTEA() }> for binary LOB types so that
C<DBD::Pg> handles C<BYTEA> columns correctly. Also checks that a compatible
C<DBD::Pg> version is installed for the connected PostgreSQL server version.

=head2 is_replicating

    my $streaming = $storage->is_replicating;

Whether the connected server is a standby that is streaming from its primary.
This is what L<DBIO::Replicated::Pool/validate_replicants> asks every
replicant, and it tells three answers apart: a true one goes on to
L</lag_behind_master>, a false but defined one deactivates the replicant, and
no answer at all leaves the replicant as it is.

=over 4

=item *

B<A server that is not in recovery answers 0.> That is a primary, and it is a
standby that has been promoted: neither follows a primary, so neither is a
replica to read from, and PostgreSQL can say so (C<pg_is_in_recovery()>).
L<DBIO::MySQL::Storage> answers nothing for a server that is not a replica;
here that would keep a promoted standby in the pool for good. A primary listed
as a replicant by mistake loses nothing by the 0: with no replicant active the
balancer reads from the master.

=item *

B<A standby without a WAL receiver answers 0>, and so does one whose WAL
receiver is in any state but C<streaming> (C<waiting>, C<restarting>,
C<stopping>). C<pg_stat_wal_receiver> has its one row only while the receiver
process is alive B<and> has connected to its upstream, so a standby that lost
its primary has no row. This also deactivates a standby that is fed by
C<restore_command> alone: it never starts a WAL receiver, and is replicating by
shipped files, not by a stream this method can see.

=item *

B<A WAL receiver whose state the role may not read counts as streaming.>
Without membership in C<pg_read_all_stats> (which C<pg_monitor> includes) a
role sees the row with its C<pid> and every other column NULL. The row alone
says the receiver is alive and connected; reading the missing state as "not
streaming" would deactivate every replicant of an ordinary application role.
What such a role cannot see is a receiver that is connected but momentarily
C<waiting>, C<restarting> or C<stopping>.

=item *

B<No answer> comes only from a server older than PostgreSQL 10, which lacks
the functions the query uses. The replicant is then managed by hand, as it was
before this method existed.

=back

=head2 lag_behind_master

    my $seconds = $storage->lag_behind_master;

How far the standby's data is behind, in whole seconds -- the unit
L<DBIO::MySQL::Storage> reports, so that C<maximum_lag> of
L<DBIO::Replicated::Pool> means the same on both. Never negative. Answers
nothing when L</is_replicating> is not true: a server that follows no stream
has no lag that means anything, even if it has replayed all it ever received.

=over 4

=item *

B<0 when everything received has been replayed>
(C<pg_last_wal_replay_lsn() E<gt>= pg_last_wal_receive_lsn()>; replay runs
ahead of the stream while WAL comes from the archive). This is what keeps an
idle primary from looking like lag: the time since the last replayed
transaction grows for as long as nothing is written, although nothing is
missing.

=item *

B<Otherwise the age of the last replayed transaction>, C<clock_timestamp() -
pg_last_xact_replay_timestamp()>, cut to whole seconds. C<clock_timestamp()>
because C<now()> stands still inside a transaction. A standby under steady
load is always some milliseconds behind; reading that as 0, as MySQL's whole
seconds do, is what lets the default C<maximum_lag> of 0 keep it active. A
standby whose clock is behind its primary's would give a negative age, which
is reported as 0. The same age is used when the standby has never received
anything by streaming in this run and there is no position to compare.

=item *

B<Nothing when WAL is outstanding and no transaction has been replayed yet> --
a standby just started. There is WAL to apply and no timestamp to date it by,
so no number of seconds exists; the pool leaves such a replicant as it is. The
window closes with the first commit or abort record replayed.

=back

Two things this number cannot see. It is measured against what has B<arrived>
on the standby: WAL the primary has written but not yet sent is not in it, and
a silent link shows as lag only once C<wal_receiver_timeout> has ended the WAL
receiver and L</is_replicating> turns false. And it overstates once: after a
long quiet period the first new WAL arrives while the last replayed
transaction is still the old one, so the age reads as the whole quiet period
until that WAL is applied.

=head2 cake_defaults

Returns PostgreSQL-optimized defaults for L<DBIO::Cake>.
Activated via C<use DBIO::Cake '-Pg'>.

=over 4

=item * C<inflate_jsonb> — on (PostgreSQL standard is jsonb, not json)

=item * C<inflate_datetime> — on

=item * C<retrieve_defaults> — on (PostgreSQL generates UUIDs, serials, NOW(), etc.)

=back

=head1 SEE ALSO

=pod

=over 4

=item * L<DBIO::PostgreSQL> - schema component that activates this storage class

=item * L<DBIO::PostgreSQL::Deploy> - high-level deploy/upgrade orchestration

=item * L<DBIO::PostgreSQL::DDL> - native PostgreSQL DDL generator

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
