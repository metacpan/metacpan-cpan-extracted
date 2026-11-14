package DBIO::Storage::DBI::Capabilities;
# ABSTRACT: Three-tier capability probing for DBI storage drivers

use strict;
use warnings;

our $VERSION = '0.900005';

use base 'DBIO::Storage';
use mro 'c3';

use DBIO::Exception;

use namespace::clean;

our $CONTRACT_VERSION = '1.3';



sub contract_version { $CONTRACT_VERSION }

my @capabilities = (qw/
  insert_returning
  insert_returning_bound

  multicolumn_in

  placeholders
  typeless_placeholders

  join_optimizer

  transactional_ddl
  supports_if_exists
  supports_upsert
  supports_upsert_where
  supports_exists_query
/);
__PACKAGE__->mk_group_accessors( dbms_capability => map { "_supports_$_" } @capabilities );
__PACKAGE__->mk_group_accessors( use_dbms_capability => map { "_use_$_" } (@capabilities ) );

# on by default, not strictly a capability (pending rewrite)
__PACKAGE__->_use_join_optimizer (1);
sub _determine_supports_join_optimizer { 1 };

# transactional_ddl and supports_if_exists are engine-specific facts. The
# default _determine_supports_* returns 0 (conservative: do not assume the
# engine is transactional / has the IF [NOT] EXISTS syntax until the driver
# says so). Drivers override via _use_X or _determine_supports_X.
sub _determine_supports_transactional_ddl { 0 }
sub _determine_supports_supports_if_exists { 0 }

# The per-statement half of transactional_ddl (ADR 0026 addendum). The
# capability is one boolean for the connection, but atomicity is decided per
# statement: some engines have DDL that may not be inside a transaction even
# where everything else may. Default yes -- a driver that never overrides this
# behaves exactly as before, and that is also the correct answer for every
# engine whose DDL is uniformly transactional. Only a driver that emits such a
# statement needs to say so. See L</_ddl_statement_is_transactional>.
sub _ddl_statement_is_transactional { 1 }

# The SQL dialect the engine's DDL is split under. undef = not declared = the
# splitter takes both backslash readings, as it always has. A driver names
# 'postgresql', 'sqlite', 'mysql' or 'oracle'. See L</_ddl_sql_dialect>.
sub _ddl_sql_dialect { undef }

# supports_upsert (ADR 0036) is the same kind of engine-specific fact: an
# atomic INSERT ... ON CONFLICT / ON DUPLICATE KEY needs both engine grammar
# and a driver SQLMaker that renders it, so the conservative default is 0.
sub _determine_supports_supports_upsert { 0 }

# ... and the conditional conflict branch on top of it. Default 0 is what
# keeps a driver that has never heard of the option safe: core refuses to
# send a condition rather than let it be dropped into an unconditional write.
sub _determine_supports_supports_upsert_where { 0 }

# supports_exists_query (ADR 0037): a boolean-valued EXISTS query is one more
# engine fact -- three engines need a dummy table in it, and the ones nobody
# has checked are exactly the ones a default-on would ship broken SQL to. The
# driver renders the whole fragment (_exists_value_sql) and declares here that
# it did.
sub _determine_supports_supports_exists_query { 0 }

sub set_use_dbms_capability {
  my ($self, $capname, $value) = @_;

  # ADR 0041. The per-storage force (tier 1) and the class-level
  # declaration (tier 2) are two physically different slots -- set_inherited
  # writes the instance hash for an instance invocant and the
  # $Class::__cag_<field> package variable for a class one -- but
  # get_inherited reads the instance with exists(), not defined(). A plain
  # undef assignment would therefore leave a *tombstone* in tier 1 that
  # shadows the declaration for the life of this storage: the caller who
  # forces a capability off and then clears the force does not get the
  # driver's answer back, they fall through to _determine_supports_* and land
  # on core's conservative default.
  #
  # Deleting the slot is what "clear" has to mean, and undef is unambiguous
  # here: get_use_dbms_capability below already treats undef as "no opinion,
  # ask the next tier", so undef can never have meant "off" -- that is 0.
  #
  # A class invocant needs nothing: get_inherited tests defined() while it
  # walks classes, so an undef declaration already falls through on its own.
  if (! defined $value and ref $self) {
    delete $self->{$capname};
    return undef;
  }

  $self->set_inherited ($capname, $value);
}

sub get_use_dbms_capability {
  my ($self, $capname) = @_;

  my $use = $self->get_inherited ($capname);
  return defined $use
    ? $use
    : do { $capname =~ s/^_use_/_supports_/; $self->get_dbms_capability ($capname) }
  ;
}

sub set_dbms_capability {
  $_[0]->_dbh_details->{capability}{$_[1]} = $_[2];
}

sub get_dbms_capability {
  my ($self, $capname) = @_;

  # Determining a capability reads the per-$dbh detail slot, so a class-method
  # invocant runs out of road right here. Left alone, the accessor below dies
  # with "Class::XSAccessor: invalid instance method invocant: no hash ref
  # supplied", which names neither the capability nor the reason -- and the
  # very same call *does* work on a class whose driver declared the value via
  # _use_, so the failure looks arbitrary from the call site.
  # The check sits where the instance is actually needed and costs one ref().
  unless (ref $self) {
    (my $usename = $capname) =~ s/^_supports_/_use_/;
    DBIO::Exception->throw(
      "Cannot determine the capability '$capname' on class '$self': "
    . "determining a capability probes the connected \$dbh and therefore needs "
    . "a storage instance -- ask one instead "
    . "(\$schema->storage->${capname}). A capability answers as a class method "
    . "only where a driver declared its value outright, with "
    . "__PACKAGE__->${usename}(0|1) in its storage class; that is why some "
    . "capabilities work that way and their neighbours die here"
    );
  }

  my $cap = $self->_dbh_details->{capability}{$capname};

  unless (defined $cap) {
    if (my $meth = $self->can ("_determine$capname")) {
      $cap = $self->$meth ? 1 : 0;
    }
    else {
      $cap = 0;
    }

    $self->set_dbms_capability ($capname, $cap);
  }

  return $cap;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Storage::DBI::Capabilities - Three-tier capability probing for DBI storage drivers

=head1 VERSION

version 0.900005

=head1 DESCRIPTION

Capability detection for L<DBIO::Storage::DBI>. Every capability C<X> is
answered by asking three tiers in order and taking the first defined answer.
The tiers are separate slots, and which one a value lands in is decided by
B<how> it was written, not by which accessor was used:

=over 4

=item 1. The per-storage force -- C<< $storage->_use_X(0|1) >>

Written on an B<instance>. This is the caller's slot: one application, one
storage object, overriding whatever the driver believes. It lives in the
storage's own hash and dies with it.

Clear it with C<< $storage->_use_X(undef) >>, which hands the question back to
tier 2 (see L</Clearing a force> -- C<undef> B<removes> the force, it does not
mean "off"; "off" is C<0>).

=item 2. The class-level declaration -- C<< __PACKAGE__->_use_X(0|1) >>

Written on a B<class>, in a driver's storage class body. This is the driver's
slot for a fact that is a static property of the driver. It lives in a package
variable and is inherited down C<@ISA>, so a subclass of the declaring storage
gets it too.

It is B<not> the same slot as tier 1 -- C<set_inherited> writes the instance
hash for an instance invocant and the C<$Class::__cag_*> package variable for a
class one -- which is why a caller can force over a class declaration and get
the declaration back afterwards.

=item 3. The determination -- C<sub _determine_supports_X>

The driver's slot for a fact that has to be B<probed>: an answer that depends
on the server version, on which C<DBD> is loaded, on anything only the live
C<$dbh> knows. Called through C<_supports_X>, a simple-style accessor that
caches the answer in a slot wiped on every C<$dbh> reconnection (a reconnect is
not guaranteed to land on the same RDBMS version).

C<_determine_supports_X> does not need to exist on a driver -- the runtime
C<< ->can >>-checks for it before calling, and a capability with neither a
declaration nor a determiner reads as C<0>.

=back

C<< $storage->_use_X >> is the accessor to B<read>: it is the only one that
consults all three tiers, and it is what every consumer in core asks
(L<DBIO::ResultSet/upsert>, L<DBIO::ResultSet/results_exist>,
L<DBIO::Diff::Op/should_emit_if_exists>, L<DBIO::Deploy::Base/_execute_ddl>,
L<DBIO::DeploymentHandler>). C<< $storage->_supports_X >> is tier 3's own
accessor and answers for tier 3 alone -- on a storage whose driver declared in
tier 2 it will report the default while C<_use_X> reports the declaration, and
that is not a disagreement to fix but the difference between "what did the
probe find" and "what is the answer".

=head2 Which tier a driver writes to

Tiers 2 and 3 are B<both> the driver's. Pick by what is being declared, not by
what the caller might want to do with it -- the caller's slot is tier 1 and
neither declaration form takes it away:

=over 4

=item *

A B<static fact> about this driver -- "this storage renders the standard
C<CASE WHEN EXISTS> form", "this engine commits DDL implicitly" -- goes in tier
2, C<< __PACKAGE__->_use_X(0|1) >>. It answers as a class method, before any
connection and before any storage object exists.

=item *

A B<probed fact> -- "PostgreSQL 9.5 and up", "MariaDB 10.5 and up" -- goes in
tier 3, C<sub _determine_supports_X>, where it can read C<_server_info>.

=back

Declaring in both tiers with the same constant is harmless but says nothing
extra; one is enough.

=head2 Clearing a force

C<< $storage->_use_X(undef) >> B<removes> the tier-1 force, and the question
falls to tier 2 and then tier 3 -- so a caller who forces a capability off and
later changes their mind gets the B<driver's> answer back, not core's default.

This is not what L<Class::Accessor::Grouped> does on its own, and the
difference is the reason C<set_use_dbms_capability> exists as an override
rather than a straight call to C<set_inherited>: C<get_inherited> reads an
instance slot with C<exists>, not C<defined>, so a plain C<undef> assignment
would leave a tombstone shadowing the class declaration for the life of the
storage instead of clearing anything. Assigning C<undef> to an
instance therefore B<deletes> the slot. On a class invocant nothing special
happens -- C<get_inherited> already tests C<defined> when it walks classes, so
an C<undef> declaration falls through by itself.

=head2 Driver-declared capabilities and the per-name accessor

A driver may add capabilities of its own:

  __PACKAGE__->mk_group_accessors( dbms_capability     => '_supports_X' );
  __PACKAGE__->mk_group_accessors( use_dbms_capability => '_use_X' );

The three tiers then work exactly as above -- but the two per-name accessors
are installed in B<the class that declared them>, and core reblesses a storage
into its driver class lazily, on first use. On a freshly connected storage that
has not been reblessed yet, C<< $storage->_use_X(...) >> is therefore not a
method at all:

  Can't locate object method "_use_X" via package "DBIO::Storage::DBI"

Core cannot install it in advance: it does not know the name, and the driver's
storage class is not even loaded until determination runs. Two forms work
regardless, and a driver's POD should name one of them:

=over 4

=item *

C<< DBIO::Yourdb::Storage->_use_X(0|1) >> -- the class form. Valid from the
moment the storage class is loaded, needs no storage object, and is tier 2, so
it is the right form for a deployment-wide setting.

=item *

C<< $storage->set_use_dbms_capability('_use_X', 0|1) >> and
C<< $storage->get_use_dbms_capability('_use_X') >> -- the two-argument form
underneath every C<_use_> accessor. Name-independent, so it works before the
rebless: the getter is on C<DBIO::Storage::DBI>'s driver-determination list
and reblesses first, the setter writes the tier-1 slot the driver's accessor
reads afterwards. C<undef> clears there too.

=back

Both accessors want a storage B<instance> for anything they have to determine.
A class-method call only ever succeeds where the value was declared outright in
tier 2, because everything else has to be determined from the connected
C<$dbh>. Asking a class for an undeclared capability therefore throws, naming
the capability.

=head1 CONTRACT VERSION

This class exposes an independent compatibility version, distinct from
C<$VERSION> (the dist version injected by L<Dist::Zilla>'s
C<VersionFromMainModule>):

    my $v = $class->contract_version;

C<$CONTRACT_VERSION> bumps when the capability-probing interface (the
C<_supports_*> / C<_use_*> accessors, the default capability list, or the
contract surface that drivers extend with new entries) changes. The dist
C<$VERSION> bumps on every release, but two core releases at the same contract
version remain wire-compatible. Out-of-tree drivers should record the contract
version they were last tested against and compare it against core's at load
time, warning (or strict-failing under C<DBIO_STRICT_CONTRACT>) when the shapes
have drifted. See F<docs/adr/> for the contract-version policy.

Version history of this class: 1.3 adds C<_adjust_bind_values>, the one seam
for adjusting values before they are bound, on both bind paths.

=head1 CAPABILITY LIST

The default capability set is the following. Drivers add their own with
C<< __PACKAGE__->mk_group_accessors(dbms_capability => '_supports_X') >>.

=over 4

=item C<insert_returning> / C<insert_returning_bound>

INSERT ... RETURNING support.

=item C<multicolumn_in>

Multi-column IN list optimisation.

=item C<placeholders> / C<typeless_placeholders>

Driver placeholder style.

=item C<join_optimizer>

Join-order hinting. On by default; not strictly a capability.

=item C<transactional_ddl> -- F02 / F10

True iff the engine runs DDL inside a normal transaction (i.e.
C<txn_do { do_ddl() }> is atomic). False if the engine forces an implicit
COMMIT on DDL (MySQL, Oracle, Sybase, Informix), depends on C<AutoCommit=on>
for in-place rebuilds (SQLite), or is capable but deliberately declines for
driver-specific reasons (DB2). L<DBIO::Deploy::Base> uses
this to decide whether to wrap a multi-statement DDL loop in
C<< $storage->txn_do >>; L<DBIO::DeploymentHandler> uses it to decide
whether the whole upgrade can run atomically. Drivers register their
engine value via C<< __PACKAGE__->_use_transactional_ddl(0|1) >> (in the
driver's storage class) or by defining C<_determine_supports_transactional_ddl>.

Its per-statement companion is the C<_ddl_statement_is_transactional> hook
below: the capability answers for the connection, the hook for the odd
statement that cannot be in a transaction anyway.

=item C<supports_if_exists> -- F12

True iff the engine / diff emitter can use C<IF [NOT] EXISTS> in DDL
(C<CREATE TABLE IF NOT EXISTS>, C<DROP TABLE IF EXISTS>,
C<ALTER TABLE ... ADD COLUMN IF NOT EXISTS>). False on engines that do
not parse the syntax (older MySQL / MariaDB before 10.0.2, some SQLite
builds, others). L<DBIO::Diff::Op::should_emit_if_exists> probes this
to decide whether to emit guarded DDL. Drivers register their engine
value via C<< __PACKAGE__->_use_supports_if_exists(0|1) >> or by defining
C<_determine_supports_supports_if_exists>.

=item C<supports_upsert> -- ADR 0036

True iff the engine has a single-statement, server-side atomic upsert that
rides on C<INSERT> (PostgreSQL / SQLite C<ON CONFLICT ... DO UPDATE|NOTHING>,
MySQL C<ON DUPLICATE KEY UPDATE>) B<and> the driver's
L<DBIO::SQLMaker> subclass implements the C<on_conflict> option of
C<< sql_maker->insert >>. False everywhere by default -- including on
engines whose upsert is a C<MERGE> statement (Oracle, DB2, SQL Server),
which is a different statement shape and not covered by this capability.

L<DBIO::ResultSet/upsert> probes this and throws when it is false; it never
degrades silently to a client-side read-then-write. Drivers register their
engine value via C<< __PACKAGE__->_use_supports_upsert(0|1) >> or by defining
C<_determine_supports_supports_upsert> (version-gated, as PostgreSQL does for
C<insert_returning>).

B<MERGE-based upsert is a deliberate, permanent non-goal -- not an oversight.>
The exclusion of the C<MERGE> engines (Oracle, DB2, SQL Server) above is a
decision, not an accident of the default C<0>: they stay without C<<
$rs->upsert >> under this capability for good, because C<MERGE> is a different
feature rather than a driver nobody has written yet. Two structural facts say
so:

=over 4

=item *

B<Two correlation names, one vocabulary.> This API's condition vocabulary
(L<DBIO::ResultSet/upsert>'s C<update_where>) names the B<stored> row with a bare
column and the B<attempted> row with C<< { -attempted => $col } >>, and that is
unambiguous only because an C<INSERT ... ON CONFLICT> has exactly one target
correlation plus the one C<EXCLUDED> pseudo-row. A C<MERGE> has B<two> named
sides -- source and target -- so the stored side comes out unqualified and
ambiguous. Covering it would need a second, symmetric qualifier this vocabulary
does not have.

=item *

B<The identity guarantee does not carry.> ADR 0036's rule that a driver may
declare C<supports_upsert> only if it can B<prove> which row it wrote rests, for
the INSERT-borne engines, on an insert having happened (C<RETURNING>, or the
engine's insert-identity channel). When a C<MERGE> takes its C<UPDATE> branch
there was no insert and no generated key -- verbatim the SQLite-below-3.35
failure mode ADR 0036 rejects as "silent bad data, worse than C<undef>". The
guarantee must be re-derived for C<MERGE>, not inherited.

=back

A future C<MERGE> upsert therefore needs its B<own> capability
(C<supports_merge_upsert> or the like) with guarantees reasoned from scratch --
never a widening of this flag or a second alias bolted onto this vocabulary. See
ADR 0036 for the full rationale.

=item C<supports_upsert_where> -- ADR 0036

True iff the driver renders the B<conditional> conflict branch --
C<DO UPDATE SET ... WHERE ...>, the C<where> key of the C<on_conflict>
structure, reachable as L<DBIO::ResultSet/upsert>'s C<update_where> option.
PostgreSQL and SQLite have the grammar; MySQL has no equivalent
(C<ON DUPLICATE KEY UPDATE> takes no C<WHERE>, and a per-column C<IF()> does
not suppress the write). Implies nothing on its own: it is only ever consulted
together with C<supports_upsert>.

This is the one dialect difference that gets a flag of its own, and the reason
is that it is the only one a driver can ignore B<silently>. Dropping the
conflict target emits invalid SQL on PostgreSQL, ignoring C<< action =>
'nothing' >> leaves no set to write -- those announce themselves. Dropping the
C<WHERE> produces a perfectly valid unconditional C<UPDATE>, i.e. the
last-write-wins overwrite the condition was written to prevent. Default C<0>
therefore keeps every driver that has never heard of the option correct, and
core throws instead of handing it one.

B<Answer about the branch itself; never derive the answer from
C<supports_upsert>.> The two flags earn their keep by answering two different
questions, so a flag that always repeats the other one carries no information at
all -- and deriving it also imports whatever the other gate happens to require
for its own reasons. PostgreSQL's C<supports_upsert>, for one, additionally
demands C<INSERT ... RETURNING>, because that is what proves the row handed back
is the row that was written; a condition that does not hold writes no row B<by
design>, so folding that requirement in here would make this flag report a
limitation the conditional branch does not have. Nor is a second C<0> any help
diagnostically: core probes C<supports_upsert> first and throws there, so a
driver gated off for an unrelated reason is already named by the right gate,
with that gate's message.

The legitimate uses of C<_determine_supports_supports_upsert_where> are the ones
that still measure the branch: an engine whose B<own> support for the
conditional clause is version-dependent, which is the same fact, probed. What is
not an input to this answer is anything the branch does not depend on --
C<RETURNING>, the identity transport, connection state. Drivers register their
engine value via C<< __PACKAGE__->_use_supports_upsert_where(0|1) >> where it is
a static fact, or as a C<_determine_supports_supports_upsert_where> where it has
to be probed; both leave the C<_use_> B<force> to the caller, because the
class-level declaration and the per-storage force are different slots
(L</Clearing a force>). For PostgreSQL and SQLite the rule yields an
unconditional yes: C<ON CONFLICT> arrived complete on either engine
(PostgreSQL 9.5, libsqlite 3.24), C<WHERE> included, so neither has a version
that speaks the conflict grammar but not the condition.

=item C<supports_exists_query> -- ADR 0037

True iff the storage can render a boolean-valued C<EXISTS> query this engine
accepts -- either because the base rendering of
L<DBIO::Storage::DBI/_exists_value_sql> is right for it
(C<SELECT CASE WHEN EXISTS E<lt>innerE<gt> THEN 1 ELSE 0 END>, correct on
PostgreSQL, MySQL/MariaDB, SQLite, DuckDB, SQL Server and Sybase), or because
the driver overrode that hook with the spelling its engine needs (Oracle
C<FROM DUAL>, DB2 C<FROM SYSIBM.SYSDUMMY1>, Firebird C<FROM RDB$DATABASE>).

L<DBIO::ResultSet/results_exist>, L<DBIO::ResultSet/results_exist_async> and
L<DBIO::ResultSet/results_exist_as_query> probe this and throw when it is
false; they never
degrade silently to L<DBIO::ResultSet/has_rows>, which is the portable
alternative the exception names. False everywhere by default: the flag is not
vacuous for a driver that does not override the hook, because it asserts that
somebody B<checked> -- and the engines nobody has checked are exactly the ones
a default-on would ship broken SQL to. Drivers register their engine value via
C<< __PACKAGE__->_use_supports_exists_query(0|1) >> or by defining
C<_determine_supports_supports_exists_query>.

=back

=head1 PER-STATEMENT DDL SAFETY

=head2 _ddl_statement_is_transactional

    sub _ddl_statement_is_transactional {
      my ($self, $stmt) = @_;
      return 0 if $stmt =~ /^\s*ALTER \s+ TYPE \b .* \b ADD \s+ VALUE \b/xi;
      return 1;
    }

Asked once per DDL statement by L<DBIO::Deploy::Base/_execute_ddl>, but only
on a storage that already reports C<transactional_ddl>. Answer false for a
statement this engine refuses to run inside a transaction, or runs but leaves
unusable until commit.

C<_execute_ddl> groups consecutive statements by this answer and keeps the
original order: each run of transaction-safe statements gets one
C<< $storage->txn_do >>, and a statement that answered false runs on its own,
outside any transaction. A batch where everything answers true produces a
single run and is therefore identical to bracketing the whole loop, which is
why a driver that never defines this hook sees no change at all.

The default is true, and overriding it is a deliberate act with a cost: the
batch is no longer one transaction, so a failure does not take the whole
upgrade back, and core announces the split once. Only define it where the
engine leaves no choice. The known case is PostgreSQL's
C<ALTER TYPE ... ADD VALUE>, rejected outright in a transaction block before
server 12 and, from 12 on, accepted while the new value stays unusable until
that transaction commits.

Match on the statement text with care — it is the DDL your own driver emits,
not arbitrary user SQL, so anchoring on the forms your DDL and diff classes
actually produce is both sufficient and safer than a broad pattern.

=head1 DDL SPLITTING

=head2 _ddl_sql_dialect

    sub _ddl_sql_dialect { 'postgresql' }

Names the SQL dialect the engine's DDL is written in, for the one reader that
must know it: the splitter L<DBIO::SQL::Util/_split_statements> that
L<DBIO::Deploy::Base/_execute_ddl> (and, for the async deploy,
C<< DBIO::Storage::Async >>) cuts install and upgrade DDL with. The text of a
statement does not say which dialect it is in, and one place -- the backslash
in a string literal -- reads differently: a character in standard SQL
(PostgreSQL, SQLite), an escape in MySQL and MariaDB. Left to guess, the
splitter takes both readings, which cuts a literal that ends on a backslash
in front of a later literal with a semicolon. The engine knows; this hook is
how it says so.

Allowed values: C<postgresql>, C<sqlite>, C<mysql> (MariaDB declares
C<mysql>), C<oracle> (a PL/SQL unit is one statement that keeps the semicolon
behind its C<END>). The default is C<undef>, "not declared", which leaves the splitter
exactly as it was: both readings. An unknown name makes the splitter throw, so
a typo is loud instead of silently reading the wrong way.

It is a fact about the engine like C<transactional_ddl> and
L</_ddl_statement_is_transactional>, which is why it lives on the storage and
not on a deploy class: the sync deploy reaches it through
C<< $schema->storage >>, the async deploy through its owner storage, and both
end in the same answer. Define it once on the driver's base storage class.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
