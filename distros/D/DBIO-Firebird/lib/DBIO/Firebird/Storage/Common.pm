package DBIO::Firebird::Storage::Common;
# ABSTRACT: Shared Firebird / InterBase storage logic

use strict;
use warnings;

our $VERSION = '0.900004';

use base qw/DBIO::Storage::DBI/;
use mro 'c3';

use DBIO::Firebird::Util qw(mask_error_details);


__PACKAGE__->_use_insert_returning (1);
__PACKAGE__->sql_quote_char ('"');
__PACKAGE__->sql_maker_class ('DBIO::Firebird::SQLMaker');

sub sqlt_type {
  return 'Firebird';
}


# ADR 0037 -- the complete 1/0 statement behind DBIO::ResultSet::results_exist
# and its two siblings. Core's base rendering has no FROM clause at all, and
# Firebird has no FROM-less SELECT; RDB$DATABASE is the one-row system table
# that makes it a legal statement here. Only the dummy table is ours -- the
# CASE spelling stays core's, so there is one copy of it.
#
# The literal is single-quoted on purpose: in a double-quoted string $DATABASE
# interpolates as an (empty) global and the statement silently becomes
# "FROM RDB", which parses as a table reference and fails far from here.
sub _exists_value_sql {
  my $self = shift;
  return $self->next::method(@_) . ' FROM RDB$DATABASE';
}

# ... and the capability that lets core call the above at all. Not vacuous
# next to the override: it is this driver asserting that somebody checked the
# rendering against Firebird, which is why the default is 0 and why declaring
# is a separate act from overriding.
__PACKAGE__->_use_supports_exists_query (1);

# F02 / F10 -- transactional DDL, and the one capability in this file whose
# value is NOT the engine's answer. Firebird HAS transactional DDL: metadata
# lives in ordinary MVCC records in the rdb$ system tables, a DDL statement
# stays in the user transaction until that transaction ends, and a ROLLBACK
# takes it back. That is not inferred -- it is the whole reason isql carries
# SET AUTODDL, whose default ON exists to commit each DDL statement as it runs
# and whose OFF (isql -n) hands DDL back to the transaction (Firebird 5.0 isql
# manual, "Transaction Handling" and "SET AUTOddl"). Core's own
# DBIO::Deploy::Base lists this engine in its transactional set.
#
# The 0 below is this driver declining to promise the ATOMICITY of a bracketed
# batch, which is a narrower claim than "the engine has transactional DDL" and
# the only claim DBIO::Deploy::Base::_execute_ddl actually acts on. Three
# things stand between the engine fact and that promise, and none of them could
# be settled here: nothing in this distribution has ever run against a Firebird
# server (t/10, t/15, t/17, t/20, t/30 all need DBIO_TEST_FIREBIRD_DSN), so
# every claim below is documentation plus the shipped DBD binary, never a
# measurement.
#
# 1. The diff emits a same-name DROP/CREATE PAIR that a bracket would put in
#    one transaction. DBIO::Firebird::Diff::Index turns a changed index into
#    DROP INDEX "n" followed by CREATE INDEX "n" -- the same name, adjacent in
#    the batch. Today a real COMMIT separates them, because each statement runs
#    on its own. Under one txn_do the re-CREATE stores an rdb$indices row whose
#    rdb$index_name duplicates one this transaction has deleted but not
#    committed, and Firebird enforces that name through its own unique index
#    rdb$index_5 with "visible to active transactions" semantics -- the
#    spelling of the error is literally "attempt to store duplicate value
#    (visible to active transactions) in unique index RDB$INDEX_5" (the shape
#    is documented for a plain duplicate index name; whether an uncommitted
#    self-delete also counts as visible is exactly what needs a server).
#    What makes this decisive rather than merely unknown is that it is a
#    constraint on a PAIR. The _ddl_statement_is_transactional hook next door
#    is per statement: it can say "this statement may not be inside a
#    transaction", it cannot say "these two may not be inside the SAME one".
#    Answering false for DROP INDEX would split the pair by accident while
#    stating something untrue about the statement, and would take index drops
#    out of the atomic batch anyway -- i.e. pay the price the 1 was for.
#
# 2. CREATE INDEX does its work at COMMIT, not at the statement. Firebird 5.0
#    Language Reference, ALTER INDEX: "if our ALTER INDEX succeeds and starts
#    to rebuild the index at COMMIT, other transactions modifying that table
#    will fail or wait, according to their WAIT/NO WAIT attributes. The
#    situation is the same for CREATE INDEX." (Unchanged from the 2.5
#    reference, so this is not version-bounded.) Bracketing the batch moves
#    every index build in it onto the single commit at the end: a failing
#    CREATE UNIQUE INDEX then surfaces from the commit rather than from the
#    statement that caused it, and concurrent writers to those tables are held
#    against for the length of the whole deploy instead of one statement.
#
# 3. The DBD half, which is where the family's DuckDB finding applies here: the
#    engine may manage it and the transport still not. This driver TELLS users
#    to switch on ib_softcommit (see DBIO::Firebird::Storage::InterBase and its
#    CAVEATS -- without it a commit closes the cursors still open on the
#    connection), and this repo's own live tests set it for both
#    native DSNs. ib_softcommit makes DBD::Firebird use isc_commit_retaining
#    AND isc_rollback_retaining -- both are undefined symbols of the shipped
#    DBD::Firebird 1.39 object, next to the strings "try isc_commit_retaining",
#    "try isc_rollback_retaining" and "dbd_db_STORE: switch ib_softcommit from
#    %d to %d"; its own POD says soft commit "retains the internal transaction
#    handle". Firebird 5.0 Language Reference, COMMIT and ROLLBACK: RETAIN
#    means "the transaction is committed, but some server resources are
#    retained and a new transaction is restarted transparently with the same
#    Transaction ID", and for the rollback "although all work of the
#    transaction is to be rolled back, the transaction context is to be
#    retained". So on the transport this driver recommends, the COMMIT that
#    would close a bracketed DDL batch and the ROLLBACK that would take it back
#    are both retaining calls that deliberately do not end the transaction.
#    Nothing today depends on that, because nothing ever rolls DDL back; a 1
#    would make recovery depend on isc_rollback_retaining undoing a batch of
#    METADATA changes, which no documentation covers. Jaybird, the official
#    Firebird JDBC driver, declines to use commit retaining "during normal
#    execution" at all.
#
# Supporting rather than deciding: the engine's own history says several DDL
# statements in one transaction is not the well-trodden path here. Firebird
# release notes: "Database corruption could occur if two different indexes on a
# table were dropped within the same transaction" (CORE-2397 / CORE-2359, fixed
# 2.1.1 / 2.5.6 -- and a diff routinely drops several indexes off one table);
# "Problems could occur if further DDL commands were issued in the same
# transaction following a CREATE COLLATION command" (CORE-3056); "SET AUTODDL
# OFF and sequence of CREATE + ALTER + DROP VIEW would lead to a server crash"
# (CORE-5107, fixed 3.0.3); FirebirdSQL/firebird#8801, still open against 5.0.x,
# is database corruption reached with set autoddl OFF. Those particular ones are
# fixed; the pattern is why SET AUTODDL ON is the default in the first place.
#
# The price of the 0 is core's one-time non-transactional-DDL notice and a
# batch that is not atomic: an apply that fails part way leaves the earlier
# statements applied. Re-running upgrade is safe -- the diff is recomputed
# against live state, so the second run picks up only what is left.
#
# The flip condition is concrete, not a promise. On a live server, check (1)
# whether DROP INDEX "n" + CREATE INDEX "n" survives one transaction, and (3)
# whether a txn_do rollback under ib_softcommit really takes a batch of rdb$
# changes back. If both hold, this becomes 1 and the notice goes away. If only
# (1) fails, the honest fix is in DBIO::Firebird::Diff::Index -- rename through
# a distinct index name so the batch no longer contains the pair -- not in the
# per-statement hook, which cannot express the constraint.
#
# Level: this sits on Storage::Common, so all three transports inherit it.
# Reasons 1 and 2 are facts about this engine and about the DDL these shared
# Diff/DDL classes emit, and they reach DBD::Firebird, DBD::InterBase and
# DBD::ODBC alike (ADR 0010's cut: engine facts go here). Reason 3 is a fact
# about the two native DBDs only and needs no declaration of its own, since it
# can only push the answer further towards the conservative value this already
# is. If this ever flips, DBIO::Firebird::Storage::ODBC is where it could flip
# first, and that would be the moment to split the declaration.
__PACKAGE__->_use_transactional_ddl (0);

# ADR 0039 -- the keyword DBIO::ResultSet joins the operands of a set
# operation with, or the refusal when this engine has no such operation.
# Firebird has UNION and UNION ALL and nothing else: EXCEPT, INTERSECT and
# MINUS are absent from the <query-expression> grammar and from the complete
# keyword list of the Firebird 5.0 Language Reference alike, and
# FirebirdSQL/firebird#1194 has asked for them since 2004 without being
# implemented. Refusal is unconditional rather than version-gated -- see the
# DESCRIPTION for why that costs nothing here, unlike on Oracle. The two
# operations we do have fall through to core's base map, which spells them
# UNION and UNION ALL.
my %UNSUPPORTED_SET_OPERATION = map { $_ => 1 }
  qw(intersect intersect_all except except_all);

sub _set_operation_keyword {
  my ($self, $op) = @_;

  $self->throw_exception(
    "Firebird cannot express the set operation '$op': UNION and UNION ALL are "
  . 'the only set operators in the language -- EXCEPT, INTERSECT and MINUS are '
  . 'not keywords of this engine at all (Firebird 5.0 Language Reference, the '
  . '<query-expression> production and Appendix C; requested in '
  . 'FirebirdSQL/firebird#1194 since 2004, still open). InterBase is the same. '
  . 'The refusal is unconditional and covers every release: this hook chooses '
  . 'the keyword without a connection (ADR 0039 section 7), and no version has '
  . 'the operators anyway. There is no drop-in replacement, but set difference '
  . 'is expressible as a search with a NOT EXISTS subquery and intersection '
  . 'with EXISTS.'
  ) if defined $op and $UNSUPPORTED_SET_OPERATION{$op};

  return $self->next::method($op);
}

# ADR 0011 / karr k17 -- the function DBIO::ResultSet::rand drops into an
# ORDER BY literal. Core answers RANDOM(), which is right on PostgreSQL and
# SQLite and is not a function either of these engines has; the failure mode of
# inheriting it is loud, an unresolvable function name in the server's own
# error. Firebird spells it RAND() (internal since 2.1), and so does the ib_udf
# external function that covers everything older and InterBase -- one string
# for both engines and every version, which is why it sits on this class and
# not on either driver. See the DESCRIPTION for the sources, including the one
# for per-row evaluation: an engine that computed this once per statement would
# not error, it would answer the rows unshuffled.
sub _random_function { 'RAND()' }

sub _sequence_fetch {
  my ($self, $nextval, $sequence) = @_;

  $self->throw_exception("Can only fetch 'nextval' for a sequence")
    if $nextval !~ /^nextval$/i;

  $self->throw_exception('No sequence to fetch') unless $sequence;

  my ($val) = $self->_get_dbh->selectrow_array(sprintf
    'SELECT GEN_ID(%s, 1) FROM rdb$database',
    $self->sql_maker->_quote($sequence)
  );

  return $val;
}

sub _dbh_get_autoinc_seq {
  my ($self, $dbh, $source, $col) = @_;

  my $table_name = $source->from;
  $table_name    = $$table_name if ref $table_name;
  $table_name    = $self->sql_maker->quote_char ? $table_name : uc($table_name);

  local $dbh->{LongReadLen} = 100000;
  local $dbh->{LongTruncOk} = 1;

  my $sth = $dbh->prepare(<<'EOF');
SELECT t.rdb$trigger_source
FROM rdb$triggers t
WHERE t.rdb$relation_name = ?
AND t.rdb$system_flag = 0 -- user defined
AND t.rdb$trigger_type = 1 -- BEFORE INSERT
EOF
  $sth->execute($table_name);

  while (my ($trigger) = $sth->fetchrow_array) {
    my @trig_cols = map
      { /^"([^"]+)/ ? $1 : uc($_) }
      $trigger =~ /new\.("?\w+"?)/ig
    ;

    my ($quoted, $generator) = $trigger =~
/(?:gen_id\s* \( \s* |next \s* value \s* for \s*)(")?(\w+)/ix;

    if ($generator) {
      $generator = uc $generator unless $quoted;

      return $generator
        if grep {
          $self->sql_maker->quote_char ? ($_ eq $col) : (uc($_) eq uc($col))
        } @trig_cols;
    }
  }

  return undef;
}

sub _exec_svp_begin {
  my ($self, $name) = @_;

  $self->_dbh->do("SAVEPOINT $name");
}

sub _exec_svp_release {
  my ($self, $name) = @_;

  $self->_dbh->do("RELEASE SAVEPOINT $name");
}

sub _exec_svp_rollback {
  my ($self, $name) = @_;

  $self->_dbh->do("ROLLBACK TO SAVEPOINT $name")
}

# http://www.firebirdfaq.org/faq223/
sub _get_server_version {
  my $self = shift;

  return $self->_get_dbh->selectrow_array(q{
SELECT rdb$get_context('SYSTEM', 'ENGINE_VERSION') FROM rdb$database
  });
}


sub _mask_error_values {
  my ($self, $text, $values, $statement) = @_;

  return $text unless defined $text and !ref $text;

  $text = mask_error_details($text, $values);
  return $self->next::method($text, $values, $statement);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Firebird::Storage::Common - Shared Firebird / InterBase storage logic

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

This class contains the shared logic for both Firebird and InterBase drivers.
It extends L<DBIO::Storage::DBI> directly to avoid unnecessary inheritance depth.

=head2 Existence queries

L<DBIO::ResultSet/results_exist> and its two siblings work here because this
class declares the C<supports_exists_query> capability (ADR 0037). Core
defaults that capability to C<0> and throws on all three methods without it,
rather than degrading silently to L<DBIO::ResultSet/has_rows> -- which stays
the portable alternative for callers that must also run against a driver which
has not declared it.

Declaring it alone would not be enough: core's base rendering of
L<DBIO::Storage::DBI/_exists_value_sql> is
C<SELECT CASE WHEN EXISTS E<lt>innerE<gt> THEN 1 ELSE 0 END>, a C<SELECT> with
no C<FROM> clause, and Firebird has no C<FROM>-less C<SELECT> at all. The
override appends C<FROM RDB$DATABASE> -- the one-row system table every
Firebird and InterBase database has, and the same one this class already
selects from for C<GEN_ID> and the engine version -- and leaves the C<CASE>
spelling to core, so there is one copy of it.

=head2 Set operations: C<UNION> only

Firebird has B<no set difference and no intersection>. C<UNION> and
C<UNION ALL> are the only set operators in the language, so four of the six
L<DBIO::ResultSet> set operations -- L<intersect|DBIO::ResultSet/intersect>,
L<intersect_all|DBIO::ResultSet/intersect_all>,
L<except|DBIO::ResultSet/except> and
L<except_all|DBIO::ResultSet/except_all> -- are B<refused> from
L<DBIO::Storage::DBI/_set_operation_keyword> with a typed exception, at
query-build time, before any operand SQL is rendered (ADR 0039). Before that
refusal existed they emitted keywords the engine has no token for and failed as
a syntax error several layers below the method the caller invoked.

Sourced rather than assumed:

=over 4

=item *

the C<E<lt>query-expressionE<gt>> production in the Firebird 5.0 Language
Reference is
C<E<lt>query-termE<gt> | E<lt>query-expressionE<gt> UNION [{ DISTINCT | ALL }] E<lt>query-termE<gt>>
-- one set operator, no alternatives;

=item *

Appendix C lists every Firebird 5.0 keyword, reserved and non-reserved, and
contains C<UNION> but neither C<EXCEPT> nor C<INTERSECT> nor C<MINUS>. The
tokens are not in the grammar at all, so this is not a missing feature behind a
compatibility switch;

=item *

L<https://github.com/FirebirdSQL/firebird/issues/1194> (tracker CORE808) has
requested C<INTERSECT> and C<EXCEPT> since 2004 and is still open, unmilestoned
and without a linked pull request;

=item *

the InterBase 2020 Language Reference documents C<[UNION [ALL] select_expr]>
and nothing else, which matters because L<DBIO::Firebird::Storage::InterBase>
inherits this refusal.

=back

The refusal is B<unconditional> and is not a version gate. ADR 0039 section 7
allows either an unconditional refusal or a class-level opt-in for a deployment
that knows its server, and forbids probing the server, because
L<DBIO::ResultSet/_set_operation> bakes the keyword into a literal C<from>
clause at construction time. Unconditional is the honest choice here and it
costs nothing, unlike Oracle's version-bounded C<MINUS ALL> gap: no released
Firebird or InterBase has ever had these operators, so there is no version
being withheld from. A class-level opt-in would be an opt-in for a server that
does not exist, and would let a deployment switch on SQL no engine parses. If
issue 1194 ever ships, the gap becomes version-bounded and the opt-in becomes
the right shape -- that is the falsification condition, not a promise.

=head2 Random ordering

L<DBIO::ResultSet/rand> orders by whatever
L<DBIO::Storage::DBI/_random_function> names. Core answers C<RANDOM()>, right
on PostgreSQL and SQLite and a function neither Firebird nor InterBase has at
all; the spelling here is C<RAND()>. It is overridden on this class rather than
on either driver because it is a fact about the SQL both engines speak, not
about either DBD.

Sourced rather than assumed:

=over 4

=item *

C<RAND()> is an B<internal> function of Firebird since 2.1 (Language Reference
Update 2.1, I<Internal functions>; unchanged in the Firebird 5.0 Language
Reference, I<Mathematical Functions>), returning a C<DOUBLE PRECISION> between
0 and 1. Appendix C of the 5.0 reference lists every keyword, reserved and
non-reserved, and contains no C<RANDOM> in any form;

=item *

before 2.1, and on InterBase, the same call is the C<ib_udf> B<external>
function, declared C<DECLARE EXTERNAL FUNCTION rand RETURNS DOUBLE PRECISION
BY VALUE ENTRY_POINT 'IB_UDF_rand' MODULE_NAME 'ib_udf'>. The name is C<RAND>
either way, which is why one override covers both engines and every version;
a database that declares the UDF shadows the internal function of the same
name (2.1 Language Reference Update), and the emitted SQL does not care which
of the two resolves it;

=item *

the value is re-evaluated B<per row>, which is the half worth checking rather
than assuming: an engine that computes it once per statement gives every row
the same sort key and answers with the rows unshuffled, in their natural
order, with no error to notice. Firebird does not do that. Dmitry Yemanov on
tracker CORE4362 (L<https://github.com/FirebirdSQL/firebird/issues/4684>),
where a user reports the opposite complaint -- that C<rand()>-derived values
differ on every reference -- answers: "This is an implementation detail.
Firebird does not materialize simple expressions." The one release where the
optimizer did fold such an expression away, 5.0 Beta 1 and RC 1, was treated
as a bug and fixed in 5.0 RC 2 (FirebirdSQL/firebird#7853, I<Do not consider
non-deterministic expressions as invariants in pre-filters>) -- and even there
the folding was in C<WHERE> pre-filters, not in the sort key
L<DBIO::ResultSet/rand> writes.

=back

B<Unverified:> no server was run for any of this. The documentation above is
the whole evidence, both for C<RAND()> being the spelling and for its per-row
evaluation; the live half of F<t/58-explain-query.t> is where a server checks
them.

=head2 Transactional DDL

This class declares C<< _use_transactional_ddl(0) >>, and that C<0> is B<not> a
statement about the engine. Firebird does have transactional DDL: metadata
lives in ordinary MVCC records in the C<rdb$> system tables, a DDL statement
stays in the user transaction until it ends, and a C<ROLLBACK> takes it back --
which is why C<isql> carries C<SET AUTODDL> at all, and why
L<DBIO::Deploy::Base> lists this engine in its transactional set.

What the declaration withholds is the narrower promise
L<DBIO::Deploy::Base/_execute_ddl> acts on: that this driver's whole DDL batch
may be bracketed in one C<< $storage->txn_do >> and be atomic. Three things
stand between the engine fact and that promise -- a same-name
C<DROP INDEX> / C<CREATE INDEX> pair in the diff, C<CREATE INDEX> doing its
work at C<COMMIT>, and C<ib_softcommit> turning both the commit and the
rollback into I<retaining> calls -- and none of them could be settled without a
server. The full reasoning, its sources and the condition that would flip the
value are in L<DBIO::Firebird::Deploy/Transactional DDL -- not claimed> and in
the comment on the declaration itself.

All three transports inherit it. F<t/42-deploy-transactional-ddl.t> pins the
value, pins that this class declared it rather than inheriting core's identical
default, and drives the counterfactual through C<_execute_ddl> in both
directions.

=head1 METHODS

=head2 sqlt_type

Returns C<Firebird>, identifying this storage to L<SQL::Translator>.

=head1 CAVEATS

=over 4

=item *

C<last_insert_id> support by default only works for Firebird versions 2 or
greater, L<auto_nextval|DBIO::ResultSource/auto_nextval> however should
work with earlier versions.

=back

=head2 Values in error text

Core sends every text an engine writes into an error through
L<DBIO::Storage::DBI/_mask_error_values>. The Firebird server quotes values
in two sentences -- C<Problematic key value is ("ID" = 7, "EMAIL" = 'x')> of a
PRIMARY KEY, UNIQUE or FOREIGN KEY violation and C<conversion error from
string "x"> -- also when the value was bound and is only a character long.
This class applies L<DBIO::Firebird::Util/mask_error_details> first and then
core's rule for the bound values, on all three transports. The type, the
column, the constraint, the table and the error code stay in the message; the
errstr of the handle is the DBI attribute and stays as the server wrote it.

=head1 SEE ALSO

=over

=item * L<DBIO::Firebird> - Firebird schema component

=item * L<DBIO::Firebird::Storage> - Firebird driver via L<DBD::Firebird>

=item * L<DBIO::Firebird::Storage::InterBase> - InterBase driver

=item * L<DBIO::Firebird::Storage::ODBC> - Firebird via L<DBD::ODBC>

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
