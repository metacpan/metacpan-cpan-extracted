package DBIO::Sybase::Storage::ASE;
# ABSTRACT: Sybase ASE SQL Server support for DBIO

use strict;
use warnings;

our $VERSION = '0.900004';

# The ASE::* trait classes below are standalone (no parent) and override
# methods that also exist in the deep DBIO::Storage::DBI hierarchy reached
# via DBIO::Sybase::Storage (e.g. last_insert_id, _execute, _insert_bulk,
# _exec_txn_begin). They MUST be listed before DBIO::Sybase::Storage so the
# C3 linearisation places them ahead of DBIO::Storage::DBI; otherwise their
# overrides are shadowed by core and never run (the trait methods chain into
# core via next::method).
use base qw/
  DBIO::Sybase::Storage::ASE::LOBWriter
  DBIO::Sybase::Storage::ASE::BulkInsert
  DBIO::Sybase::Storage::ASE::IdentityRetrieval
  DBIO::Sybase::Storage::ASE::TxnManager
  DBIO::Sybase::Storage
  DBIO::Storage::DBI::AutoCast
  DBIO::Storage::DBI::IdentityInsert
/;
use mro 'c3';
use DBIO::Carp;
use Scalar::Util qw/blessed weaken/;
use List::Util 'first';
use Sub::Util ();
use Try::Tiny;
use Scope::Guard ();
use Context::Preserve 'preserve_context';
use DBIO::Util 'sigwarn_silencer';
use DBIO::Sybase::Util ();
use version ();
use namespace::clean;


__PACKAGE__->sql_maker_class('DBIO::Sybase::SQLMaker');
__PACKAGE__->sql_quote_char ([qw/[ ]/]);
__PACKAGE__->datetime_parser_type(
  'DBIO::Sybase::Storage::ASE::DateTime::Format'
);

__PACKAGE__->mk_group_accessors('simple' =>
    qw/_identity _identity_method _blob_log_on_update _parent_storage
       _writer_storage _is_writer_storage
       _bulk_storage _is_bulk_storage _began_bulk_work
    /
);

# ADR 0037. The base rendering of DBIO::Storage::DBI::_exists_value_sql --
#
#   SELECT CASE WHEN EXISTS <inner> THEN 1 ELSE 0 END
#
# -- is grammatical Transact-SQL on ASE exactly as core writes it, so this
# driver declares the capability and deliberately does NOT override the hook.
# The declaration means somebody read the grammar, so here is what was read
# (SAP ASE 16.0 SP04 manuals), in the three places the fragment could break:
#
#   * no FROM. Reference Manual: Commands, "select": the production is
#     "select [all | distinct] [top <n>] <select_list> [<into_clause>]
#     [<partition_clause>] [<from_clause>] ..." -- <from_clause> is optional,
#     so ASE needs none of the dummy tables Oracle (DUAL), DB2
#     (SYSIBM.SYSDUMMY1) and Firebird (RDB$DATABASE) do. The manual writes
#     FROM-less selects itself, e.g. "select 1 intersect (select 2 intersect
#     select 3)" under "Using intersect and except".
#   * CASE in the select list. Reference Manual: Building Blocks, 3.15 "case":
#     "can be used anywhere a value expression can be used", searched form
#     "case when <search_condition> then <expression> [...] [else
#     <expression>] end".
#   * EXISTS as that <search_condition>. Reference Manual: Commands lists
#     "where [not] exists (<subquery>)" among the search conditions, and the
#     case entry defines its <search_condition> as "similar to the search
#     conditions in a where clause". What ASE documents nowhere is EXISTS as a
#     *value* expression -- the bare "SELECT EXISTS (...)" core emitted before
#     ADR 0037 is a PostgreSQL-ism with no ASE grammar behind it.
#
# Declared here and not on DBIO::Sybase::Storage on purpose: that class is the
# base shared with DBIO::MSSQL::Storage::Sybase, which
# talks DBD::Sybase to Microsoft SQL Server. See the note above
# _set_operation_keyword below.
__PACKAGE__->_use_supports_exists_query(1);

# F02 / F10 -- transactional DDL. Answered 0, but NOT for the reason the
# family's shared prose gives for this engine: ASE does not force an implicit
# COMMIT on DDL the way Oracle and MySQL do. It refuses the statement.
#
# Whether a create table may sit inside a transaction at all is a per-DATABASE
# server option, off by default (SAP ASE 16.1, Transact-SQL Users Guide,
# document version 1.0 / 2026-03-30, 23.3.1 "Allow Data Definition Commands in
# Transactions"): "You can use certain data definition language commands, such
# as create table, grant, and alter table, in transactions by setting the ddl
# in tran database option to true", set with sp_dboption <db>,"ddl in tran",
# true followed by checkpoint, from master, by a system administrator or the
# database owner only. A database created while model had it false has it
# false. With it false the statement does not half-commit -- the server
# rejects it, naming the database it rejected it in (msg 2762, "The '%s'
# command is not allowed within a multi-statement transaction in the '%.*s'
# database"). The same manual states the rule in passing for another command:
# "you cannot issue alter precomputed result set as part of a multistatement
# transaction (unless you set the ddl in tran option to true for the
# database)". t/22-ase-bulk-freetds.t records the same shape of refusal from
# another corner of the engine -- msg 226, "BULK INSERT not allowed within
# multi-statement transaction".
#
# That inverts the usual cost of getting this capability wrong, and is why it
# is worth declaring rather than inheriting. On an implicit-COMMIT engine a
# mistaken 1 buys nothing and loses nothing: txn_do brackets a loop that
# commits anyway. Here a mistaken 1 makes DBIO::Deploy::Base::_execute_ddl
# open a transaction (our txn_do -> begin_work -> CHAINED, see TxnManager)
# around DDL the server will then throw out, turning a working
# statement-at-a-time apply into a hard failure -- on the DEFAULT
# configuration of every ASE. So the 0 is not the conservative shrug core's
# default would be; it is the only answer that is true on every server this
# driver can be pointed at.
#
# The honest answer is "it depends on the server", and that is precisely what
# a capability cannot say. This one is a class-level fact, fixed before any
# connection, and DBIO::Deploy::Base reads it once per batch. A runtime probe
# is expressible in principle -- _determine_supports_transactional_ddl runs on
# a connected instance and could read ddl in tran out of sp_helpdb -- and is
# still not wanted: the answer is cached per $dbh while the deploy path spans
# two databases with independent settings (the live one and the temp one
# DBIO::Sybase::Deploy creates, whose setting comes from model), and it would
# make bracketing depend on server configuration nobody deploying this driver
# was asked about. SAP's own advice runs the same way: "Use data definition
# commands with caution. The only scenario in which using data definition
# language commands inside transactions is justified is in create schema."
#
# Two things this reasoning does NOT rest on, so that nobody re-derives them
# as support:
#   * The CREATE DATABASE / DROP DATABASE of the temp-database deploy path
#     (ADR 0005) are in the manual's always-forbidden list, banned even with
#     ddl in tran true -- but they never reach _execute_ddl. Deploy's
#     _create_temp_db / _drop_temp_db call $dbh->do directly and
#     need a handle with AutoCommit for exactly that reason (they refuse one
#     without, karr k96), independent of this capability.
#     Nor does the DDL deployed INTO the temp database reach a bracket: core
#     skips it because the handle belongs to no storage.
#   * The diff emits no select into and no truncate table, the other two
#     entries of that list a schema tool might plausibly produce.
# What the live apply path does emit -- create table, drop table, create
# index, drop index, alter table add/modify/replace/drop, alter table add/drop
# constraint -- sits in the manual's ddl-in-tran list, except that alter table
# appears in its prose and not in its enumeration, while the only alter table
# forms it forbids outright are ...partition and ...unpartition. That gap is
# the source's, not ours, and it is one more thing a 1 would have to bet on.
#
# Read, not measured: all of the above comes from the manual and from SAP's
# message texts. This repo's offline suite never touches a server and no live
# run was made to watch msg 2762 arrive, so treat the error numbers as
# citations rather than as something observed here.
#
# Declared here and not on DBIO::Sybase::Storage for the reason spelled out
# above _use_supports_exists_query, which bites harder here: that base
# is first in the C3 linearisation of DBIO::MSSQL::Storage::Sybase, ahead of
# DBIO::MSSQL::Storage, so a 0 on it would both state something false about
# Microsoft SQL Server (whose DDL is transactional) and pre-empt dbio-mssql's
# own declaration if it ever makes one. The base stays silent; value,
# declaredness and that silence are pinned by t/42-deploy-transactional-ddl.t.
__PACKAGE__->_use_transactional_ddl(0);

# ADR 0039 -- does this deployment's ASE have intersect and except at all?
#
# Unlike every other gap in this family the ASE version boundary runs the
# other way round: the operators are NEW (16.0 SP03, 2019), so the servers
# that lack them are the OLD ones. dbio-oracle's equivalent flag defaults to 0
# because MINUS ALL exists only on 21c and refusing protects the majority;
# here a default of 0 would take intersect and except away from every server
# SAP still supports in order to protect legacy installs, which is the
# regression ADR 0039 section 3 lists as a reason against gating at all. So
# this is section 7 option (b) with the polarity the engine fact dictates: an
# opt-OUT a deployment sets when it knows its server predates 16.0 SP03 (or is
# a Cluster Edition, which SAP note 2687392 reports as lacking them in every
# version). Declared outright on both tiers, exactly like dbio-oracle's, so
# that the hook stays a static class fact: the only honest _determine_supports_*
# here would read the server version, and this is the spot a future author
# would be tempted to add that probe.
__PACKAGE__->mk_group_accessors( dbms_capability     => '_supports_intersect_except' );
__PACKAGE__->mk_group_accessors( use_dbms_capability => '_use_intersect_except' );
__PACKAGE__->_use_intersect_except (1);
sub _determine_supports_intersect_except { 1 }

# ADR 0039 -- the keyword the six DBIO::ResultSet set operations join their
# operands with, and the seam that refuses the ones ASE does not have.
#
# The engine facts, read rather than assumed (SAP ASE 16.0 SP04 Reference
# Manual: Commands unless noted):
#
#   * union has an ALL form. The "union operator" entry gives
#     "union [all]" with all as a documented parameter: "includes all rows in
#     the results; duplicates are not removed".
#   * intersect and except do NOT. "Using intersect and except" gives both
#     productions with no all anywhere in them, describes intersect as
#     "Duplicate rows are eliminated from the result set", and its own worked
#     example subtracts t2 = (1,6,6,6,7,7,7,7) from t1 = (2,6,1,1) and returns
#     the single row 2 -- the duplicate 1s collapse, so there is no ALL
#     semantics to reach. The strings "except all", "intersect all" and
#     "minus all" do not occur anywhere in that manual.
#   * except is spelled except. ASE takes minus as an interchangeable synonym
#     ("the parameter name except is used throughout the documentation for the
#     sake of simplicity"), so core's ANSI base map already answers correctly
#     and this driver has no spelling to contribute -- only refusals.
#   * intersect and except are NEW in 16.0 SP03: SAP ASE 16.0 SP03 What's New,
#     chapter 15 "Version 16.0 SP03", section 15.5.1 "intersect and except
#     Parameters". SAP note 2687392 ("Error 156 when trying to use EXCEPT /
#     MINUS set operator - ASE") gives the other side of the boundary: "all
#     versions prior to 16.0 SP03", plus ASE Cluster Edition in all versions.
#
# Hence two different kinds of refusal in one hook. except_all / intersect_all
# are refused UNCONDITIONALLY because the fact is unconditional -- no ASE has
# ever had them, so nothing is being withheld from a version that works.
# except / intersect are refused only where the class fact above says this
# server is too old, because on 16.0 SP03 and newer they work and taking them
# away would be the section 7 cost with none of the section 7 benefit.
#
# Static class fact throughout, with no version probe: ResultSet's
# _set_operation bakes the keyword into a literal from clause at construction
# time, so a runtime-resolved keyword is not expressible -- and asking the
# server which word it wants is exactly the connection-at-query-build-time
# this hook's predecessor removed.
#
# Lives on ::ASE and not on DBIO::Sybase::Storage for the reason spelled out
# above _use_supports_exists_query: the base is shared with
# DBIO::MSSQL::Storage::Sybase, which linearises it AHEAD of
# DBIO::MSSQL::Storage under c3, so an override there would shadow the MSSQL
# refusal with an ASE answer about Microsoft SQL Server.
sub _set_operation_keyword {
  my ($self, $op) = @_;

  return $self->next::method($op) unless defined $op;

  if ($op eq 'except_all' or $op eq 'intersect_all') {
    (my $distinct_form = $op) =~ s/_all\z//;

    $self->throw_exception(
      "Sybase ASE has no $op: its intersect and except operators always "
    . 'return distinct rows and take no ALL, while union on the same engine '
    . 'is documented as "union [all]". This refusal is unconditional and is '
    . 'not a version compromise -- ASE gained intersect and except in 16.0 '
    . 'SP03 and neither has ever had an ALL form; "except all", "intersect '
    . 'all" and "minus all" occur nowhere in the SAP ASE 16.0 SP04 Reference '
    . 'Manual: Commands. The nearest available operation is '
    . "->$distinct_form(), but it is not a substitute: it collapses duplicate "
    . 'rows, so it answers a different question.'
    );
  }

  if ($op eq 'except' or $op eq 'intersect') {
    $self->throw_exception(
      "Sybase ASE gained $op only in version 16.0 SP03; older releases answer "
    . 'it with "Incorrect syntax near the keyword" (SAP note 2687392, which '
    . 'also reports ASE Cluster Edition as lacking it in every version). This '
    . 'deployment has declared its server one of those, with '
    . 'DBIO::Sybase::Storage::ASE->_use_intersect_except(0), so the operation '
    . 'is refused while the query is built rather than by the server. On 16.0 '
    . 'SP03 or newer, drop that declaration -- it defaults to 1. The hook '
    . 'cannot decide this for you: DBIO::ResultSet::_set_operation bakes the '
    . 'keyword into the query at construction time, so probing the server '
    . 'version here would open a connection during query build, purely in '
    . 'order to throw (ADR 0039 section 7).'
    ) unless $self->_use_intersect_except;
  }

  # union, union all -- and intersect / except once the server is new enough.
  # ASE spells all four the ANSI way, so the base map answers and an unknown
  # $op lands on core's throw there rather than being invented here.
  return $self->next::method($op);
}

# karr k28 -- the function DBIO::ResultSet::rand drops into an order_by
# literal. Core answers RANDOM(), which ASE simply does not have: the SAP ASE
# 16.0 "Transact-SQL Functions" list carries rand and newid and no random at
# all, so the inherited default dies naming the function the server could not
# find.
#
# The obvious replacement is the WRONG one, and that is this ticket's finding.
# rand() exists, but it is not computed per row -- the reference entry for its
# sibling rand2 defines itself by exactly that contrast, "Unlike rand, it is
# computed for each returned row when it is used in the select list", with the
# worked example "If there are n rows in table t, the following select
# statement returns n different random values, not just one: select rand2()
# from t". So ORDER BY rand() hands every row the SAME sort key: the ordering
# is not random, and nothing says so. That is a silent wrong answer, strictly
# worse than the loud RANDOM() it would replace. rand2() has the per-row
# behaviour and is documented out of this position instead -- "The behavior of
# rand2 in places other than the select list is currently undefined" -- and an
# order_by is such a place.
#
# newid() is the one whose own entry carries the per-row guarantee: "By
# default newid returns new values for every filtered row." It yields a
# 32-byte human-readable GUID (varchar, no dashes) by default, so ordering by
# it shuffles.
#
# That DBIO::MSSQL::Storage answers NEWID() too is a coincidence of two
# independently documented engine facts, not shared Transact-SQL heritage, and
# it does NOT license moving this declaration up a level. It lives on ::ASE
# for the reason spelled out above _use_supports_exists_query: the shared
# shared base DBIO::Sybase::Storage is linearised AHEAD of
# DBIO::MSSQL::Storage by DBIO::MSSQL::Storage::Sybase under c3, so a
# declaration there would answer for Microsoft SQL Server out of this
# distribution. dbio-mssql's t/56-explain-query.t asserts that from its side.
sub _random_function { 'NEWID()' }

# karr k28 / ADR 0040 section 7: ASE emits its plan as server MESSAGES, not as
# a rowset -- the channel DBD::Sybase exposes only through syb_err_handler --
# so _explain_query collects them through the _execute_sth seam core karr k140
# built. Both overrides live HERE, on ::ASE, and not on DBIO::Sybase::Storage:
# ASE spells the setting "set showplan on" where Microsoft SQL Server spells it
# SET SHOWPLAN_ALL ON, so a declaration on the shared base would break
# dbio-mssql's DBD::Sybase path.
#
# The handler is installed on the handle the statement runs on -- the one
# _dbh_execute received, never $self->dbh -- so tracing/redact_bind_value
# (ADR 0025), dbh_do retry and the read handler of a replicated storage all
# survive. It fires only for the showplan message numbers (3612-3615, 6201-6299,
# 10201-10299, per DBD::Sybase's own worked example) and returns 0 for them --
# showplan output is not an error. Everything else is chained to the handler
# the borrow displaced: the slot is taken for the duration of the statement,
# but a caller's own syb_err_handler (PRINT/dbcc output processing) must keep
# seeing its messages and keep its verdict while the borrow lasts -- (karr k34;
# the restore pattern is core karr k153 / ADR 0040 section 7). The restore is a
# Scope::Guard: if execute throws, the handler must not outlive the statement it
# was installed for, or a caller's own syb_err_handler would be lost and a stale
# closure left on the handle.
sub _execute_sth {
  my ($self, $dbh, $sth) = @_;

  my @messages;
  my $old = $dbh->{syb_err_handler};
  $dbh->{syb_err_handler} = sub {
    my ($err, $sev, $state, $line, $server, $proc, $msg) = @_;
    if ($err >= 3612 && $err <= 3615
        || $err >= 6201 && $err <= 6299
        || $err >= 10201 && $err <= 10299) {
      push @messages, $msg;
      return 0;   # showplan output is not an error
    }
    return $old ? $old->(@_) : 1;   # everything else: the prior handler's verdict
  };
  my $restore = Scope::Guard->new(sub { $dbh->{syb_err_handler} = $old });

  # The client library tells a conversion it could not do with a warn(), not
  # an error (cs_convert failed (to_money(x))), and the text holds the value.
  # The warning goes on to the handler it displaced, with the value masked;
  # every other warning passes unchanged.
  my $previous = $SIG{__WARN__};
  local $SIG{__WARN__} = sub {
    my $text = $_[0];
    if (defined $text and !ref $text and $text =~ /\bcs_convert failed \(/) {
      my $values = eval { $self->_warned_values($sth) } || [];
      my $tail = $text =~ s/(\s+at \S+ line \d+\.?\n?)\z// ? $1 : '';
      $text = $self->_mask_error_values($text, $values) . $tail;
    }
    ref $previous eq 'CODE' ? $previous->($text, @_[1..$#_]) : warn $text;
  };

  my $rv = $sth->execute;

  return ($rv, \@messages);
}

# The plain values bound to a running statement, as the handle knows them.
sub _warned_values {
  my ($self, $sth) = @_;
  my $params = $sth->{ParamValues};
  return [] unless ref $params eq 'HASH';
  return [ grep { defined and !ref } values %$params ];
}


sub _mask_error_values {
  my ($self, $text, $values, $statement) = @_;

  return $text unless defined $text and !ref $text;

  my $masked = eval { DBIO::Sybase::Util::mask_error_details($text, $values) };
  return $self->next::method(defined $masked ? $masked : $text, $values, $statement);
}

# The whole operation of obtaining a plan, per SAP "Using set showplan with
# noexec": the plain form prints the plan AND runs the query, so noexec has to
# bracket it -- five statements in all. The plan arrives as server messages,
# read back from _server_messages right after the query statement (each execute
# overwrites it with that statement's own messages), and wrapped as a
# single-column rowset -- the shape _explain_query's contract names. The two
# OFF statements run from a Scope::Guard, created only after both ONs
# succeeded: if the query throws, an unguarded OFF is skipped and the session
# is left with showplan on -- every later query on that connection returns a
# plan instead of its rows, and with noexec still on, does not even run.
sub _explain_query {
  my ($self, $sql, $bind) = @_;

  $self->_execute_rendered('set showplan on', []);
  $self->_execute_rendered('set noexec on', []);

  my $restore = Scope::Guard->new(sub {
    $self->_execute_rendered('set noexec off', []);
    $self->_execute_rendered('set showplan off', []);
  });

  $self->_execute_rendered($sql, $bind);
  my $messages = $self->_server_messages;

  return [ map { [ $_ ] } @$messages ];
}


my @also_proxy_to_extra_storages = qw/
  connect_call_set_auto_cast auto_cast connect_call_blob_setup
  connect_call_datetime_setup

  disconnect _connect_info _sql_maker _sql_maker_opts disable_sth_caching
  auto_savepoint unsafe cursor_class debug debugobj schema
/;


# The one decision this class takes about itself, for a declared storage and a
# storage pinned to this class (DBIO::Sybase::Storage::_adapt_to_access_path).
# It asks the client library, through the handle, and is taken once: a storage
# that is the NoBindVars class has been through it.
sub _adapt_to_placeholder_support {
  my $self = shift;

  my $no_bind_vars = __PACKAGE__ . '::NoBindVars';

  return if $self->isa($no_bind_vars);

  if ($self->_using_freetds) {
    carp_once <<'EOF' unless $ENV{DBIO_SYBASE_FREETDS_NOWARN};

You are using FreeTDS with Sybase.

We will do our best to support this configuration, but please consider this
support experimental.

TEXT/IMAGE columns will definitely not work.

You are encouraged to recompile DBD::Sybase with the Sybase Open Client libraries
instead.

See perldoc DBIO::Sybase::Storage::ASE for more details.

To turn off this warning set the DBIO_SYBASE_FREETDS_NOWARN environment
variable.
EOF

    if (not $self->_use_typeless_placeholders) {
      if ($self->_use_placeholders) {
        $self->auto_cast(1);
      }
      else {
        $self->ensure_class_loaded($no_bind_vars);
        bless $self, $no_bind_vars;
      }
    }
  }

  elsif (not $self->_get_dbh->{syb_dynamic_supported}) {
    # not necessarily FreeTDS, but no placeholders nevertheless
    $self->ensure_class_loaded($no_bind_vars);
    bless $self, $no_bind_vars;
  }
  # this is highly unlikely, but we check just in case
  elsif (not $self->_use_typeless_placeholders) {
    $self->auto_cast(1);
  }
}

sub _init {
  my $self = shift;

  $self->next::method(@_);

  if (my $ver = $self->_using_freetds && $self->_using_freetds_version) {
    # Only the historic FreeTDS 0.8x line has the known statement-caching bug;
    # parse as a dotted version so 1.x is not coerced to a number (and no
    # "isn't numeric" warning is emitted).
    if (version->parse("v$ver") <= version->parse('v0.82')) {
      carp_once(
        "Buggy FreeTDS version $ver detected, statement caching will not work and "
      . 'will be disabled.'
      );
      $self->disable_sth_caching(1);
    }
  }

  $self->_set_max_connect(256);

# create storage for insert/(update blob) transactions,
# unless this is that storage
  return if $self->_parent_storage;

  my $writer_storage = (ref $self)->new;

  $writer_storage->_is_writer_storage(1); # just info
  $writer_storage->connect_info($self->connect_info);
  $writer_storage->auto_cast($self->auto_cast);

  weaken ($writer_storage->{_parent_storage} = $self);
  $self->_writer_storage($writer_storage);

# create a bulk storage unless connect_info is a coderef
  return if ref($self->_dbi_connect_info->[0]) eq 'CODE';

# FreeTDS' blk-library cannot do BCP ("Type '7' not implemented", and BULK
# INSERT is rejected inside the multi-statement txn DBD::Sybase keeps open).
# Without a bulk storage the _insert_bulk eligibility check falls back to
# regular array inserts, which is the only thing that works under FreeTDS.
  return if $self->_using_freetds;

  my $bulk_storage = (ref $self)->new;

  $bulk_storage->_is_bulk_storage(1); # for special ->disconnect acrobatics
  $bulk_storage->connect_info($self->connect_info);

# this is why
  $bulk_storage->_dbi_connect_info->[0] .= ';bulkLogin=1';

  weaken ($bulk_storage->{_parent_storage} = $self);
  $self->_bulk_storage($bulk_storage);
}

for my $method (@also_proxy_to_extra_storages) {
  no strict 'refs';
  no warnings 'redefine';

  my $replaced = __PACKAGE__->can($method);

  *{$method} = Sub::Util::set_subname $method => sub {
    my $self = shift;
    # class invocant (e.g. core connect_info's ref($self)->cursor_class):
    # there are no extra storages to proxy to (karr k45)
    return $self->$replaced(@_) unless ref $self;
    $self->_writer_storage->$replaced(@_) if $self->_writer_storage;
    $self->_bulk_storage->$replaced(@_)   if $self->_bulk_storage;
    return $self->$replaced(@_);
  };
}

sub disconnect {
  my $self = shift;

# Even though we call $sth->finish for uses off the bulk API, there's still an
# "active statement" warning on disconnect, which we throw away here.
# This is due to the bug described in _insert_bulk.
# Currently a noop because 'prepare' is used instead of 'prepare_cached'.
  local $SIG{__WARN__} = sigwarn_silencer(qr/active statement/i)
    if $self->_is_bulk_storage;

# so that next transaction gets a dbh
  $self->_began_bulk_work(0) if $self->_is_bulk_storage;

  $self->next::method;
}

# This is only invoked for FreeTDS drivers by ::Storage::DBI::Sybase::FreeTDS
sub _set_autocommit_stmt {
  my ($self, $on) = @_;

  return 'SET CHAINED ' . ($on ? 'OFF' : 'ON');
}

# Set up session settings for Sybase databases for the connection.
#
# Make sure we have CHAINED mode turned on if AutoCommit is off in non-FreeTDS
# DBD::Sybase (since we don't know how DBD::Sybase was compiled.) If however
# we're using FreeTDS, CHAINED mode turns on an implicit transaction which we
# only want when AutoCommit is off.
sub _run_connection_actions {
  my $self = shift;

  # ASE cuts a string that is too long without a word: a char(10) takes 11
  # characters, varchar(5) turns 'abcdefgh' into 'abcde'. With this option the
  # statement is refused instead (Msg 9502, "string data right truncated").
  # Set on every connection, the first one, a reconnect, the writer storage's
  # and the bulk storage's (karr k97, the maintainer's decision: silent cutting
  # is never wanted). A change of behaviour for every user of the driver.
  $self->_dbh->do('set string_rtruncation on');

  if ($self->_is_bulk_storage) {
    # this should be cleared on every reconnect
    $self->_began_bulk_work(0);
    return;
  }

  $self->_dbh->{syb_chained_txn} = 1
    unless $self->_using_freetds;

  $self->next::method(@_);
}


sub connect_call_blob_setup {
  my $self = shift;
  my %args = @_;
  my $dbh = $self->_dbh;
  $dbh->{syb_binary_images} = 1;

  $self->_blob_log_on_update($args{log_on_update})
    if exists $args{log_on_update};
}

sub _is_lob_column {
  my ($self, $source, $column) = @_;

  return $self->_is_lob_type($source->column_info($column)->{data_type});
}

# Over FreeTDS a string with a character beyond ASCII does not arrive in a
# character column: the client library cannot convert it to the character set
# of the server, says so AFTER the statement was executed (Open Client Msg 97
# / 98), and the row holds a blank where the value was (measured, FreeTDS
# 1.3.17, U+00FC, U+20AC and U+65E5, varchar and univarchar). So it is refused
# before anything is sent (karr k97), as dbio-mssql refuses it over
# DBD::Sybase (its karr k49). Not for NULL, not for a binary column (its bytes
# are no characters), and not where the client library is not FreeTDS: nothing
# was measured there. What is told is table and column, never the value.
our $BINARY_TYPE_RE = my $BINARY_TYPE = qr/\A(?:(?:var)?binary|image|blob|bytea|bit)\b/i;

sub _refuse_non_ascii_binds {
  my ($self, $ident, $bind) = @_;
  # the cheap test first: asking the client library needs a connection
  return unless grep { defined $_->[1] and not ref $_->[1] and $_->[1] =~ /[^\x00-\x7F]/ }
    @{ $bind || [] };
  return unless $self->_using_freetds;

  my $position = 0;
  for my $item (@{ $bind || [] }) {
    $position++;
    my ($attrs, $value) = @$item;
    next unless defined $value and not ref $value;
    next unless $value =~ /[^\x00-\x7F]/;
    next if ref $attrs eq 'HASH' and ($attrs->{sqlt_datatype} // '') =~ $BINARY_TYPE;
    $self->_throw_non_ascii(
      $self->_table_name_of($ident),
      ref $attrs eq 'HASH' ? $attrs->{dbic_colname} : undef,
      $position,
    );
  }
}

# The table a statement is about, for a message: a source's name, or the first
# table of a FROM (`[ { me => 'doc' } ]`); undef when it is neither.
sub _table_name_of {
  my ($self, $ident) = @_;
  if (blessed $ident and $ident->can('name')) {
    my $name = $ident->name;
    return ref $name ? undef : $name;
  }
  if (ref $ident eq 'ARRAY') {
    my ($first) = @$ident;
    $first = (first { blessed $_ } values %$first) // (values %$first)[0] if ref $first eq 'HASH';
    return $self->_table_name_of($first) if blessed $first;
    return (defined $first and !ref $first) ? $first : undef;
  }
  return undef;
}

sub _throw_non_ascii {
  my ($self, $table, $column, $position) = @_;
  DBIO::Exception->throw(sprintf
    'DBIO::Sybase: %s has a character beyond ASCII and is refused: over FreeTDS '
    . "the client library cannot convert it to the server's character set, says "
    . 'so after the statement has run, and the row then holds a blank in place '
    . 'of the value. Nothing was sent. Use a DBD::Sybase built against the Sybase '
    . 'Open Client libraries with the client character set set, or keep to ASCII',
    defined $column
      ? sprintf('table %s, column %s: the value', $table // '(statement)', $column)
      : sprintf('table %s, bind value %d: the value', $table // '(statement)', $position),
  );
}

sub _prep_for_execute {
  my ($self, $op, $ident, $args) = @_;

  my $limit;  # extract and use shortcut on limit without offset
  if ($op eq 'select' and ! $args->[4] and $limit = $args->[3]) {
    $args = [ @$args ];
    $args->[3] = undef;
  }

  my ($sql, $bind) = $self->next::method($op, $ident, $args);

  $self->_refuse_non_ascii_binds($ident, $bind);

  # $limit is already sanitized by now
  $sql = join( "\n",
    "SET ROWCOUNT $limit",
    $sql,
    "SET ROWCOUNT 0",
  ) if $limit;

  if (my $identity_col = $self->_perform_autoinc_retrieval) {
    $sql .= "\n" . $self->_fetch_identity_sql($ident, $identity_col)
  }

  return ($sql, $bind);
}

# Stolen from SQLT, with some modifications. This is a makeshift
# solution before a sane type-mapping library is available, thus
# the 'our' for easy overrides.
our %TYPE_MAPPING  = (
    number    => 'numeric',
    money     => 'money',
    varchar   => 'varchar',
    varchar2  => 'varchar',
    timestamp => 'datetime',
    text      => 'varchar',
    real      => 'double precision',
    comment   => 'text',
    bit       => 'bit',
    tinyint   => 'smallint',
    float     => 'double precision',
    serial    => 'numeric',
    bigserial => 'numeric',
    boolean   => 'varchar',
    long      => 'varchar',
);

sub _native_data_type {
  my ($self, $type) = @_;

  $type = lc $type;
  $type =~ s/\s* identity//x;

  return uc($TYPE_MAPPING{$type} || $type);
}

# handles TEXT/IMAGE and transaction for last_insert_id
sub insert {
  my $self = shift;

  # the writer storage is made by _init, at the first connect (karr k67)
  $self->_get_dbh;

  my ($source, $to_insert) = @_;

  # The hash is the caller's: the placeholders and DEFAULTs below go into a
  # copy of it (karr k83). Scalar ref values are literal SQL and are not cloned.
  $to_insert = { %$to_insert };

  my $columns_info = $source->columns_info;

  my $identity_col =
    (first { $columns_info->{$_}{is_auto_increment} }
      keys %$columns_info )
    || '';

  # FIXME - this is duplication from DBI.pm. When refactored towards
  # the LobWriter this can be folded back where it belongs.
  local $self->{_autoinc_supplied_for_op} = exists $to_insert->{$identity_col}
    ? 1
    : 0
  ;
  local $self->{_perform_autoinc_retrieval} =
    ($identity_col and ! exists $to_insert->{$identity_col})
      ? $identity_col
      : undef
  ;

  # check for empty insert
  # INSERT INTO foo DEFAULT VALUES -- does not work with Sybase
  # try to insert explicit 'DEFAULT's instead (except for identity, timestamp
  # and computed columns)
  my %defaulted;
  if (not %$to_insert) {
    for my $col ($source->columns) {
      next if $col eq $identity_col;

      my $info = $source->column_info($col);

      next if ref $info->{default_value} eq 'SCALAR'
        || (exists $info->{data_type} && (not defined $info->{data_type}));

      next if $info->{data_type} && $info->{data_type} =~ /^timestamp\z/i;

      $to_insert->{$col} = \'DEFAULT';
      $defaulted{$col} = 1;
    }
  }

  # What stands in the TEXT/IMAGE columns before _remove_blob_cols puts its
  # placeholders there. Core's insert returns the columns as it is handed
  # them, and DBIO::Row keeps what is returned: _insert puts these back, or a
  # row object holds the placeholder, a SCALAR ref, until it is read again
  # (karr k79).
  my %lob_values =
    map { $_ => $to_insert->{$_} }
    grep { !$defaulted{$_} && $self->_is_lob_column($source, $_) }
    keys %$to_insert;

  my $blob_cols = $self->_remove_blob_cols($source, $to_insert);

  # do we need the horrific SELECT MAX(COL) hack?
  my $need_dumb_last_insert_id = (
    $self->_perform_autoinc_retrieval
      &&
    ($self->_identity_method||'') ne '@@IDENTITY'
  );

  my $next = $self->next::can;

  # we are already in a transaction, or there are no blobs
  # and we don't need the PK - just (try to) do it
  if ($self->{transaction_depth}
        || (!$blob_cols && !$need_dumb_last_insert_id)
  ) {
    return $self->_insert (
      $next, $source, $to_insert, $blob_cols, $identity_col, \%lob_values,
      \%defaulted
    );
  }

  # otherwise use the _writer_storage to do the insert+transaction on another
  # connection
  my $guard = $self->_writer_storage->txn_scope_guard;

  my $updated_cols = $self->_writer_storage->_insert (
    $next, $source, $to_insert, $blob_cols, $identity_col, \%lob_values,
    \%defaulted
  );

  $self->_identity($self->_writer_storage->_identity);

  $guard->commit;

  return $updated_cols;
}

sub _insert {
  my ($self, $next, $source, $to_insert, $blob_cols, $identity_col, $lob_values, $defaulted) = @_;

  my $updated_cols = $self->$next ($source, $to_insert);

  my $final_row = {
    ($identity_col ?
      ($identity_col => $self->last_insert_id($source, $identity_col)) : ()),
    %$to_insert,
    %$updated_cols,
  };

  $self->_insert_blobs ($source, $blob_cols, $final_row) if $blob_cols;

  # the values of the TEXT/IMAGE columns, not their placeholders: see insert
  @{$updated_cols}{ keys %$lob_values } = values %$lob_values;

  # The DEFAULT literals insert wrote for an empty insert are not values of the
  # row: the object holds the primary key and reads the rest on demand, as
  # after create({}) on every other driver (karr k84).
  delete @{$updated_cols}{ keys %{ $defaulted || {} } };

  return $updated_cols;
}

sub update {
  my $self = shift;

  # the writer storage is made by _init, at the first connect (karr k67)
  $self->_get_dbh;

  my ($source, $fields, $where, @rest) = @_;

  # The hash is the caller's: _remove_blob_cols and the delete below work on a
  # copy, which is also what next::method gets (karr k83).
  $fields = { %$fields };
  @_ = ($source, $fields, $where, @rest);

  #
  # When *updating* identities, ASE requires SET IDENTITY_UPDATE called
  #
  if (my $blob_cols = $self->_remove_blob_cols($source, $fields)) {

    # If there are any blobs in $where, Sybase will return a descriptive error
    # message.
    # XXX blobs can still be used with a LIKE query, and this should be handled.

    # update+blob update(s) done atomically on separate connection
    $self = $self->_writer_storage;

    my $guard = $self->txn_scope_guard;

    # First update the blob columns to be updated to '' (taken from $fields, where
    # it is originally put by _remove_blob_cols .)
    my %blobs_to_empty = map { ($_ => delete $fields->{$_}) } keys %$blob_cols;

    # We can't only update NULL blobs, because blobs cannot be in the WHERE clause.
    # Its row count is the one to return when no other column is left to set:
    # $where hit that many rows, and the content write below is aimed at the
    # same rows with the same $where, so it has no count of its own (it returns
    # none). DBIO::Row::update takes a false count for "row not found" (k82).
    my $rv = $self->next::method($source, \%blobs_to_empty, $where, @rest);

    # Now update the blobs before the other columns in case the update of other
    # columns makes the search condition invalid.
    $self->_update_blobs($source, $blob_cols, $where);

    if (keys %$fields) {

      # Now set the identity update flags for the actual update
      local $self->{_autoinc_supplied_for_op} = grep
        { $_->{is_auto_increment} }
        values %{ $source->columns_info([ keys %$fields ]) }
      ;

      my $next = $self->next::can;
      my $args = \@_;
      return preserve_context {
        $self->$next(@$args);
      } after => sub { $guard->commit };
    }
    else {
      $guard->commit;
      return $rv;
    }
  }
  else {
    # Set the identity update flags for the actual update
    local $self->{_autoinc_supplied_for_op} = grep
      { $_->{is_auto_increment} }
      values %{ $source->columns_info([ keys %$fields ]) }
    ;

    return $self->next::method(@_);
  }
}


sub connect_call_datetime_setup {
  my $self = shift;
  my $dbh = $self->_get_dbh;

  if ($dbh->can('syb_date_fmt')) {
    # amazingly, this works with FreeTDS
    $dbh->syb_date_fmt('ISO_strict');
  }
  else {
    carp_once
      'Your DBD::Sybase is too old to support '
     .'DBIO::InflateColumn::DateTime, please upgrade!';

    $dbh->do('SET DATEFORMAT mdy');
  }
}


package DBIO::Sybase::Storage::ASE::DateTime::Format;

use base 'DBIO::Storage::DateTimeFormat';

# No preferred_format_class: DateTime::Format::Sybase expects mdy in both
# directions, but connect_call_datetime_setup configures ISO_strict output.
__PACKAGE__->datetime_parse_pattern('%Y-%m-%dT%H:%M:%S.%3NZ');
__PACKAGE__->datetime_format_pattern('%m/%d/%Y %H:%M:%S.%3N');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Sybase::Storage::ASE - Sybase ASE SQL Server support for DBIO

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

    # Recommended connect_info settings for Sybase ASE:
    on_connect_call => [['datetime_setup'], ['blob_setup', log_on_update => 0]]

=head1 DESCRIPTION

Storage driver for Sybase ASE (Adaptive Server Enterprise) databases via
L<DBD::Sybase>.

A schema that declares the driver (the L<DBIO::Sybase> component or the
C<-syb> shortcut) moves its storage here at the first use, without asking the
server what it is (L<DBIO::Sybase::Storage/_adapt_to_access_path>). The
decision about placeholders follows: if your combination of L<DBD::Sybase>
and client library does not support placeholders, the storage is reblessed to
C<DBIO::Sybase::Storage::ASE::NoBindVars>, and if it supports them only with a
type, C<auto_cast> is turned on. A storage pinned to this class by hand
(C<storage_type>) takes that decision too, at its first use and on the same
connection (L<DBIO::Sybase::Storage/_adapt_to_access_path>); it ends
in the class, and has the C<auto_cast>, the declared base has on that
connection. One pinned to a subclass of this class is left as it is.

FreeTDS connections are supported but TEXT/IMAGE columns will not work; use
the native Sybase OpenClient libraries for full functionality.

Autoincrement retrieval is done via C<SELECT MAX(col)> inside a locked
transaction, as Sybase ASE provides no single-statement equivalent of
C<SCOPE_IDENTITY()>. TEXT/IMAGE (blob) columns require a separate write
operation on a dedicated connection and are handled transparently.

Bulk inserts use the L<DBD::Sybase> bulk API when available.

=head1 METHODS

=head2 _mask_error_values

  my $text = $storage->_mask_error_values($text, \@values, $statement);

The seam of L<DBIO::Storage::DBI/_mask_error_values>, for the texts ASE and its
client library write. L<DBIO::Sybase::Util/mask_error_details> replaces the
value in the sentences that quote one (conversion, duplicate key, C<cs_convert>)
and every bound value of four characters or more found elsewhere in the text;
then core takes out the bound values it knows. The message number, type,
column, constraint, table and the C<with N bind values> of the exception stay.
Text that is C<undef> or a reference is returned as it is, and the method never
throws.

It is declared on this class and so serves the NoBindVars class, the FreeTDS
class, the writer storage and the bulk storage as well. The base
L<DBIO::Sybase::Storage> does not have it: that class is shared with
L<DBIO::MSSQL::Storage::Sybase>, whose server writes other sentences.

The warning of the client library for a conversion it could not do
(C<cs_convert failed (to_money(x))>) is no error and carries no
C<errstr>; C<_execute_sth> hands it on to the C<__WARN__> handler of the caller
masked the same way. The C<errstr> of the handle stays as the engine wrote it.

=head2 connect_call_blob_setup

Used as:

  on_connect_call => [ [ 'blob_setup', log_on_update => 0 ] ]

Does C<< $dbh->{syb_binary_images} = 1; >> to return C<IMAGE> data as raw binary
instead of as a hex string.

Recommended.

Also sets the C<log_on_update> value for blob write operations. The default is
C<1>, but C<0> is better if your database is configured for it.

See
L<DBD::Sybase/Handling IMAGE/TEXT data with syb_ct_get_data()/syb_ct_send_data()>.

=head2 connect_call_datetime_setup

Used as:

  on_connect_call => 'datetime_setup'

In L<connect_info|DBIO::Storage::DBI/connect_info> to set:

  $dbh->syb_date_fmt('ISO_strict'); # output fmt: 2004-08-21T14:36:48.080Z

Only a L<DBD::Sybase> too old to have C<syb_date_fmt> gets, with a warning,

  $dbh->do('SET DATEFORMAT mdy');   # input fmt:  08/13/1979 18:08:55.080

instead; the output format is then not set.

This works for both C<DATETIME> and C<SMALLDATETIME> columns, note that
C<SMALLDATETIME> columns only have minute precision.

=head1 EXISTS QUERIES

This storage declares the C<supports_exists_query> capability (ADR 0037), so
L<DBIO::ResultSet/results_exist>, L<DBIO::ResultSet/results_exist_async> and
L<DBIO::ResultSet/results_exist_as_query> are available on Sybase ASE. It does
B<not> override L<DBIO::Storage::DBI/_exists_value_sql>: core's base rendering,
C<SELECT CASE WHEN EXISTS E<lt>innerE<gt> THEN 1 ELSE 0 END>, is grammatical
ASE Transact-SQL as written -- a C<FROM>-less C<select> is legal (the
C<from_clause> is optional in ASE's C<select> production), C<case> "can be used
anywhere a value expression can be used", and C<exists (E<lt>subqueryE<gt>)> is
one of the search conditions its C<when> accepts. What ASE does not document is
C<EXISTS> as a bare value expression, which is what core emitted before ADR
0037.

The declaration lives on this class rather than on
L<DBIO::Sybase::Storage> because that class is only the shared base:
L<DBIO::MSSQL::Storage::Sybase> inherits from it too, and reaches
Microsoft SQL Server rather than ASE, so an ASE engine fact declared there
would be an answer about the wrong engine. See L</SET OPERATIONS>.

Note that reaching this class at all costs a connection: the storage
connects to learn the client library and whether the connection takes
placeholders (L<DBIO::Sybase::Storage/_adapt_to_access_path>); the server is
not asked what it is. So C<< $rs->results_exist_as_query >> connects on this
driver even though ADR 0037 removed core's own connect-at-query-build-time. That is
this driver's own dispatch cost, not core's. Only a storage pinned to this
class by hand is here without one.

=head1 SET OPERATIONS

Of L<DBIO::ResultSet>'s six set operations, Sybase ASE has four:
L<union|DBIO::ResultSet/union>, L<union_all|DBIO::ResultSet/union_all>,
L<intersect|DBIO::ResultSet/intersect> and L<except|DBIO::ResultSet/except>,
all spelled the ANSI way and inherited from core unchanged. (ASE accepts
C<minus> as an interchangeable synonym for C<except>, so there is no spelling
for this driver to contribute -- only refusals.)

L<intersect_all|DBIO::ResultSet/intersect_all> and
L<except_all|DBIO::ResultSet/except_all> B<throw> (ADR 0039). ASE's C<intersect>
and C<except> always return distinct rows and take no C<ALL>, while C<union> on
the same engine is documented as C<union [all]>. That refusal is unconditional,
because the gap is: no ASE release has ever had an C<ALL> form of either.
C<< $rs->intersect >> and C<< $rs->except >> are the nearest available
operations, but they are not substitutes -- they collapse duplicate rows, which
is a different question.

=head2 Servers older than 16.0 SP03

C<intersect> and C<except> are B<new in ASE 16.0 SP03>. Every older release
answers them with C<Incorrect syntax near the keyword ...>, and SAP note
2687392 reports ASE Cluster Edition as lacking them in every version.

L<DBIO::Storage::DBI/_set_operation_keyword> must answer as a static class
fact -- L<DBIO::ResultSet> bakes the keyword into the query while it is being
built, so probing the server version there would open a connection during
query build, purely in order to throw. This driver therefore B<assumes 16.0
SP03 or newer> and offers a class-level opt-out for deployments that know
better:

  # somewhere in your application setup, for an ASE older than 16.0 SP03
  DBIO::Sybase::Storage::ASE->_use_intersect_except(0);

  # or for a single connection
  $schema->storage->_use_intersect_except(0);

With that set, C<< $rs->intersect >> and C<< $rs->except >> throw while the
query is being built, with a message naming the version boundary, instead of
reaching the server and coming back as a syntax error. Left at its default of
C<1>, this driver behaves exactly as it always has.

The default deliberately points the other way from L<DBIO::Oracle::Storage>'s
comparable flag, because the ASE version boundary does: Oracle's missing
operators exist only on its B<newest> releases, ASE's missing operators are
missing only on its B<oldest> ones.

The keyword is resolved before any operand SQL is assembled, so a refused
operation throws while the query is being built and never yields a fragment
that could be embedded in a larger query.

=head1 RANDOM ORDERING

L<DBIO::ResultSet/rand> drops L<DBIO::Storage::DBI/_random_function> into an
C<order_by> literal. This storage answers C<NEWID()>.

Core's inherited C<RANDOM()> is not a function Sybase ASE has -- the SAP ASE
16.0 I<Transact-SQL Functions> list carries C<rand> and C<newid> and no
C<random> at all -- so C<< $rs->rand >> died on the inherited default, loudly,
naming the function the server could not find.

The obvious replacement is the wrong one, which is what this driver has to
record. ASE's C<rand> is B<not computed per row>: the reference entry for its
sibling C<rand2> defines itself by exactly that contrast -- "Unlike C<rand>,
it is computed for each returned row when it is used in the B<select> list" --
and gives the worked example "If there are I<n> rows in table C<t>, the
following select statement returns I<n> different random values, not just one:
C<select rand2() from t>". So C<ORDER BY rand()> hands every row the same sort
key, the ordering is not random, and nothing anywhere says so: a silent wrong
answer, strictly worse than the loud C<RANDOM()> it would replace. C<rand2()>
has the per-row behaviour and is documented out of this position instead --
"The behavior of C<rand2> in places other than the B<select> list is currently
undefined" -- and an C<ORDER BY> is such a place.

C<newid()> is the function whose own entry carries the per-row guarantee: "By
default C<newid> returns new values for every filtered row." It yields a
32-byte human-readable GUID (C<varchar>, no dashes) by default, so ordering by
it shuffles.

That L<DBIO::MSSQL::Storage> answers C<NEWID()> too is a coincidence of two
independently documented engine facts rather than shared Transact-SQL
heritage. The declaration still lives on this class rather than on
L<DBIO::Sybase::Storage>, for the reason given under L</EXISTS QUERIES>.

C<< $rs->rand($n)->as_query >> throws here, for a reason that has nothing to
do with the function: ASE paginates through the C<GenericSubQ> limit dialect,
which refuses an C<ORDER BY> that is not over a column of the main source. The
executed path does not go that way -- C<_prep_for_execute> lifts a
rows-without-offset limit out of the query and wraps it in C<SET ROWCOUNT>
instead -- so C<< $rs->rand($n)->all >> works, and emits C<ORDER BY NEWID()>
between the two C<SET ROWCOUNT> lines.

B<What is verified.> The four function facts above are quoted from the SAP ASE
16.0 I<Reference Manual: Building Blocks> entries for C<rand>, C<rand2> and
C<newid>, and from its I<Transact-SQL Functions> list. B<No live ASE was run.>
What that leaves unchecked is the I<quality> of the shuffle: that C<newid()>
produces a new value per row is documented, but whether a lexicographic sort
over the leading bytes of an ASE GUID is well distributed is not.

=head1 QUERY PLANS

L<DBIO::ResultSet/explain> works on Sybase ASE through the server-message seam
core's ADR 0040 section 7 defines: this storage overrides
L<DBIO::Storage::DBI/_explain_query> and L<DBIO::Storage::DBI/_execute_sth>.
Obtaining a plan on ASE is a session setting, as it is on Microsoft SQL
Server, but it is neither the same setting nor the same shape.

=over

=item * B<The spelling differs, and so do the semantics.>

ASE has C<set showplan on>, not C<SET SHOWPLAN_ALL ON>, and it does not
suppress execution. SAP's own "Using C<set showplan> with C<noexec>" says the
plain form "prints the query plan but also executes the queries, which might
be time consuming", and that "if you include B<set noexec>, you can view the
query plan without running the query". So the operation is five statements
rather than three: the explained query has to be bracketed by C<set noexec on>
/ C<set noexec off> as well.

=item * B<The plan is not a result set.>

ASE emits showplan as server B<messages> -- the same channel Transact-SQL
C<print> and C<dbcc> output travel on -- and L<DBD::Sybase> surfaces them only
through its C<syb_err_handler> callback, documented there as "useful for
handling PRINT statements in Transact-SQL, for handling messages from the
Backup Server, showplan output, dbcc output", with a worked example that traps
the showplan message numbers 3612-3615, 6201-6299 and 10201-10299. Nothing
reaches C<< $sth->fetchall_arrayref >>, so C<_explain_query> collects the
messages through the L<DBIO::Storage::DBI/_execute_sth> seam instead: the
handler is installed on the handle the statement runs on, the query executes,
and the messages are read back from L<DBIO::Storage::DBI/_server_messages> and
wrapped as a single-column rowset.

=back

The handler is installed on the handle the statement runs on -- the one
C<_dbh_execute> received, never C<< $self->dbh >> -- so tracing and therefore
L<DBIO::Storage::DBI/redact_bind_value> (ADR 0025), C<dbh_do>'s reconnect
retry, and the read handler of a L<DBIO::Replicated::Storage> all survive. It
fires only for the showplan message numbers and returns 0 for them (showplan
output is not an error); every other message is chained to the handler the
borrow displaced, so a caller's own C<syb_err_handler> (Transact-SQL C<print>
and C<dbcc> output processing) keeps seeing its messages and keeps its verdict
while the slot is taken (the restore pattern is ADR 0040 section 7). The two
OFF statements run from a L<Scope::Guard>, created only after both ONs
succeeded: if the explained query throws, an unguarded OFF is skipped and the
session is left with showplan on -- every later query on that connection
returns a plan instead of its rows, and with noexec still on, does not even
run.

B<No live ASE was run.> The facts above are quoted from SAP's
C<set showplan> / C<noexec> page and from L<DBD::Sybase>'s own POD. What is
unverified is whether ASE 15+'s XML plan routes (C<set plan for
show_exec_xml>, C<show_final_plan_xml>, C<showplan_in_xml()>) answer with a
rowset rather than with messages; if one of them does, this section is wrong
and the driver should switch to the rowset route.

=head1 SEE ALSO

=over

=item * L<DBIO::Sybase> - Sybase schema component

=item * L<DBIO::Sybase::Storage> - Sybase base storage

=item * L<DBIO::Sybase::Storage::FreeTDS> - FreeTDS connection layer

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
