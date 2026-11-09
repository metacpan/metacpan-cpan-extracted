package DBIO::Deploy::Base;
# ABSTRACT: Base class for DBIO driver deploy orchestrators

use strict;
use warnings;

our $VERSION = '0.900004';

our $CONTRACT_VERSION = '1.3';

# Loaded without importing: importing _split_statements would leak it into
# this package's method-resolution namespace (t/55namespaces_cleaned.t).
# We deliberately do NOT use DBIO::Carp either -- its `import` installs
# carp/carp_once/carp_unique into our namespace and triggers the same
# namespace leak. The F02 informational warning is fired via a local
# one-time closure below.
use DBIO::SQL::Util ();
use Scalar::Util ();
use DBIO::Exception;



sub contract_version { $CONTRACT_VERSION }

sub new {
  my ($class, %args) = @_;
  return bless { %args }, $class;
}


sub schema { $_[0]->{schema} }


sub add_drop_table { $_[0]->{add_drop_table} }


sub allow_destructive {
  if (@_ > 1) {
    $_[0]->{allow_destructive} = $_[1] ? 1 : 0;
    return $_[0];
  }
  return $_[0]->{allow_destructive};
}


sub deploy_args {
  my ($class, $sqltargs) = @_;
  return () unless defined $sqltargs;
  DBIO::Exception->throw(
    "The options of deploy must be a hash reference, got '" . (ref($sqltargs) || $sqltargs) . "'"
  ) unless ref $sqltargs eq 'HASH';

  my %args;
  for my $key (sort keys %$sqltargs) {
    if ($key eq 'add_drop_table') {
      $args{add_drop_table} = $sqltargs->{$key} ? 1 : 0;
    }
    elsif ($key eq 'version') {
      DBIO::Exception->throw(
        "deploy option 'version' is not supported: the native install always "
      . "installs the current state of the schema, a version cannot be selected"
      );
    }
    else {
      DBIO::Exception->throw(
        "Unknown deploy option '$key' (known: add_drop_table)"
      );
    }
  }
  return %args;
}


sub _ddl_quote_ident {
  my ($self, $name) = @_;
  my $storage = $self->_driver_storage;
  return $storage->_ddl_quote_ident($name)
    if $storage && $storage->can('_ddl_quote_ident');
  return DBIO::SQL::Util::_quote_ident($name);
}

sub _dbh { $_[0]->schema->storage->dbh }


sub _driver_storage {
  my ($self) = @_;
  my $storage = eval { $self->schema->storage } || return undef;
  return DBIO::Deploy::Base::driver_storage($storage);
}


sub driver_storage {
  my ($storage) = @_;
  return $storage
    unless Scalar::Util::blessed($storage) and $storage->isa('DBIO::Replicated::Storage');
  return $storage->master->storage;
}

# --- abstract hooks: the driver's helper classes -----------------------------


sub _ddl_class { die ref(shift) . '::_ddl_class not implemented' }


sub _introspect_class { die ref(shift) . '::_introspect_class not implemented' }


sub _diff_class { die ref(shift) . '::_diff_class not implemented' }

# --- overridable factories / glue --------------------------------------------


sub _new_introspect {
  my ($self, $dbh) = @_;
  return $self->_introspect_class->new(dbh => $dbh);
}


sub _introspect_current {
  my ($self) = @_;
  return $self->_new_introspect($self->_dbh)->model;
}


sub _install_ddl {
  my ($self) = @_;
  return $self->_ddl_class->install_ddl($self->schema);
}


sub _execute_ddl {
  my ($self, $dbh, $sql) = @_;
  my $storage = $self->_driver_storage;

  my @stmts = _split_ddl($storage, $sql);
  return 1 unless @stmts;

  my $use_txn = $storage && $storage->can('_use_transactional_ddl')
    ? $storage->_use_transactional_ddl
    : 0;

  if ($use_txn and _storage_owns_dbh($storage, $dbh)) {
    my @runs = _group_ddl_statements($storage, \@stmts);

    if (@runs > 1) {
      my $class = ref($self) || $self;
      my $loose = scalar grep { !$_->[0] } @runs;
      DBIO::Deploy::Base::_warn_split_ddl_once(
        $class,
        "$class -- $loose statement(s) cannot run inside a transaction, so the "
      . "batch was split into " . scalar(@runs) . " runs and is not atomic as a "
      . "whole; recovery depends on the driver's version-row gate"
      );
    }

    for my $run (@runs) {
      my ($transactional, @group) = @$run;

      if ($transactional) {
        $storage->txn_do(sub {
          $dbh->do($_) for @group;
        });
      }
      else {
        $dbh->do($_) for @group;
      }
    }
  }
  elsif ($use_txn) {
    # Transactional engine, but a handle the storage does not own: run the
    # loop bare and say nothing. See _storage_owns_dbh for why bracketing here
    # would be worse than not bracketing, and why this case gets no warning.
    $dbh->do($_) for @stmts;
  }
  else {
    my $class = ref($self) || $self;
    DBIO::Deploy::Base::_warn_non_txn_ddl_once("$class -- DDL loop is not atomic; recovery depends on the driver's version-row gate");
    $dbh->do($_) for @stmts;
  }
  return 1;
}

# The capability is one boolean for the connection, but atomicity is decided
# per statement: some engines have DDL that may not be inside a transaction
# even where everything else may. PostgreSQL's ALTER TYPE ... ADD VALUE is the
# known case -- rejected outright in a transaction block before server 12, and
# from 12 on accepted but the new value stays unusable until commit, so an
# upgrade that adds an enum value and then references it breaks either way.
#
# Rather than give that up for the whole batch, consecutive statements are
# grouped into runs, in their original order: each run of transaction-safe
# statements gets one txn_do, and a statement that cannot be in one runs on its
# own, bare. The common case -- every statement safe -- yields exactly one run
# and is therefore byte-identical to a single bracket around the loop.
#
# The trade is real and deliberate: what used to be one transaction becomes
# several, so a failure no longer takes the entire upgrade back. That is what
# the __VERSION gate in DBIO::DeploymentHandler is for (a re-run recomputes the
# diff against live state), and it is why the split is announced once.
#
# Returns a list of [ $transactional, @stmts ] arrayrefs.
sub _group_ddl_statements {
  my ($storage, $stmts) = @_;

  my @runs;
  for my $stmt (@$stmts) {
    my $txn = _stmt_is_txn_safe($storage, $stmt);

    if (@runs and $runs[-1][0] == $txn) {
      push @{ $runs[-1] }, $stmt;
    }
    else {
      push @runs, [ $txn, $stmt ];
    }
  }

  return @runs;
}

# Split DDL text under the SQL dialect the storage declares. The storage may be
# undef (a deploy with no reachable storage) or one that has never heard of
# _ddl_sql_dialect; both read as "not declared", which is the splitter's
# behaviour without the option, byte for byte. can() rather than eval, like
# _stmt_is_txn_safe: a hook that throws should be heard. The async deploy asks
# through the same function with its owner storage.
sub _split_ddl {
  my ($storage, $sql) = @_;
  my $dialect = $storage && Scalar::Util::blessed($storage)
    && $storage->can('_ddl_sql_dialect')
    ? $storage->_ddl_sql_dialect
    : undef;
  return DBIO::SQL::Util::_split_statements($sql,
    defined $dialect ? { dialect => $dialect } : undef);
}

# The per-statement half of the transactional_ddl question. Default yes: a
# driver that has never heard of the hook keeps the behaviour it had, which is
# also the right answer for every engine whose DDL is uniformly transactional.
#
# can() rather than eval here, unlike _storage_owns_dbh: this hook is new, so
# no facade can be delegating it without knowing it exists, and a driver whose
# hook throws should be heard rather than silently read as "safe".
sub _stmt_is_txn_safe {
  my ($storage, $stmt) = @_;
  return 1 unless $storage->can('_ddl_statement_is_transactional');
  return $storage->_ddl_statement_is_transactional($stmt) ? 1 : 0;
}

# One-time notice that a batch was split. Same reasoning as the
# non-transactional notice below -- an operator needs to know once that this
# upgrade was not atomic as a whole, and does not need telling on every deploy.
#
# Keyed on the CLASS, not on the message, which is where this one differs: the
# text carries how many statements forced the split and how many runs came out,
# and those vary from batch to batch. Keying on the message would let the same
# engine announce itself again for every new shape of upgrade, which is exactly
# the nagging the one-shot exists to prevent.
my %_WARNED_SPLIT_DDL;
sub _warn_split_ddl_once {
  my ($key, $msg) = @_;
  return if $_WARNED_SPLIT_DDL{$key}++;
  warn "split DDL batch on $msg\n";
}

# The bracket has to own the handle it brackets. _execute_ddl takes $dbh as an
# argument but can only bracket through $storage->txn_do, and those are not
# always the same connection: DBIO::Deploy::Base::TempDatabase opens its OWN
# raw DBI handle to the throwaway database (AutoCommit => 1) and hands that in.
# Bracketing there would open a transaction on the LIVE connection around DDL
# executing on a different one -- buying no atomicity, since the temp handle
# auto-commits every statement anyway, while a failure would roll back whatever
# the caller had open on the live connection. Not bracketing is not a
# compromise here: the throwaway database is dropped whole on any failure
# (TempDatabase::_build_target_model), so the DROP is the unit of recovery and
# a half-deployed temp schema is unreachable by definition.
#
# Hence no warning in that branch either. The F02 notice exists to tell an
# operator that a LIVE schema can be left half migrated; it would be noise on a
# database that is about to be dropped, and its text -- pointing at the
# version-row gate -- would be wrong there as well.
#
# _dbh is asked first: it is the raw attribute and never connects, and on a
# DBIO::Storage::DBI it holds the very handle dbh() hands out. It is called
# through eval rather than can(), so a delegating facade that answers by
# AUTOLOAD is not written off as handle-less. dbh() is the fallback for a
# storage exposing only the public accessor; any deploy reaching this point has
# already fetched a handle through it, so the extra call costs a ping at most.
#
# A storage that answers neither is treated as not owning the handle, leaving
# the loop unwrapped. That is the conservative direction: an unwrapped loop
# deploys correctly and merely without atomicity, whereas a wrongly wrapped one
# can roll back a connection it was never entitled to touch.
sub _storage_owns_dbh {
  my ($storage, $dbh) = @_;
  return 0 unless defined $dbh and ref $dbh;

  my $own = eval { $storage->_dbh } || eval { $storage->dbh };
  return 0 unless defined $own and ref $own;

  return Scalar::Util::refaddr($own) == Scalar::Util::refaddr($dbh) ? 1 : 0;
}

# F02: one-time informational warning for non-transactional DDL runs.
# Implemented as a local one-time closure rather than `use DBIO::Carp`
# to avoid the namespace leak (t/55namespaces_cleaned.t). Keyed on the
# full message so a different engine class gets its own one-shot.
#
# The wording stays as it is, deliberately. It reads as if the engine were at
# fault, when the driver may simply never have declared the capability -- but
# that is precisely what makes it useful, and it has already done the job:
# this notice appearing in a PostgreSQL deploy log is what surfaced that no
# driver but ClickHouse declared transactional_ddl at all. Softening it into
# "capability not declared" would turn an operator-facing statement about
# recovery into an internal remark most operators cannot act on. What the
# notice must NOT do is fire where it does not apply, which is why the
# foreign-handle branch above is silent.
my %_WARNED_NON_TXN_DDL;
sub _warn_non_txn_ddl_once {
  my ($msg) = @_;
  return if $_WARNED_NON_TXN_DDL{$msg}++;
  warn "non-transactional DDL on $msg\n";
}


sub _build_target_model {
  die ref(shift) . '::_build_target_model not implemented';
}

# --- database extensions (ADR 0066) -----------------------------------------


sub _extension_list { [] }


sub _extension_driver_helpers { {} }


sub _extension_connection_schema { undef }


sub _extension_restricted { 0 }


sub _apply_extension_claims {
  my ($self, $model, $addresses) = @_;
  DBIO::Exception->throw(
    ref($self) . ' cannot apply the extension claims of ' . scalar(@$addresses)
    . ' address(es): _apply_extension_claims is not implemented'
  );
}


sub _apply_extension_annotations {
  my ($self, $model, $triples) = @_;
  DBIO::Exception->throw(
    ref($self) . ' cannot apply the extension annotations of ' . scalar(@$triples)
    . ' triple(s): _apply_extension_annotations is not implemented'
  );
}


# Read-only all the way down: hashes (keys and values) and the arrays in them.
# A file-scoped closure, not a sub: a named helper would be a method of every
# deploy class (t/55namespaces_cleaned.t).
my $lock_deep;
$lock_deep = sub {
  my ($x) = @_;
  if (ref $x eq 'HASH') {
    $lock_deep->($_) for values %$x;
    Hash::Util::lock_hashref($x);
  }
  elsif (ref $x eq 'ARRAY') {
    $lock_deep->($_) for @$x;
    Internals::SvREADONLY($_, 1) for @$x;
    Internals::SvREADONLY(@$x, 1);
  }
  return;
};

sub _apply_extension_states {
  my ($self, $model, $states) = @_;
  $model->{extensions} = $states;
  require Hash::Util;
  $lock_deep->($model->{extensions});
  return;
}


sub _extension_verdict {
  my ($self, $change) = @_;
  my $protocol = $self->{_extension_protocol} or return undef;
  return $protocol->verdict($change);
}

# --- public orchestration ----------------------------------------------------


sub install {
  my ($self) = @_;
  my $ddl = $self->_install_ddl;
  # A class that overrides install owns the dropping; its SUPER::install only
  # installs.
  if ($self->add_drop_table
      and (ref($self)->can('install') || 0) == \&DBIO::Deploy::Base::install) {
    my $storage = $self->_driver_storage;
    my $dialect = $storage && $storage->can('_ddl_sql_dialect')
      ? $storage->_ddl_sql_dialect : undef;
    my $drop = DBIO::SQL::Util::_drop_statements(
      $self->schema,
      sub { $self->_ddl_quote_ident($_[0]) },
      { cascade => !(defined $dialect && $dialect eq 'sqlite') },
    );
    $ddl = "$drop\n\n$ddl" if length $drop;
  }
  $self->_execute_ddl($self->_dbh, $ddl);
  return 1;
}


sub diff {
  my ($self, $opts) = @_;
  my %opts = $self->_diff_options($opts);
  my $source_model = $self->_introspect_current;
  my $target_model = $self->_build_target_model;

  my $entries = $self->_extension_list;
  delete $self->{_extension_protocol};
  return $self->_diff_class->new(
    source => $source_model,
    target => $target_model,
    %opts,
  ) unless @$entries;

  # Loaded only when extensions are declared: a plain session pays nothing.
  require DBIO::Extension::Protocol;
  my $protocol = $self->{_extension_protocol} = DBIO::Extension::Protocol->new(
    entries           => $entries,
    driver            => $self->_extension_driver_helpers,
    connection_schema => $self->_extension_connection_schema,
    restricted        => $self->_extension_restricted,
  );
  $protocol->inspect($self->_dbh);
  ($source_model, $target_model)
    = $protocol->extend_models($self, $source_model, $target_model);

  return $self->_diff_class->new(
    source     => $source_model,
    target     => $target_model,
    extensions => $protocol,
    %opts,
  );
}

# The options of diff, checked against what the diff class declares.
sub _diff_options {
  my ($self, $opts) = @_;
  return () unless defined $opts;
  DBIO::Exception->throw(
    "The options of diff must be a hash reference, got '" . (ref($opts) || $opts) . "'"
  ) unless ref $opts eq 'HASH';

  my $class = $self->_diff_class;
  my %known = map { $_ => 1 } $class->diff_options;
  for my $key (sort keys %$opts) {
    DBIO::Exception->throw(
      "Unknown diff option '$key' for $class (known: "
    . (join(', ', sort keys %known) || 'none') . ")"
    ) unless $known{$key};
  }
  return %$opts;
}


sub apply {
  my ($self, $diff, %opts) = @_;
  my ($allow, $dry_run) = $self->_apply_options(%opts);
  return unless $diff->has_changes;

  if ($dry_run) {
    $diff->as_sql;   # a diff that cannot render fails here, as in a real run
    return $diff;
  }

  $self->_assert_diff_allowed($diff, $allow);
  $self->_check_before_apply($diff);
  return $self->_execute_diff($diff);
}


sub _check_before_apply { return }


sub _execute_diff {
  my ($self, $diff) = @_;
  my @sql = $diff->as_sql;
  $self->{_extension_protocol}->assert_no_refusals if $self->{_extension_protocol};
  $self->_execute_ddl($self->_dbh, @sql);
  return 1;
}

# The arguments of apply and upgrade: (allow_destructive, dry_run).
sub _apply_options {
  my ($self, %opts) = @_;
  my %known = map { $_ => 1 } qw(allow_destructive dry_run);
  for my $key (sort keys %opts) {
    DBIO::Exception->throw(
      "Unknown option '$key' for apply/upgrade of " . ref($self)
    . " (known: " . join(', ', sort keys %known) . ")"
    ) unless $known{$key};
  }
  my $allow = exists $opts{allow_destructive}
    ? $opts{allow_destructive} : $self->allow_destructive;
  return ($allow ? 1 : 0, $opts{dry_run} ? 1 : 0);
}

# Refusals stop every run; destructive and lossy operations stop a run that is
# not released with allow_destructive.
sub _assert_diff_allowed {
  my ($self, $diff, $allow) = @_;
  my $class = ref $diff;

  DBIO::Exception->throw(
    "Cannot apply the diff: $class cannot classify itself (a diff class derives from DBIO::Diff::Base)"
  ) unless $diff->can('classify') && $diff->can('destructive_operations');

  my $c = $diff->classify;
  if (!defined $c->{class} || @{ $c->{refused} || [] }) {
    DBIO::Exception->throw(
      "Refusing to apply the diff, it contains operations the deploy refuses:\n"
    . join("\n", map { "  $_" } @{ $c->{refused} || [] })
    );
  }

  return if $allow;
  my @risky = $diff->destructive_operations;
  return unless @risky;
  DBIO::Exception->throw(
    "Refusing to apply a destructive diff without allow_destructive => 1; no statement has run. "
  . "These operations drop or may alter stored data:\n"
  . join("\n", map { '  ' . $_->summary } @risky)
  );
}


sub upgrade {
  my ($self, %opts) = @_;
  $self->_apply_options(%opts);
  my $diff = $self->diff;
  return unless $diff->has_changes;
  $self->apply($diff, %opts);
  return $diff;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Deploy::Base - Base class for DBIO driver deploy orchestrators

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Base class for the per-driver C<Deploy> orchestrators
(L<DBIO::PostgreSQL::Deploy>, L<DBIO::MySQL::Deploy>, L<DBIO::DuckDB::Deploy>,
L<DBIO::SQLite::Deploy>). Those classes implement the same
test-deploy-and-compare strategy and their C<install>/C<apply>/C<upgrade>
methods were byte-near-identical; only the way C<diff> obtains the I<target>
model (deploy the desired schema into a throwaway database and introspect it)
is genuinely engine-specific.

This base hosts the shared orchestration:

=over 4

=item * L</install> -- generate install DDL and run it against the live db.

=item * L</apply> -- run a diff's SQL against the live db.

=item * L</upgrade> -- L</diff> then L</apply>.

=item * L</diff> -- introspect the live db (source), build the target model,
and hand both to the driver's diff class.

=back

against a handful of hooks. A subclass must provide the three class-name hooks
(L</_ddl_class>, L</_introspect_class>, L</_diff_class>) and L</_build_target_model>
-- the "make a throwaway, deploy the desired schema, introspect it" step that
is the real engine seam. Drivers that use a temporary I<database> (PostgreSQL,
MySQL) get a ready-made L</_build_target_model> by subclassing
L<DBIO::Deploy::Base::TempDatabase> instead; in-memory drivers (DuckDB, SQLite)
override L</_build_target_model> directly with a C<:memory:> connection.

=head1 ATTRIBUTES

=head2 schema

A connected L<DBIO::Schema> instance using the driver's component. Required.

=head2 add_drop_table

    my $deploy = $class->new(schema => $schema, add_drop_table => 1);

Optional. When true, L</install> drops what the schema declares before it
creates it: first the declared views (in the reverse of their install order),
then the tables, each as C<DROP ... IF EXISTS>, in the same batch as the install
DDL. A fresh deploy over an existing copy of the schema is what it is for.
L<DBIO::Schema/deploy> and L<DBIO::Storage::DBI/deploy> hand it on from the
C<add_drop_table> key of their options (L</deploy_args>). A class that
overrides L</install> owns the dropping itself (see there).

=head2 allow_destructive

    my $deploy = $class->new(schema => $schema, allow_destructive => 1);

Optional. The standing release for destructive changes: when true,
L</apply> and L</upgrade> run a diff that drops or possibly alters stored data
(see L</apply>). The argument C<allow_destructive> of those two methods, when
given, takes the place of this attribute for that call. Defaults to false.
Read/write; the setter returns the object.

=head1 METHODS

=head2 new

    my $deploy = $class->new(schema => $connected_schema, %extra);

Blesses the argument hash. C<schema> is required.

=head2 contract_version

    my $v = $class->contract_version;

Returns C<$CONTRACT_VERSION>, the compatibility version of this base class's
public interface -- independent of the dist C<$VERSION> and unaffected by a
release that changes no contract shape. See L</CONTRACT VERSION> above and
ADR 0024.

=head2 deploy_args

    my %args = DBIO::Deploy::Base->deploy_args(\%sqltargs);
    my $deploy = $deploy_class->new(schema => $schema, %args);

Turns the options a caller handed to C<< $schema->deploy >> or
C<< $storage->deploy >> into the arguments of L</new>. Only C<add_drop_table>
is known. Any other key throws, naming the key, so an option is never dropped
silently. C<version> in particular is refused: the native install always
installs the current state of the schema, a version is not selectable. An
C<undef> argument is no options; anything but a hash reference throws.

=head2 _ddl_quote_ident

    my $quoted = $deploy->_ddl_quote_ident($name);

How an identifier is written in the DROP statements of L</add_drop_table>:
through the storage's C<_ddl_quote_ident> when it has one, else a plain
identifier stays bare and any other is double-quoted
(L<DBIO::SQL::Util>). Override for an engine that quotes differently.

=head2 _driver_storage

    my $storage = $deploy->_driver_storage;

The storage that answers the driver's own hooks (C<_ddl_quote_ident>,
C<_ddl_sql_dialect>, C<_use_transactional_ddl>, ...): the storage of the
schema, or, when that is a L<DBIO::Replicated::Storage>, the driver storage of
its master. The replicated storage forwards a named list of methods and no
others, so a hook of a driver is asked of the master's storage directly.
C<undef> when the schema has no storage.

=head2 driver_storage

    my $storage = DBIO::Deploy::Base::driver_storage($schema->storage);

The function behind L</_driver_storage>: the driver storage of the master for
a L<DBIO::Replicated::Storage>, any other storage as it is.

=head2 _ddl_class

Class name whose C<install_ddl($schema)> returns the install DDL. Abstract.

=head2 _introspect_class

Class name whose C<< new(dbh => $dbh)->model >> returns an introspected model.
Abstract.

=head2 _diff_class

Class name whose C<< new(source => $m, target => $m) >> returns a diff object
(responding to C<has_changes> and C<as_sql>). Abstract.

=head2 _new_introspect

    my $intro = $self->_new_introspect($dbh);

Factory for an introspector over C<$dbh>. Default: C<< _introspect_class->new(dbh => $dbh) >>.
Override to pass extra construction args (e.g. PostgreSQL's C<schema_filter>).

=head2 _introspect_current

The introspected model of the live (source) database. Default:
C<< $self->_new_introspect($self->_dbh)->model >>.

=head2 _install_ddl

The install DDL string for the connected schema. Default:
C<< _ddl_class->install_ddl($self->schema) >>.

=head2 _execute_ddl

    $self->_execute_ddl($dbh, $sql);

Splits C<$sql> into statements (L<DBIO::SQL::Util/_split_statements>) and runs
each via C<< $dbh->do >>. The splitter reads the text as SQL: a semicolon
inside a string literal, a quoted identifier, a comment, a dollar-quoted string
or the body of a C<CREATE TRIGGER> ends nothing, a comment in front of a
statement is taken off it, and a piece that holds only comments is no statement
and is not run. The body of a function or a procedure is read as one statement
when the storage declares a dialect that has a reader for it: PostgreSQL's
C<BEGIN ATOMIC ... END> body and nested C</* /* */ */> comments under
C<postgresql>, and under C<oracle> every PL/SQL unit (function, procedure,
package, type body, trigger, anonymous block), which is run as one statement
with the semicolon behind its C<END> and ends at a line of C</> as well. A
routine in any other dialect has to come dollar-quoted.

The splitter reads a backslash in a literal one way or the other depending on
the engine, and the text cannot say which. It is told by the storage:
C<_ddl_sql_dialect> (L<DBIO::Storage::DBI::Capabilities/_ddl_sql_dialect>)
names C<postgresql>, C<sqlite>, C<mysql> or C<oracle>. A storage that does not declare one
-- the default -- leaves the splitter taking both readings.

When the storage reports C<< _use_transactional_ddl >> truthy B<and> C<$dbh> is
the handle that storage itself holds, the loop is wrapped in
C<< $storage->txn_do >> so a failure on any statement rolls the whole batch
back. The ownership half matters because this method is also called with a
foreign handle: L<DBIO::Deploy::Base::TempDatabase> opens its own connection to
the throwaway database and deploys into that. Bracketing a transaction on the
live connection around DDL running on another one would buy no atomicity and
could roll back the caller's own work, so that case runs unwrapped and silent
-- the throwaway database is dropped whole on failure, which is its unit of
recovery.

Within a bracketed batch the statements are grouped by the storage's
C<_ddl_statement_is_transactional> hook, so DDL an engine refuses to run
inside a transaction runs outside one without costing the rest of the batch
its atomicity; see L</Per-statement exceptions>. With no such statement — the
usual case — there is exactly one group and exactly one C<txn_do>.

When the storage reports C<0> (the default for engines
whose DDL forces an implicit C<COMMIT> -- MySQL and MariaDB on every version,
Oracle, Sybase, Informix -- or whose rebuild path depends on C<AutoCommit=on>, e.g. SQLite,
or that deliberately declines a capability its engine could support, e.g.
DB2), the loop runs statement-at-a-time as before and a C<carp> is emitted
naming this engine class so operators see that a partial-failure recovery
depends on per-driver bookkeeping (e.g. the C<__VERSION> row gate in
L<DBIO::DeploymentHandler>).

=head2 _build_target_model

The desired-state model: deploy the install DDL into a throwaway database and
introspect it. Abstract here -- provided by L<DBIO::Deploy::Base::TempDatabase>
for temp-database drivers, or overridden directly by in-memory drivers.

=head2 _extension_list

    my $entries = $self->_extension_list;

The resolved list of the database extensions the schema declares, as an array
reference of L<DBIO::Extension::List/entries> (name, class, options, with the
installed state the driver read attached). Default: C<[]> -- no extensions, and
then L</diff> behaves exactly as without the protocol. A driver that supports
extensions overrides this with its list; it spells the declaration, owns the
table of the family's classes and reads the installed state.

=head2 _extension_driver_helpers

The hash reference that becomes C<< $ctx->{driver} >> of every extension
(quote and key helpers, address constructors). Default: C<{}>.

=head2 _extension_connection_schema

The namespace of the connection (ADR 0065) for C<< $ctx->{connection_schema} >>.
Default: C<undef>.

=head2 _extension_restricted

True when the deploy is restricted to the schemas it manages, for
C<< $ctx->{restricted} >>. Default: false.

=head2 _apply_extension_claims

    $self->_apply_extension_claims($model, \@addresses);

Driver seam, phase 1: remove the objects at the claimed addresses from
C<$model> (with the driver's cascade: a claimed schema takes its tables, a
table its columns, indexes, triggers, keys). Called only when there is at least
one address. The default throws: a driver that declares extensions that claim
something must implement it.

=head2 _apply_extension_annotations

    $self->_apply_extension_annotations($model, \@triples);

Driver seam, phase 2: set the C<< [ $address, $attribute, $value ] >> triples on
the objects of C<$model>. Called only when there is at least one triple. The
default throws, like L</_apply_extension_claims>.

=head2 _apply_extension_states

    $self->_apply_extension_states($model, \%states);

Puts the phase 0 states into the model, read-only, under their extension names.
Called only when an extension returned a state. Default:
C<< $model->{extensions} = \%states >>, read-only all the way down -- the
hashes (keys and values) and the arrays in them, locked with L<Hash::Util> and
C<Internals::SvREADONLY>. Both models of a diff get the same states.

=head2 _extension_verdict

    my $answer = $self->_extension_verdict($change);

For a driver's diff code that has the deploy: the merged phase 3 answer for one
change (C<undef>, C<< { using => $expr } >> or C<< { refuse => \@messages } >>).
C<undef> without declared extensions. A refusal makes L</apply> throw.

=head2 install

    $deploy->install;

Generates the install DDL and executes it against the connected database.
Suitable for a fresh install on an empty database. Returns true.

With L</add_drop_table> true, the drop statements of the declared views and
tables (L<DBIO::SQL::Util>, without C<CASCADE> on an engine that declares the
C<sqlite> dialect, which does not know it) go in front of the install DDL, in
the same batch. B<If a driver overrides C<install>, it owns the dropping>: the
generic drop runs only when the class uses this C<install> itself, so a
C<SUPER::install> from an override installs and does not drop a second time.

=head2 diff

    my $diff = $deploy->diff;
    my $diff = $deploy->diff({ foreign_keys_not_valid => 1 });

Introspects the live database (source), builds the target model via
L</_build_target_model>, and returns C<< _diff_class->new(source => ..., target => ...) >>.

With database extensions declared (L</_extension_list>) the extension protocol
of ADR 0066 runs around it: phase 0 reads the extensions' state over the live
handle, phases 1 and 2 (claims, annotations) are applied to the source and the
target model with the same set, and the diff class is constructed with the
additional argument C<extensions>, the L<DBIO::Extension::Protocol>, so it can
ask C<< ->verdict($change) >> for a change it is about to write (see
L</_extension_verdict>). Without declared extensions nothing of this happens
and the diff is built from the two models as they are.

The optional argument is a hash reference of options for the diff class. It is
handed to C<new> of the diff class (on the extension path as well) beside
C<source> and C<target>. Only the names the diff class lists in
C<< ->diff_options >> (L<DBIO::Diff::Base/diff_options>) are accepted; any other
key throws, naming the key and the diff class, so an option is never dropped
silently. An C<undef> argument is no options; anything but a hash reference
throws.

=head2 apply

    $deploy->apply($diff);
    $deploy->apply($diff, allow_destructive => 1);
    my $same_diff = $deploy->apply($diff, dry_run => 1);

Executes each statement of C<< $diff->as_sql >> against the connected
database. No-op (returns false) when C<< $diff->has_changes >> is false.

Before the first statement the diff is read through
L<DBIO::Diff::Base/classify> and L<DBIO::Diff::Base/destructive_operations>:

=over 4

=item * A diff with a refusal (an operation whose action is C<refuse>) is never
applied. The L<DBIO::Exception> names the C<summary> of each refusing
operation. No option releases it.

=item * A diff with a destructive operation (a drop of something the schema
class does not declare) or an operation that reports a possibly lossy change
(the optional operation method C<lossy>, see L<DBIO::Diff::Base/destructive_operations>)
runs with C<< allow_destructive => 1 >>, given as argument or as the
L</allow_destructive> attribute. Without it the L<DBIO::Exception> names the
C<summary> of each such operation and no statement has run.

=item * Everything else (additive and changing operations) runs as it is.

=back

The release is for destructive operations only; the model of the diff, the
extension protocol and the refusals keep their say.

With C<< dry_run => 1 >> nothing is executed and nothing is checked: C<apply>
returns the diff itself, whose C<< ->as_sql >>, C<< ->summary >> and
C<< ->classify >> show what a real run would do. It returns false for a diff
without changes.

Other argument names throw, naming the name.

C<apply> and L</upgrade> are the only entry points; a driver class inherits
both and takes part through two hooks, run in this order for a released diff:
L</_check_before_apply> (the driver's checks against the live tables) and
L</_execute_diff> (the execution itself).

=head2 _check_before_apply

    sub _check_before_apply {
      my ($self, $diff) = @_;
      # compare the diff with the live tables; throw DBIO::Exception to stop
      $self->next::method($diff);
    }

Driver seam of L</apply>, called once the diff is released (the guard has
passed) and before the first statement runs. A driver puts its checks of the
diff against the live tables here (rows a new constraint would violate, a
reorganisation a statement needs first) and throws a L<DBIO::Exception> to
stop the run. Not called for C<dry_run> or a diff without changes. The default
does nothing.

=head2 _execute_diff

    sub _execute_diff {
      my ($self, $diff) = @_;
      ...                      # the driver's own way to run the diff
      return 1;
    }

Driver seam of L</apply>: runs a diff that has been checked and released, and
returns true. The default renders C<< $diff->as_sql >>, asks the extension
protocol of the diff for refusals and hands the statements to L</_execute_ddl>.
A driver that executes in its own way (a table rebuild, statements after the
DDL, a reorganisation) overrides this method and inherits L</apply> and
L</upgrade> unchanged.

=head2 upgrade

    my $diff = $deploy->upgrade;
    my $diff = $deploy->upgrade(allow_destructive => 1);
    my $diff = $deploy->upgrade(dry_run => 1);

Convenience: L</diff> then L</apply>. Returns the diff object if changes were
applied, or C<undef> if the database was already up to date. The arguments are
those of L</apply> and are handed on to it: C<allow_destructive> releases a
destructive diff, and C<dry_run> returns the diff without having executed
anything. An unknown argument name throws before the diff is built.

=head1 CONTRACT VERSION

This class exposes an independent compatibility version, distinct from
C<$VERSION> (the dist version injected by L<Dist::Zilla>'s
C<VersionFromMainModule>):

    my $v = $class->contract_version;

C<$CONTRACT_VERSION> bumps when the deploy orchestrator's public interface
(C<install>, C<apply>, C<upgrade>, C<diff>) or the hook contract
(C<_ddl_class>, C<_introspect_class>, C<_diff_class>,
C<_build_target_model>) changes. The dist C<$VERSION> bumps on every
release, but two core releases at the same contract version remain
wire-compatible. Out-of-tree drivers should record the contract version
they were last tested against and compare it against core's at load time,
warning (or strict-failing under C<DBIO_STRICT_CONTRACT>) when the shapes
have drifted. See F<docs/adr/> for the contract-version policy.

=head1 TRANSACTIONAL DDL

Whether the loop in L</_execute_ddl> is wrapped in C<< $storage->txn_do >>
is governed by the C<transactional_ddl> capability on the storage
(L<DBIO::Storage::DBI::Capabilities>), plus one condition that is not about
the engine at all: the C<$dbh> handed to L</_execute_ddl> must be the handle
that storage owns. It is not always — L<DBIO::Deploy::Base::TempDatabase>
deploys into a connection it opened itself — and bracketing the live storage
around DDL running elsewhere is worse than not bracketing at all. See
L</_execute_ddl>.

The capability answers one narrow question: can several DDL statements run
inside one transaction and be taken back by a C<ROLLBACK>?

=over 4

=item * B<Transactional>: PostgreSQL, Firebird, Microsoft SQL Server. DDL
participates in the surrounding transaction, so the driver sets
C<< _use_transactional_ddl(1) >> and the whole multi-statement batch runs as
one atomic unit — a failure on statement 7 of 12 rolls back the preceding six.

=item * B<Implicit COMMIT on DDL>: MySQL, MariaDB, Oracle, Sybase,
Informix. Each DDL statement commits the transaction around it, so wrapping
C<< $dbh->do >> in C<txn_do> changes nothing and the loop runs
statement-at-a-time. A one-time notice is emitted at the first
L</_execute_ddl> call naming the deploy class, so operators see that
partial-failure recovery rests on the driver's own bookkeeping (e.g. the
version-row gate).

B<MySQL 8.0 and MariaDB 10.6 do not change this>, and their I<atomic DDL> is
easy to mistake for it: atomic DDL means a I<single> statement no longer
half-completes across a crash — no orphaned table left without its data
dictionary entry. It does not put DDL under transaction control, and it does
not let a C<ROLLBACK> undo a C<CREATE TABLE>. This capability asks the second
question, so for these engines the answer stays C<0> on every version.

=item * B<Capable, but deliberately answering no>: SQLite, DB2. The engine
does have transactional DDL, but its diff path rebuilds tables in place and
that rebuild depends on C<AutoCommit=on>; a blanket C<txn_do> wrap regresses
it. Nothing in core special-cases SQLite — the decision is carried entirely by
the driver declaring C<< _use_transactional_ddl(0) >>, which is why that
declaration must stay explicit and commented in the driver rather than being
"tidied up" to match the engine. DB2 also runs DDL inside the current unit of
work (a C<ROLLBACK> takes it back), so the driver's answer is a deliberate
C<0> for its own reasons, not an engine limit: it drops and re-creates an
index under the same name inside one batch, and on z/OS the pending DROP can
make the re-CREATE fail (SQLCODE -679). Both reasons are unmeasured — no live
DB2 has been tested against this driver — which is exactly why the
declaration names them instead of staying silent.

=back

B<Every driver should declare its answer> rather than inherit the default.
Core defaults to C<0> because that is the safe assumption for an engine nobody
has checked, but a storage that stays silent is indistinguishable from one that
was overlooked, and it leaves the deploy path resting on a core default core is
free to change. L<DBIO::ClickHouse::Storage> is the reference shape: an
explicit C<< _use_transactional_ddl(0) >> with its reasoning, and a test
pinning the value together with C<get_inherited>, which is defined only for a
value the class set itself. Core is not neutral about this either — a
capability read as a class method C<dies> unless it was declared outright.

Recovery on the non-transactional set is engine-specific.
L<DBIO::DeploymentHandler> relies on the C<__VERSION> row as a
forward-progress gate: a partially applied upgrade can be re-run safely
because the diff re-computes against live state, and the next apply picks up
the remainder.

=head2 Per-statement exceptions

The capability answers for the connection, but atomicity is decided per
statement: some engines have DDL that may not be inside a transaction even
where everything else may. The known case is PostgreSQL's
C<ALTER TYPE ... ADD VALUE> — rejected outright in a transaction block before
server 12, and from 12 on accepted while the new value stays unusable until
that transaction commits, so an upgrade that adds an enum value and then
references it breaks either way.

A driver declares those statements through the
C<_ddl_statement_is_transactional> hook on
L<DBIO::Storage::DBI::Capabilities>, and L</_execute_ddl> groups consecutive
statements by the answer, in their original order: each run of
transaction-safe statements gets one C<txn_do>, and a statement that answered
false runs on its own, outside any transaction. A batch where everything
answers true is a single run, identical to bracketing the whole loop, so a
driver that never defines the hook sees no change.

Where a batch does split, the upgrade is no longer atomic as a whole — a
failure in a later run leaves the earlier ones applied. That is what the
C<__VERSION> gate below is for, and core announces the split once so operators
know which recovery story applies.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
