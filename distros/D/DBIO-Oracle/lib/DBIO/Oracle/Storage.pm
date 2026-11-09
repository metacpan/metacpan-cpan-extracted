package DBIO::Oracle::Storage;
# ABSTRACT: Oracle Support for DBIO

use strict;
use warnings;

our $VERSION = '0.900004';

# Compose cross-cutting Storage behaviour via ISA (not Exporter import), so the
# role methods live in the MRO and their next::method calls resolve. Roles that
# override a DBIO::Storage::DBI method (LOBSupport::_prep_for_execute,
# Savepoints::_dbh_execute_for_fetch) come BEFORE DBIO::Storage::DBI so the
# override wins and chains forward to the base.
use base qw/
  DBIO::Oracle::Storage::LOBSupport
  DBIO::Oracle::Storage::AutoIncrement
  DBIO::Oracle::Storage::Savepoints
  DBIO::Oracle::Storage::FKDeferral
  DBIO::Oracle::Storage::ConnectSetup
  DBIO::Storage::DBI
/;
use mro 'c3';

__PACKAGE__->register_driver('Oracle' => __PACKAGE__);

use DBIO::Carp;
use Try::Tiny;
use namespace::clean;

__PACKAGE__->sql_quote_char ('"');
__PACKAGE__->sql_maker_class('DBIO::Oracle::SQLMaker');
__PACKAGE__->datetime_parser_type('DateTime::Format::Oracle');

use DBIO::Oracle::Type ();
use DBIO::Oracle::Util ();

sub __cache_queries_with_max_lob_parts { 2 }

sub dbio_deploy_class { 'DBIO::Oracle::Deploy' }

# The attributes of every connection of this driver that the connect_info does
# not name (an attribute it names wins, core merges it over these): LongReadLen
# 16 MiB, so a CLOB or BLOB is read in full instead of dying at DBD::Oracle's
# 80 characters (LongTruncOk stays off: a cut value is an error, never a silent
# one), and AL32UTF8 as the client character sets, so a character is not turned
# into U+FFFD by a client NLS_LANG that is not UTF-8 (karr k63).
sub _default_dbi_connect_attributes () {
  +{
    %{ $_[0]->next::method },
    LongReadLen  => 16 * 1024 * 1024,
    ora_charset  => 'AL32UTF8',
    ora_ncharset => 'AL32UTF8',
  };
}
sub deploy_setup { }


sub _determine_supports_insert_returning {
  my $self = shift;
  # TODO find out which version supports the RETURNING syntax
  # 8i has it and earlier docs are a 404 on oracle.com
  return 1 if $self->_server_info->{normalized_dbms_version} >= 8.001;
  return 0;
}

__PACKAGE__->_use_insert_returning_bound (1);

# F02 / F10 -- transactional DDL. Zero, and here that is the ENGINE's answer
# rather than this driver's preference: on Oracle a DDL statement is not
# something a transaction can contain. The SQL Language Reference states it as
# a property of COMMIT itself -- "Oracle Database issues an implicit COMMIT
# under the following circumstances: * Before any syntactically valid data
# definition language (DDL) statement, even if the statement results in an
# error * After any data definition language (DDL) statement that completes
# without an error" (19c SQL Language Reference, COMMIT) -- and the 2 Day
# Developer's Guide draws the conclusion in one sentence: "Before and after a
# DDL statement, Oracle Database issues an implicit COMMIT statement;
# therefore, you cannot roll back a DDL statement" (19c 2 Day Developer's
# Guide, About Data Definition Language (DDL) Statements).
#
# The load-bearing clause is "even if the statement results in an error": the
# COMMIT in FRONT of a DDL statement is not conditional on that statement
# working. So a $storage->txn_do around DBIO::Deploy::Base::_execute_ddl's
# loop would not merely fail to buy atomicity here -- it would be actively
# misleading. txn_do opens a transaction; the first CREATE TABLE commits it,
# together with whatever the caller had already done inside it; every further
# statement commits on both sides of itself; and the ROLLBACK txn_do issues
# when statement 7 of 12 throws has nothing left to reach. The bracket would
# read as atomicity at the call site and hand back a committed, half-migrated
# schema -- which is strictly worse than core's honest one-time
# "non-transactional DDL" notice.
#
# The very same paragraph of COMMIT is also why this driver's own deploy
# cannot be produced as the counter-example: "This statement also erases all
# savepoints in the transaction and releases transaction locks."
# DBIO::Oracle::Deploy was written to run its test deploy inside a SAVEPOINT
# on the live connection (ADR 0002), and that savepoint does not survive the
# first CREATE TABLE of the deploy it is meant to contain -- which is why its
# diff and upgrade build the desired state in a temporary user instead (karr
# k36, ADR 0010). See DBIO::Oracle::Deploy, "The desired state: a temporary
# user", for that, and "Transactional DDL" for what is left to recover with
# after a half-run apply.
#
# No version gate, and none is possible: the implicit COMMIT on DDL is
# Oracle's behaviour on every release this driver supports, so there is
# nothing for a _determine_supports_transactional_ddl to probe. Declared
# outright rather than left to core's default -- which is also 0 -- because a
# silent storage cannot be told apart from an overlooked one, and the default
# is core's to change.
#
# MEASURED IN PART. That a DDL statement commits the transaction it finds
# open -- also one that fails on the name -- and that a savepoint is gone
# after it, is measured against Oracle Database 23ai Free (23.26.3) in
# t/54-deploy-live.t (1d, 4). NOT measured: a txn_do bracket around the
# deploy loop on a server, and any other release. For those the above is
# documented engine behaviour with its sources named, in the same sense as
# the EXPLAIN PLAN and DBMS_RANDOM work above. Value and
# declaredness, plus the bracket/no-bracket behaviour it drives in core, are
# pinned offline by t/52-deploy-transactional-ddl.t.
__PACKAGE__->_use_transactional_ddl (0);

# ADR 0039 -- does this deployment's Oracle have the "... ALL" set operators?
# Declared 0 outright, which is what keeps the hook below a *static class
# fact*: an undeclared capability falls through to _determine_supports_*, and
# the only honest determination here would read the server version. See the
# refusal in _set_operation_keyword for why that is forbidden rather than
# merely inconvenient -- and note that this is the spot where a future author
# would be tempted to add the probe, so it is nailed shut on both tiers.
__PACKAGE__->mk_group_accessors( dbms_capability     => '_supports_set_operator_all_family' );
__PACKAGE__->mk_group_accessors( use_dbms_capability => '_use_set_operator_all_family' );
__PACKAGE__->_use_set_operator_all_family (0);
sub _determine_supports_set_operator_all_family { 0 }

# ADR 0039 -- the keyword the six DBIO::ResultSet set operations join their
# operands with, and the seam that refuses the two Oracle did not have until
# 21c. Replaces ADR 0037's single-operation _except_operator, which core
# removed; an unported override would simply never have been called again.
#
# Deliberately a static class fact with no version probe: ResultSet's
# _set_operation bakes the keyword into a literal from clause at construction
# time, so a runtime-resolved keyword is not expressible -- and asking the
# server which word to use is exactly the connection-at-query-build-time this
# hook removed.
sub _set_operation_keyword {
  my ($self, $op) = @_;

  # An undefined $op is a core programming error and the base throws for it;
  # it only ever sees one if this override passes it down, and the comparisons
  # below would warn about an uninitialized value first.
  return $self->next::method($op) unless defined $op;

  # MINUS on every release since 8i and still one in 23ai. EXCEPT was only
  # added alongside it in 21c and is a syntax error on everything older, so
  # this answer carries no version gate and needs none.
  return 'MINUS' if $op eq 'except';

  # Before 21c the engine has exactly UNION, UNION ALL, INTERSECT and MINUS
  # (SQL Language Reference, "The Set Operators", 19c); 21c added EXCEPT,
  # EXCEPT ALL, INTERSECT ALL and MINUS ALL. Which of the two we are talking
  # to is not askable here, so the class fact decides it.
  if ($op eq 'except_all' or $op eq 'intersect_all') {

    $self->throw_exception(
      "Oracle has no MINUS ALL / INTERSECT ALL before 21c, so this driver "
    . "refuses \$rs->$op. The refusal holds by default on every version, 21c "
    . "and later included, because _set_operation_keyword must answer as a "
    . "static class fact: DBIO::ResultSet::_set_operation bakes the keyword "
    . "into the query while it is being built, so probing the server version "
    . "here would open a connection during query build -- purely in order to "
    . "throw (ADR 0039 section 7). A deployment that knows it runs 21c or "
    . "newer lifts the refusal with "
    . "DBIO::Oracle::Storage->_use_set_operator_all_family(1), or for a "
    . "single connection with "
    . "\$schema->storage->_use_set_operator_all_family(1)."
    ) unless $self->_use_set_operator_all_family;

    # 21c spells this one both ways. MINUS ALL rather than the equally valid
    # EXCEPT ALL so that except and except_all come out of the same dialect.
    return 'MINUS ALL' if $op eq 'except_all';
  }

  # UNION, UNION ALL, INTERSECT -- and INTERSECT ALL once opted in: Oracle's
  # spelling is the ANSI one, so the base map answers. An unknown $op lands on
  # core's throw there rather than being invented here.
  return $self->next::method($op);
}

# ADR 0037 -- the complete 1/0 statement behind DBIO::ResultSet::results_exist
# and its two siblings. Core's base rendering has no FROM clause at all, and
# Oracle answers a FROM-less SELECT with ORA-00923; DUAL is the one-row table
# that makes it a legal statement here. Only the dummy table is ours -- the
# CASE spelling stays core's, so there is one copy of it.
sub _exists_value_sql {
  my $self = shift;
  return $self->next::method(@_) . ' FROM DUAL';
}

# ... and the capability that lets core call the above at all. Not vacuous
# next to the override: it is this driver asserting that somebody checked the
# rendering against Oracle, which is why the default is 0 and why declaring is
# a separate act from overriding.
__PACKAGE__->_use_supports_exists_query (1);

# karr k22 -- the function DBIO::ResultSet::rand drops into an order_by
# literal. Core answers RANDOM(), which PostgreSQL and SQLite have and Oracle
# does not have at all: the server reports it as an unknown identifier
# (ORA-00904), because there is no such function to resolve the name to.
#
# DBMS_RANDOM.VALUE is the supplied-package function, written WITHOUT
# parentheses: this is its zero-argument overload, and SQL has no empty
# argument list to write for it. A static class fact like the base hook -- no
# $dbh, no version probe.
sub _random_function { 'DBMS_RANDOM.VALUE' }

# karr k22 / ADR 0040 -- the WHOLE operation of obtaining a query plan, which
# on Oracle is two statements and was the reason core widened this seam from
# the string-valued _explain_sql to a method returning rows.
#
# Core's inherited operation is "EXPLAIN <query>", and Oracle has no EXPLAIN
# statement -- it has EXPLAIN PLAN, and the bare form is a syntax error
# (ORA-00900). The spelling is the smaller half: EXPLAIN PLAN FOR does not
# ANSWER with the plan. It writes it into PLAN_TABLE and returns no rows at
# all, so the plan has to be read back by a second statement of this driver's
# own, which core never rendered and knows nothing about.
#
# DBMS_XPLAN.DISPLAY with no arguments reads the most recently explained
# statement out of PLAN_TABLE, which is the one the line above just wrote.
# PLAN_TABLE is session-private (a global temporary table since 10g), so the
# two statements must run on the same connection -- they do, because core
# delegates this whole method rather than the statements inside it, so a
# DBIO::Replicated::Storage picks one replicant for the operation and both land
# on it (DBIO::Replicated::Balancer::_explain_query).
#
# BOTH statements go through _execute_rendered, which ADR 0040 section 3 makes
# a requirement of the contract with no engine-named exceptions -- including
# the second one, which carries no user data but everything else: tracing and
# therefore redact_bind_value (ADR 0025) over the query's own WHERE-clause
# values, dbh_do retry over a dropped connection, NoBindVars interpolation, and
# the read handler rather than the master's on a replicated storage. Reaching
# for $self->dbh here would hand every one of them back, and this driver's
# EXPLAIN PLAN FOR would be the loudest place to lose them: the binds it
# carries are the caller's own.
sub _explain_query {
  my ($self, $sql, $bind) = @_;

  # Writes the plan into PLAN_TABLE and answers nothing. The query's binds
  # travel with it: EXPLAIN PLAN parses the statement, so its placeholders are
  # the statement's own and have to be supplied.
  $self->_execute_rendered("EXPLAIN PLAN FOR $sql", $bind);

  # ... so the plan comes from here. One column, PLAN_TABLE_OUTPUT, one row per
  # line of DBMS_XPLAN's formatted report.
  my (undef, $sth) = $self->_execute_rendered(
    'SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY)', [],
  );

  return $sth->fetchall_arrayref;
}


sub insert {
  my ($self, $source, $to_insert, $opts) = @_;

  return $self->next::method($source, $to_insert, $opts)
    if $to_insert and %$to_insert;

  my $infos = $source->columns_info;
  my ($col) = grep { $infos->{$_}{is_auto_increment} } $source->columns;
  ($col) = $source->columns unless defined $col;
  return $self->next::method($source, $to_insert, $opts) unless defined $col;

  my $returned = $self->next::method($source, { $col => \'DEFAULT' }, $opts);
  delete $returned->{$col}
    if ref $returned->{$col} eq 'SCALAR' and ${ $returned->{$col} } eq 'DEFAULT';
  return $returned;
}


sub _insert_bulk {
  my ($self, $source, $cols, $data, @rest) = @_;

  my $infos = $source->columns_info($cols);
  return $self->next::method($source, $cols, $data, @rest)
    unless grep { defined $infos->{$_}{data_type} and $self->_is_lob_type($infos->{$_}{data_type}) } @$cols;

  my $guard = $self->txn_scope_guard;
  for my $row (@$data) {
    my %values;
    @values{@$cols} = @$row;
    $self->insert($source, \%values, { no_retrieve => 1 });
  }
  $guard->commit;
  return scalar @$data;
}

sub _ping {
  my $self = shift;
  my $dbh = $self->_dbh or return 0;
  local $dbh->{RaiseError} = 1;
  local $dbh->{PrintError} = 0;
  return try {
    $dbh->do('select 1 from dual');
    1;
  } catch { 0 };
}

# A Perl string without the UTF-8 flag is a sequence of Latin-1 code points,
# but DBD::Oracle sends it as bytes: under the client character set AL32UTF8 a
# "\x{fc}" arrives as the invalid byte 0xFC and comes back as U+FFFD (karr k63,
# case bind-non-ascii). The bind is upgraded (utf8::upgrade, on a copy: the
# caller's string is not touched) when its data type is a character type; a
# binary type and a bind without a type are sent as they are.
sub _is_character_data_type {
  my ($self, $data_type) = @_;

  return 0 unless defined $data_type;

  return $data_type =~ /\A \s*
    (?: (?: national \s+ )?
        (?: char (?: acter )? (?: \s+ varying )? | varchar2? | nvarchar2? | nchar (?: \s+ varying )? )
      | text | tinytext | mediumtext | longtext | n?clob | long | string )
    \s* (?: \( [^)]* \) )? \s* \z/xi ? 1 : 0;
}

sub _upgrade_character_bind {
  my ($self, $meta, $value) = @_;

  return $value
    unless defined $value
      and !length ref $value
      and ref $meta eq 'HASH'
      and $self->_is_character_data_type($meta->{sqlt_datatype});

  utf8::upgrade(my $copy = $value);
  return $copy;
}

# The one core seam for a changed value (DBIO::Storage::DBI, _adjust_bind_values):
# statements bound one by one and each row of a void populate run through it.
# The answer is a new list of new pairs; a scalar reference (a bind_param_inout
# target) stays the very same reference, and the caller's list and strings are
# never written to. In a populate row the meta of a literal-bind slot carries
# _literal_bind_subindex; that value is left as it is.
sub _adjust_bind_values {
  my ($self, $sth, $bind, $bind_attrs) = @_;

  return [ map {
    ( ref $_->[0] eq 'HASH' and defined $_->[0]{_literal_bind_subindex} )
      ? [ @$_ ]
      : [ $_->[0], $self->_upgrade_character_bind(@$_[0, 1]) ]
  } @{ $self->next::method($sth, $bind, $bind_attrs) } ];
}


sub _ddl_sql_dialect { 'oracle' }


sub _mask_error_values {
  my ($self, $text, $values, $statement) = @_;

  return $text unless defined $text and !ref $text;

  my $masked = eval { DBIO::Oracle::Util::mask_error_details($text, $values, $statement) };
  $masked = $text unless defined $masked;

  return $self->next::method($masked, $values, $statement);
}

sub _dbh_execute {
  my ($self, $sql, $bind) = @_[0,2,3];

  # Turn off sth caching for multi-part LOBs. See _prep_for_execute below
  local $self->{disable_sth_caching} = 1 if grep {
    ($_->[0]{_ora_lob_autosplit_part}||0) > (__cache_queries_with_max_lob_parts - 1)
  } @$bind;

  my $next = $self->next::can;

  # if we are already in a txn we can't retry anything
  return shift->$next(@_) if $self->transaction_depth;

  local $self->{_in_do_block};

  return DBIO::Storage::BlockRunner->new(
    storage => $self,
    wrap_txn => 0,
    retry_handler => sub {
      if ($_[0]->failed_attempt_count == 1
          and $_[0]->last_exception =~ /ORA-01003/
          and my $dbh = $_[0]->storage->_dbh) {
        delete $dbh->{CachedKids}{$sql};
        return 1;
      }
      return 0;
    },
  )->run($next, @_);
}


sub _connect_params_dsn {
  my ($self, $driver, $params) = @_;

  my ($dbname, $host, $port) = @{$params}{qw(dbname host port)};

  if (defined $host) {
    return "dbi:$driver://$host"
      . ( defined $port   ? ":$port"   : '' )
      . ( defined $dbname ? "/$dbname" : '' );
  }

  $self->throw_exception(
    'Cannot build a DBD::Oracle DSN from the connection parameter port '
  . 'without a host: DBD::Oracle connects to a database the Oracle client '
  . "resolves by name (dbi:$driver:<dbname>) or, with Easy Connect, to a "
  . "service on a host (dbi:$driver://<host>[:<port>][/<dbname>]), and only "
  . 'the second has a place for a port. Beside a name the port would be '
  . 'dropped -- tnsnames.ora or the local instance decides where the '
  . 'connection goes. Give host as well, leave port out, or supply a dsn '
  . 'instead.'
  ) if defined $port;

  return "dbi:$driver:" . ( $dbname // '' );
}


sub _bind_host_into_dsn {
  my ($self, $driver, $dsn, $host, $port) = @_;

  return $self->next::method($driver, $dsn, $host, $port)
    unless defined $dsn and $dsn =~ /^(dbi:Oracle(?:\([^)]*\))?:)(.*)\z/is;
  my ($prefix, $rest) = ($1, $2);

  if ($rest =~ m{^//(.*)\z}s) {
    my $tail = $1;
    my ($authority, $service) = $tail =~ m{^([^/]*)(/.*)?\z}s;
    $service //= '';

    my ($old_host, $old_port);
    if ($authority =~ /^(\[[^\]]+\]|[^:\[\]]+)(?::(\d*))?\z/) {
      ($old_host, $old_port) = ($1, $2);
    }
    else {
      return (undef, 'an Easy Connect DSN whose host part cannot be read');
    }

    $port = $old_port if !defined $port and defined $old_port and length $old_port;
    $host = "[$host]" if $host =~ /:/ and $host !~ /^\[/;

    return $prefix . "//$host" . ( defined $port ? ":$port" : '' ) . $service;
  }

  return (undef, 'a TNS descriptor (several ADDRESS entries make the host ambiguous)')
    if $rest =~ /^\s*\(/;

  return (undef, 'a name the Oracle client resolves (tnsnames.ora alias, SID or TWO_TASK), which names no host in the DSN')
    unless $rest =~ /=/;

  return $self->next::method($driver, $dsn, $host, $port);
}


sub relname_to_table_alias {
  my $self = shift;
  my ($relname, $join_count) = @_;
  my $alias = $self->next::method(@_);
  return $self->sql_maker->_shorten_identifier($alias);
}


# Internal helpers for LOBSupport role (called by the composed subs).
# The LOB-type predicates live in DBIO::Oracle::Type as the single source;
# these thin wrappers preserve the $self->_is_lob_type calling convention.
sub _is_lob_type      { DBIO::Oracle::Type::is_lob_type(@_) }
sub _is_text_lob_type { DBIO::Oracle::Type::is_text_lob_type(@_) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Oracle::Storage - Oracle Support for DBIO

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  # In your result (table) classes
  use base 'DBIO::Core';
  __PACKAGE__->add_columns(id => { sequence => 'mysequence', auto_nextval => 1 });
  __PACKAGE__->set_primary_key('id');

  # Somewhere in your Code
  # add some data to a table with a hierarchical relationship
  $schema->resultset('Person')->create ({
        firstname => 'foo',
        lastname => 'bar',
        children => [
            {
                firstname => 'child1',
                lastname => 'bar',
                children => [
                    {
                        firstname => 'grandchild',
                        lastname => 'bar',
                    }
                ],
            },
            {
                firstname => 'child2',
                lastname => 'bar',
            },
        ],
    });

  # select from the hierarchical relationship
  my $rs = $schema->resultset('Person')->search({},
    {
      'start_with' => { 'firstname' => 'foo', 'lastname' => 'bar' },
      'connect_by' => { 'parentid' => { '-prior' => { -ident => 'personid' } } },
      'order_siblings_by' => { -asc => 'firstname' },
    }
  );

  # this will select the whole tree starting from person "foo bar", creating
  # following query:
  # SELECT
  #     me.personid, me.firstname, me.lastname, me.parentid
  # FROM
  #     person me
  # START WITH
  #     firstname = 'foo' and lastname = 'bar'
  # CONNECT BY
  #     parentid = prior personid
  # ORDER SIBLINGS BY
  #     firstname ASC

=head1 DESCRIPTION

This class implements base Oracle support. The subclass
L<DBIO::Oracle::Storage::WhereJoins> is for C<(+)> joins in Oracle
versions before 9.0; it is not selected automatically, set C<storage_type>
to C<+DBIO::Oracle::Storage::WhereJoins>.

=head2 Date and timestamp formats

Every connection of this driver sets the ISO formats of
C<datetime_setup> (L<DBIO::Oracle::Storage::ConnectSetup>) when it is made:
C<NLS_DATE_FORMAT> C<YYYY-MM-DD HH24:MI:SS>, C<NLS_TIMESTAMP_FORMAT>
C<YYYY-MM-DD HH24:MI:SS.FF> and C<NLS_TIMESTAMP_TZ_FORMAT>
C<YYYY-MM-DD HH24:MI:SS.FF TZHTZM>, so that a C<DATE> and a C<TIMESTAMP> come
back as C<YYYY-MM-DD ...> strings without an C<on_connect_call>. A format
named in the environment variable of the same name is used instead. The
setting is made before the application's own C<on_connect_call> and
C<on_connect_do>, which can change it for their connection;
C<< on_connect_call =E<gt> 'datetime_setup' >> is still accepted and sets the
same formats again.

=head2 LOB length and character set

A connection sets the attributes the C<connect_info> does not name: C<LongReadLen>
is 16 MiB (16*1024*1024), so a C<CLOB> or C<BLOB> is read as a string in full
(DBD::Oracle's own default of 80 makes a longer value an error at the fetch),
and C<ora_charset> and C<ora_ncharset> are C<AL32UTF8>, so the client character
set is UTF-8 whatever C<NLS_LANG> says: a string with a wide character
(the euro sign, Japanese) is sent and read back as it is, where a client without
a UTF-8 C<NLS_LANG> answers C<?>. A Perl string that is not flagged as
characters is a sequence of Latin-1 code points, and DBD::Oracle would send
it as bytes (a one-byte C<"\x{fc}"> is no UTF-8): the storage upgrades such a
bind itself, see L</Strings without the UTF-8 flag>. C<LongTruncOk> stays off: a value longer than C<LongReadLen> is an error,
never silently cut. A value the C<connect_info> names for any of these wins.

=head2 Strings without the UTF-8 flag

DBD::Oracle sends a Perl string without the UTF-8 flag as bytes, so under the
client character set C<AL32UTF8> the Latin-1 string C<"\x{fc}"> would be
stored as U+FFFD. The storage therefore upgrades (C<utf8::upgrade>)
a bind whose column has a character type: C<char>, C<varchar>, C<varchar2>,
C<nchar>, C<nvarchar>, C<nvarchar2>, C<text>, C<clob>, C<nclob>, C<long> (the
C<data_type> the bind carries as C<sqlt_datatype>, the way
C<bind_attribute_by_data_type> decides). The upgrade is made on a copy; the
caller's string is not changed. A binary type (C<blob>, C<raw>, C<long raw>,
C<binary>) and a bind without a data type are sent unchanged, since their
bytes are no characters. This holds for the bulk C<populate> path too.

=head2 Set operations

Oracle spells set difference C<MINUS>, not the ANSI C<EXCEPT> that
L<DBIO::Storage::DBI/_set_operation_keyword> answers with by default, so this
class overrides that hook (ADR 0039, which generalised ADR 0037's
single-operation C<_except_operator> to all six operations) and
L<DBIO::ResultSet/except> gets the right keyword without anyone comparing
driver names. No version gate, and none is possible: C<MINUS> is right on
every release, having been the spelling since Oracle 8i and still being one in
23ai, whereas C<EXCEPT> was only added alongside it in 21c and is a syntax
error on everything older.

The same hook is where this driver B<refuses> the two operations Oracle did
not have until then. Before 21c the engine has exactly C<UNION>,
C<UNION ALL>, C<INTERSECT> and C<MINUS>; 21c added C<EXCEPT>, C<EXCEPT ALL>,
C<INTERSECT ALL> and C<MINUS ALL> (SQL Language Reference, I<The Set
Operators>, 19c and 21c). L<DBIO::ResultSet/except_all> and
L<DBIO::ResultSet/intersect_all> used to emit C<EXCEPT ALL> /
C<INTERSECT ALL> and come back as a syntax error from the server; they now
throw at query-build time, before a single operand is rendered.

The refusal cannot ask which version it is talking to -- the hook is resolved
while the query is being assembled and must not open a connection (ADR 0039
section 7) -- so it reads a class fact instead, and this driver declares the
conservative one. A deployment that knows its server lifts it:

  # this deployment runs Oracle 21c or newer
  DBIO::Oracle::Storage->_use_set_operator_all_family(1);

Reach for the class-level form: it names the class, so it holds from load time
and does not depend on any storage existing yet. The same switch can be set on
a single storage, for a process that talks to more than one server. A schema
declares its driver (core ADR 0067), so its storage is of this class from the
start, and both per-storage forms work on a freshly connected one:

=over 4

=item *

C<< $schema->storage->_use_set_operator_all_family(1) >> -- the per-name
accessor, which this class defines.

=item *

C<< $schema->storage->set_use_dbms_capability('_use_set_operator_all_family', 1) >>
-- the two-argument form underneath every C<_use_> accessor. It is
name-independent: the setter writes the tier-1 slot, and the matching getter,
C<< $schema->storage->get_use_dbms_capability('_use_set_operator_all_family') >>,
reads it.

=back

Both instance forms write the same tier-1 force, and clearing is the same in
either spelling: C<undef> B<removes> the force instead of leaving a tombstone
behind, so an application that sets the switch for one storage and
later turns it back gets this driver's C<0> declaration again.

With the switch set, C<except_all> renders C<MINUS ALL> -- the same dialect as
C<except>, and equivalent to the C<EXCEPT ALL> Oracle also accepts from 21c on
-- and C<intersect_all> inherits core's C<INTERSECT ALL>, which is Oracle's
own spelling. Left alone, both throw with a message naming the version
boundary and this switch. The default is C<0> because the releases this driver
otherwise supports are the ones without the family at all: 11.2 and 19c are
long-term releases, and a default of C<1> would send them SQL the server
rejects, which is the state this replaced.

=head2 Existence queries

L<DBIO::ResultSet/results_exist> and its two siblings work here because this
class declares the C<supports_exists_query> capability (ADR 0037). Core
defaults that capability to C<0> and throws on all three methods without it,
rather than degrading silently to L<DBIO::ResultSet/has_rows> -- which stays
the portable alternative for callers that must also run against a driver
which has not declared it.

Declaring it alone would not be enough: core's base rendering of
L<DBIO::Storage::DBI/_exists_value_sql> is
C<SELECT CASE WHEN EXISTS E<lt>innerE<gt> THEN 1 ELSE 0 END>, a C<SELECT>
with no C<FROM> clause, which Oracle rejects with ORA-00923. The override
appends C<FROM DUAL> and leaves the C<CASE> spelling to core, so the statement
is complete and the boolean arrives as an integer.

=head2 Random ordering

L<DBIO::ResultSet/rand> asks the storage which function this engine spells
"give me a random number" with (L<DBIO::Storage::DBI/_random_function>) and
drops the answer into an C<order_by> literal. Core answers C<RANDOM()>, which
is right on PostgreSQL and SQLite and is not a function Oracle has at all, so
the server reports it as an unknown identifier -- there is nothing for the name
to resolve to. Oracle's is the supplied-package function C<DBMS_RANDOM.VALUE>,
and this class overrides the hook with it.

It is written B<without> parentheses. C<DBMS_RANDOM.VALUE> has a zero-argument
overload and a two-argument one, and SQL has no empty argument list to write
for the first, so C<DBMS_RANDOM.VALUE()> is not the same string with optional
punctuation -- it is a parse error.

Together with the C<rows> that C<rand> adds, C<< $rs->rand(3) >> comes out as
this driver's C<ROWNUM> limit dialect wrapped around an
C<ORDER BY DBMS_RANDOM.VALUE> subquery. That nesting is the point rather than
an artefact: the sort has to happen B<inside> the subquery for the C<ROWNUM>
predicate outside it to pick three random rows instead of three arbitrary ones.

=head2 Query plans

L<DBIO::ResultSet/explain> asks the storage for the B<whole operation> of
obtaining a query plan through L<DBIO::Storage::DBI/_explain_query> (ADR 0040,
which replaced the string-valued C<_explain_sql>). Oracle is the engine that
argument was made for, and this class overrides the hook for two reasons at
once.

The first is spelling: core's inherited operation is
C<EXPLAIN E<lt>queryE<gt>>, and Oracle has no C<EXPLAIN> statement. It has
C<EXPLAIN PLAN>, and the bare form is a syntax error, ORA-00900.

The second is shape, and it is the larger half. C<EXPLAIN PLAN FOR> does not
B<answer> with the plan: it writes the plan into C<PLAN_TABLE> and returns no
rows at all. The plan is read back by a B<second> statement,
C<SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY)>, which with no arguments displays
the most recently explained statement of the session -- the one the first
statement just wrote. No rewriting of a single statement string could have
expressed that, which is why the seam is a method returning rows.

What comes back is C<DBMS_XPLAN>'s formatted report: one column,
C<PLAN_TABLE_OUTPUT>, one row per line, dashed rules and blank lines included.
It is text meant to be read, not a table of plan attributes -- which is no more
than ADR 0040 section 2 already says about every driver's plan rows, whose
I<contents> are engine-specific and which nothing in DBIO normalises.

Both statements go through L<DBIO::Storage::DBI/_execute_rendered>, which the
contract requires without engine-named exceptions. That is what keeps tracing
and therefore L<DBIO::Storage::DBI/redact_bind_value> (ADR 0025) over the
query's own bind values, C<dbh_do> retry over a dropped connection,
L<DBIO::Storage::DBI::NoBindVars> interpolation, and -- on a
L<DBIO::Replicated::Storage> -- the read handler instead of the master's.

=head3 What the session needs, and what happens when it does not have it

C<PLAN_TABLE> has to be visible to the session. Since 10g the database ships
one: C<SYS.PLAN_TABLE$>, a global temporary table with a public synonym
C<PLAN_TABLE>, so a default installation needs no setup at all. Where that
synonym has been dropped, or a schema carries an older private plan table left
over from an earlier release, C<EXPLAIN PLAN FOR> B<fails> -- ORA-02404 for a
missing plan table, ORA-00942 where the name does not resolve, ORA-01031 where
it resolves but the session may not write to it. The exception surfaces from
the first statement and propagates out of C<< $rs->explain >>: this driver does
not swallow it, and there is no degraded mode in which C<explain> answers with
an empty plan. The fix is a plan table of the session's own, created by
F<@?/rdbms/admin/utlxplan.sql>.

Two consequences of C<EXPLAIN PLAN> being a statement that B<writes>. The rows
it inserts are part of the current transaction, so an C<explain> inside one
leaves it non-empty, and a rollback takes those rows with it -- harmless,
because the plan has already been read by then. And because a global temporary
table is session-private, the two statements must run on the same connection.
They do: core delegates the whole C<_explain_query>, not the individual
statements inside it, so a L<DBIO::Replicated::Storage> picks one replicant for
the operation and both statements land on it.

=head3 What of this is verified

The B<seam> is verified against core's source: the hook name and signature,
that C<_explain_sql> is gone rather than deprecated, that
L<DBIO::ResultSet/explain> strips C<as_query>'s parentheses before handing the
statement over, and that C<DBIO::Replicated::Balancer> forwards
C<_explain_query> as a whole (the previous paragraph's claim about one
replicant).

Oracle's half is checked live: the live part of F<t/36-explain-query.t> runs
C<EXPLAIN PLAN>, C<DBMS_XPLAN.DISPLAY> and C<DBMS_RANDOM.VALUE> against
Oracle 23ai Free. No other release has been run. The offline part of the
file pins what this driver puts on the wire and that it goes through the
storage's statement path.

=head1 METHODS

=head2 insert

An insert of no values, C<< $rs->create({}) >>, cannot be written as the
standard C<INSERT INTO t DEFAULT VALUES>: Oracle does not know it (ORA-00926).
It is sent as C<< INSERT INTO t (col) VALUES (DEFAULT) >> for one column -- the
first auto-increment column, else the first column of the source -- which
leaves every column at its default, the named one too. That column is not a
value of the row: it is not in what the insert hands back, unless the server
returned it (a key the sequence and trigger made, read with C<RETURNING>).

=head2 _insert_bulk

C<< $rs->populate >> in void context inserts all rows with one array
execution, which DBD::Oracle does not do for a LOB ("LOBs not supported for
array operation"). A populate that writes a LOB column (C<CLOB>, C<BLOB>, any
type L<DBIO::Oracle::Type/is_lob_type> names) is therefore inserted row by row
with L</insert>, in one transaction; every other populate is core's array
execution.

=head2 _ddl_sql_dialect

Names the SQL dialect the install and upgrade DDL is split under:
C<oracle>, where a PL/SQL unit (a C<CREATE TRIGGER>, a block) is one statement
that keeps the semicolon after its C<END>.

=head2 _mask_error_values

  my $text = $storage->_mask_error_values($text, \@values, $statement);

Oracle 23ai writes the value of a statement into its error text, also when it
was a bind: the first character of a string in ORA-01722, C<invalid string
value> in ORA-03302, the key of the row in ORA-03301, the value of ORA-01438,
ORA-61800 and ORA-01428. The Oracle rules of
L<DBIO::Oracle::Util/mask_error_details> replace each of these values with
C<***> whatever its length, and the code, the type, the column, the
constraint and the table stay. The values bound to the statement are masked
where they appear elsewhere in the text, and the statement the DBD appends to
a message stays whole, literals included.

The Oracle rules run first and the core's masking after them
(C<next::method>): the rules read the key texts of the server as they are,
which the core's masking of a bound value would cut into pieces. Core calls
this wherever engine text reaches an exception (ADR 0075). The method never
connects and never throws.

=head2 _connect_params_dsn

The DSN seam of L<DBIO::Storage::DBI/_connect_params_dsn> (ADR 0057),
overridden because L<DBD::Oracle> takes nothing of core's default form
C<dbi:Oracle:dbname=...;host=...;port=...>. What follows C<dbi:Oracle:> is a
database identifier, and a C<;> in it switches DBD::Oracle to its keyed form
(C<host=...;sid=...;port=...>), which has no C<dbname> key and refuses the
default outright. The identifier has two shapes that C<dbname>, C<host> and
C<port> can fill, and which one the connection parameters mean is decided by
C<host>:

=over

=item * B<by name> -- no C<host>

  dbi:Oracle:<dbname>

C<dbname> is a name the Oracle client resolves, and what it means is the
client's to say: a net service name from F<tnsnames.ora> first, and a name
that file does not define is read as an Easy Connect string
(C<host[:port][/service_name]>). The SID of an instance on the same machine
is the third meaning the DBD::Oracle documentation gives. A name that is none
of them does not connect (ORA-12154). Without C<dbname> the identifier is
empty, C<dbi:Oracle:>, and the client takes the database from C<TWO_TASK> or,
for a local instance, C<ORACLE_SID>; with neither set that does not connect
either (ORA-12162).

=item * B<Easy Connect> -- with C<host>

  dbi:Oracle://<host>[:<port>][/<dbname>]

naming the server itself, no F<tnsnames.ora> involved. Here C<dbname> is the
B<service name>, not a SID: that is what the last part of an Easy Connect
identifier is (C<//host[:port][/service_name]> in the DBD::Oracle
documentation), and it is the meaning that reaches every database -- a
pluggable database is addressed by service name only. The keyed form would
have carried the same three parts as C<host=...;sid=...;port=...>, and would
have pinned C<dbname> to the SID.

=back

A part not given is left out; nothing is put into the DSN that the parameters
do not say:

=over

=item * C<host> without C<port> gives C<//E<lt>hostE<gt>/E<lt>dbnameE<gt>>, no
port. There is a documented default -- "If port name is not specified, 1521 is
the default" -- and it is the Oracle client's to apply, so it is not written
into the DSN here.

=item * C<host> without C<dbname> gives C<//E<lt>hostE<gt>[:E<lt>portE<gt>]>.
DBD::Oracle documents the service name as optional ("If service name is not
specified, the hostname will be used as a service name"). What the client was
seen to send is an empty service name, not the host name; which service a
listener hands to a connection that names none is the server side's business,
and none is made up here. It need not be the database the user is in: a
listener in front of a container database answered a user of its pluggable
database with ORA-01017, the error of a wrong password.

=back

One combination refuses, the error naming the ways out:

=over

=item * C<port> without C<host>. A name the client resolves has no place for a
port -- F<tnsnames.ora> or the local instance holds it. Dropping the one given
would connect to wherever they say, silently.

=back

C<host> goes into the DSN as given. An IPv6 literal therefore has to be given
in brackets (C<< host => '[2001:db8::1]' >>): the Oracle client does not parse
one without them, and they are not added here.

Anything these three parts cannot say -- a SID on a named host, a full TNS
descriptor, a TCPS address -- goes in as the whole DSN: as C<dsn>, or as a
C<dbname> that starts with C<dbi:Oracle:> (L<DBIO::AccessBroker::Static>
passes it on), which core takes as the DSN before this seam is asked.

L<DBIO::Oracle::Storage::WhereJoins> inherits this method and builds the same
DSN.

B<Verified against a server> in F<t/38-connect-params-live.t>, with Oracle
Database 23ai Free, DBD::Oracle 1.95 and Instant Client 23: a listener hands
out a session in the service named for C<//host:port/service>; without a port
the client goes to 1521; a bracketed IPv6 host is taken as the address and an
unbracketed one is not; C<dbi:Oracle:E<lt>dbnameE<gt>> resolves through
F<tnsnames.ora>; a reconnect follows a host the broker changed. Two things
were not: the SID of a local instance (the test machine has none), and a
listener that itself answers on port 1521 or over IPv6 -- for both a relay on
the test machine stood in front of the real listener, so what is shown is
where the client goes. That DBD::Oracle refuses core's default form is
observed offline (F<t/37-connect-params-dsn.t>).

=head2 _bind_host_into_dsn

The host seam of L<DBIO::Storage::DBI/_bind_host_into_dsn> (core ADR 0013,
addendum 2026-10-09): what a L<DBIO::AccessBroker::HostBound> view
(a replicant of L<DBIO::Replicated>) does with a DSN in the answer it wraps.
Core's default knows the C<host=>/C<port=> key form only and declines the
Easy Connect and TNS forms DBD::Oracle users write. This storage translates
what has one unambiguous host and declines the rest:

=over

=item * B<Easy Connect>, C<dbi:Oracle://host[:port][/service]>: the view's host
replaces the answer's, the service stays. The view's port replaces the port;
a view without a port keeps the answer's, and when neither has one none is
written (the client's default 1521 is its to apply). An IPv6 host is written
in brackets, as the Oracle client needs it. C<dbi:Oracle(attr):> prefixes are
kept.

=item * the B<key form>, C<dbi:Oracle:host=...;sid=...;port=...>: bound by core's
default, as before.

=item * B<refused>, naming the form and never the DSN: a name the Oracle client
resolves (C<dbi:Oracle:E<lt>aliasE<gt>>, or empty) -- a F<tnsnames.ora> alias
or a local SID has no host in the DSN, the client decides where it goes; a
TNS descriptor (C<(DESCRIPTION=...>) -- it may hold several C<ADDRESS>
entries, and which one the host replaces is ambiguous; and an Easy Connect
whose host part cannot be read.

=back

Offline pinned in F<t/69-hostbound-dsn.t>; L<DBIO::Oracle::Storage::WhereJoins>
inherits it.

=head2 relname_to_table_alias

L<DBIO> uses L<DBIO::Relationship> names as table aliases in queries.

Unfortunately, Oracle doesn't support identifiers over 30 chars in length, so
the L<DBIO::Relationship> name is shortened and appended with half of an
MD5 hash.

See L<DBIO::Storage::DBI/relname_to_table_alias>.

=head2 connect_by or connect_by_nocycle

=over 4

=item Value: \%connect_by

=back

A hashref of conditions used to specify the relationship between parent rows
and child rows of the hierarchy.

  connect_by => { parentid => { -prior => { -ident => 'personid' } } }

  # adds a connect by statement to the query:
  # SELECT
  #     me.personid, me.firstname, me.lastname, me.parentid
  # FROM
  #     person me
  # CONNECT BY
  #     parentid = PRIOR personid


  connect_by_nocycle => { parentid => { -prior => { -ident => 'personid' } } }

  # adds a connect by statement to the query:
  # SELECT
  #     me.personid, me.firstname, me.lastname, me.parentid
  # FROM
  #     person me
  # CONNECT BY NOCYCLE
  #     parentid = PRIOR personid

=head2 start_with

=over 4

=item Value: \%condition

=back

A hashref of conditions which specify the root row(s) of the hierarchy.

It uses the same syntax as L<DBIO::ResultSet/search>

  start_with => { firstname => 'Foo', lastname => 'Bar' }

  # SELECT
  #     me.persionid me.firstname, me.lastname, me.parentid
  # FROM
  #     person me
  # START WITH
  #     firstname = 'foo' and lastname = 'bar'
  # CONNECT BY
  #     parentid = prior persionid

=head2 order_siblings_by

=over 4

=item Value: ($order_siblings_by | \@order_siblings_by)

=back

Which column(s) to order the siblings by.

It uses the same syntax as L<DBIO::ResultSet/order_by>

  'order_siblings_by' => 'firstname ASC'

  # SELECT
  #     me.persionid me.firstname, me.lastname, me.parentid
  # FROM
  #     person me
  # CONNECT BY
  #     parentid = prior persionid
  # ORDER SIBLINGS BY
  #     firstname ASC

=head1 ATTRIBUTES

Following additional attributes can be used in resultsets.

=head1 SEE ALSO

=over

=item * L<DBIO::Oracle> - Oracle schema component

=item * L<DBIO::Oracle::SQLMaker> - Oracle SQL dialect

=item * L<DBIO::Oracle::Storage::WhereJoins> - WHERE-clause join support for Oracle E<lt> 9

=item * L<DBIO::Storage::DBI> - Base DBI storage class

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
