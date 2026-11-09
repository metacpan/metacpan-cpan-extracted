use strict;
use warnings;
use Test::More;

# F02 / F10 -- the transactional_ddl capability DBIO::Sybase::Storage::ASE
# declares, and the deploy path it steers.
#
# Fully offline: no DSN, no server, no DBIO_TEST_* anything. The declaration is
# a class-level fact by construction (that is the whole argument for it -- ASE
# answers this question per database, via the `ddl in tran` option, and a
# capability has to answer before any connection), and the behavioural half
# below drives core's real DBIO::Deploy::Base::_execute_ddl over a recording
# handle.
#
# Asserting the VALUE alone would sample almost nothing. On a storage INSTANCE
# core's own _determine_supports_transactional_ddl answers 0 as well, so an
# undeclared driver reads identically; as a CLASS method an undeclared
# capability happens to die rather than answer 0, but that is a mechanism of
# core's accessor, not the property this file is about. The get_inherited
# assertions are the direct probe: get_inherited is defined only for a value
# the class set itself -- which is why they come first below, and why the
# value assertion after them is guarded.

use_ok 'DBIO::Sybase::Storage';
use_ok 'DBIO::Sybase::Storage::ASE';
use_ok 'DBIO::Sybase::Deploy';
use_ok 'DBIO::Sybase::Diff';

# --- the declaration --------------------------------------------------------
#
# Declaredness before value, deliberately. get_inherited reads the declaration
# slot directly and cannot throw, so a regression here reports itself as a
# readable `not ok` with its diagnosis. The value accessor can throw (see
# below), and asking it first means a driver that stopped declaring aborts the
# file before the two assertions that actually name what went wrong ever run.

isnt(DBIO::Sybase::Storage::ASE->get_inherited('_use_transactional_ddl'), undef,
  'the driver states transactional_ddl itself, rather than inheriting core\'s '
. 'default');

# The base must stay silent. DBIO::Sybase::Storage is the shared base, and DBIO::MSSQL::Storage::Sybase inherits from it AHEAD of
# DBIO::MSSQL::Storage in the C3 linearisation -- so a declaration here would
# answer for Microsoft SQL Server too, whose DDL is transactional, and would
# shadow any declaration dbio-mssql makes later. Asked through get_inherited
# because the accessor itself dies for a class invocant with nothing declared,
# which is the answer we want but for the wrong reason.
is(DBIO::Sybase::Storage->get_inherited('_use_transactional_ddl'), undef,
  'the shared DBD::Sybase base declares nothing -- the answer belongs to '
. 'the ASE subclass, not to a base MSSQL also inherits');

# ... and now what it declares. Through eval, which is not ceremony here: asked
# as a class method, an UNdeclared capability makes core throw rather than
# answer 0 -- get_dbms_capability refuses to determine a capability without an
# instance whose $dbh it can probe. That throw is correct, but letting it
# escape would end the file here and take the twenty behavioural assertions
# below with it, so it is caught and reported as an ordinary failure.
my ($declared, $err);
{
  local $@;
  $declared = eval { DBIO::Sybase::Storage::ASE->_use_transactional_ddl };
  $err = $@;
}
unless (is($declared, 0,
  'transactional_ddl is 0 -- ASE rejects DDL in a multi-statement transaction '
. 'unless `ddl in tran` was turned on for that database, which is off by default'))
{
  diag "the capability accessor threw instead of answering: $err" if $err;
}

# --- what the declaration steers -------------------------------------------
#
# Real DDL from this driver's own diff, through core's real _execute_ddl, over
# a storage instance built without a server (the idiom t/22 already uses) and
# a handle that only records. Three runs against one storage:
#
#   1. the class declaration answering       -> no bracket
#   2. the capability forced true (tier 1)   -> exactly one txn_do bracket
#   3. the force cleared with undef          -> back to the declaration
#
# Run 2 is the counterfactual: it shows this value is what decides whether ASE
# would be handed DDL inside a transaction, i.e. that the declaration is
# load-bearing rather than decorative. Run 3 additionally pins that clearing a
# per-storage force falls through to the class declaration instead of leaving
# a tombstone that lands on core's default.

my $source = {
  tables       => { author => { table_name => 'author', kind => 'table' } },
  columns      => { author => [ { column_name => 'id', data_type => 'integer',
                                  not_null => 1, is_pk => 1 } ] },
  indexes      => { author => { author_idx => { index_name => 'author_idx',
                                                is_unique => 0,
                                                columns   => ['id'] } } },
  foreign_keys => {},
};
my $target = {
  tables       => { author => { table_name => 'author', kind => 'table' },
                    book   => { table_name => 'book',   kind => 'table' } },
  columns      => { author => [ { column_name => 'id', data_type => 'integer',
                                  not_null => 1, is_pk => 1 },
                                # default_value is fixture detail, not the
                                # property under test -- but it has to be here:
                                # ASE requires a default clause on a not-null
                                # ADD, so DBIO::Sybase::Diff::Column refuses to
                                # render one without it (karr k39). What this
                                # file asserts about `name` is only that its
                                # ADD is emitted, and in order.
                                { column_name => 'name', data_type => 'varchar',
                                  size => 24, not_null => 1,
                                  default_value => '' } ],
                    book   => [ { column_name => 'id', data_type => 'integer',
                                  not_null => 1, is_pk => 1 } ] },
  indexes      => { author => { author_idx => { index_name => 'author_idx',
                                                is_unique => 1,
                                                columns   => ['id'] } } },
  foreign_keys => {},
};

my $diff = DBIO::Sybase::Diff->new(source => $source, target => $target);
ok($diff->has_changes, 'the diff has DDL to apply');

{
  package TxnDdl::Dbh;
  sub new { bless { AutoCommit => 1, log => [] }, shift }
  sub do  { my ($self, $sql) = @_; push @{ $self->{log} }, $sql; 1 }
}
{
  package TxnDdl::Schema;
  sub new     { bless { storage => $_[1] }, $_[0] }
  sub sources { () }
  sub storage { $_[0]{storage} }
}

my $storage = DBIO::Sybase::Storage::ASE->new;
my $dbh     = TxnDdl::Dbh->new;
$storage->_dbh($dbh);   # _execute_ddl only brackets a handle the storage owns
my $deploy  = DBIO::Sybase::Deploy->new(schema => TxnDdl::Schema->new($storage));

my @brackets;   # one entry per txn_do, holding how much had run when it opened

# Observing the bracket rather than performing it: core's contract is
# $storage->txn_do(sub { ... }), and the real one would try to connect.
no warnings 'redefine', 'once';
local *DBIO::Sybase::Storage::ASE::txn_do = sub {
  my ($self, $code) = @_;
  push @brackets, { ran_before => scalar @{ $dbh->{log} } };
  $code->();
  $brackets[-1]{ran_after} = scalar @{ $dbh->{log} };
  return 1;
};

sub run_ddl {
  @brackets = ();
  @{ $dbh->{log} } = ();
  my @warnings;
  {
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $deploy->_execute_ddl($dbh, $diff->as_sql);
  }
  return (\@warnings, [ @{ $dbh->{log} } ]);
}

# 1. the declaration answering
my ($warned, $plain) = run_ddl();

is(scalar @brackets, 0,
  'declared 0: the DDL loop is not bracketed in txn_do');
ok(scalar @$plain >= 2,
  '... the statements ran anyway, straight onto the handle');
like(join("\n", @$plain), qr/CREATE \s+ TABLE \s+ book .*
                             ALTER  \s+ TABLE \s+ author \s+ ADD \s+ name .*
                             DROP   \s+ INDEX .*
                             CREATE \s+ UNIQUE \s+ INDEX/xis,
  '... in dependency order, as the diff rendered them');
like(join('', @$warned), qr/non-transactional DDL on DBIO::Sybase::Deploy/,
  '... and core says once that this deploy is not atomic -- a true statement '
. 'about ASE, not a defect to silence');

# 2. the counterfactual: force the capability true on this storage
$storage->_use_transactional_ddl(1);
is($storage->_use_transactional_ddl, 1, 'per-storage force takes effect');

my (undef, $bracketed) = run_ddl();

is(scalar @brackets, 1,
  'forced true: core brackets the whole batch in one txn_do -- on a default '
. 'ASE that is the transaction the server would refuse the DDL inside of');
is($brackets[0]{ran_before}, 0, '... opened before the first statement');
is($brackets[0]{ran_after}, scalar @$bracketed,
  '... and closed after the last one');
is_deeply($bracketed, $plain,
  '... over byte-identical SQL: the capability moves the bracket, not the DDL');

# 3. clearing the force hands the question back to the class declaration
$storage->_use_transactional_ddl(undef);
is($storage->_use_transactional_ddl, 0,
  'clearing the force falls through to the declaration, not to a tombstone');

my (undef, $again) = run_ddl();
is(scalar @brackets, 0, '... and the loop is unbracketed again');
is_deeply($again, $plain, '... running the same statements as the first pass');

# --- the temp database is out of this question entirely ---------------------
#
# ASE forbids CREATE DATABASE and DROP DATABASE inside a transaction
# unconditionally -- not even `ddl in tran` lifts that -- but the capability is
# not what protects them: they never reach _execute_ddl. This pins the claim
# the Deploy POD makes, so that "let's route these through _execute_ddl like
# everything else" cannot land quietly.
{
  my $temp_dbh = TxnDdl::Dbh->new;
  # karr k96: the handle comes with AutoCommit, as core hands it; one without
  # is refused (t/100-temp-db-autocommit.t), no longer committed.
  my @autocommit_at_do;
  my %option_set;   # databases sp_dboption was run on

  my $executed_ddl = 0;
  no warnings 'redefine', 'once';
  local *DBIO::Sybase::Deploy::_execute_ddl = sub { $executed_ddl++; 1 };
  local *TxnDdl::Dbh::do = sub {
    my ($self, $sql) = @_;
    push @{ $self->{log} }, $sql;
    push @autocommit_at_do, $self->{AutoCommit};
    $option_set{$1} = 1
      if $sql =~ /^EXEC \s+ sp_dboption \s+ '(\w+)', \s* 'abort \s tran \s on \s log \s full', \s* true$/xi;
    1;
  };
  # karr k46 brackets both statements in USE master / USE <original>, which
  # asks the handle for its current database first (db_name()). karr k69 asks
  # it once more whether the temp database has its option (status2 & 1 in
  # master..sysdatabases); the stub answers that one truthfully -- true only
  # for a database sp_dboption was run on -- and refuses any other query.
  # sp_dboption is one more statement of the log below that has to have run
  # under AutoCommit (the server refuses it in a transaction, Msg 17260).
  local *TxnDdl::Dbh::selectrow_array = sub {
    my ($self, $sql) = @_;
    return 'testdb' if $sql =~ /^\s*SELECT\s+db_name\(\)\s*$/i;
    return (16384, 1536, 850) if $sql =~ /^SELECT \@\@maxpagesize/;   # karr k69 part B: model
    if (my ($asked_of) = $sql =~ /^SELECT status2 & 1 FROM master\.\.sysdatabases WHERE name = '(\w+)'$/) {
      return $option_set{$asked_of} ? 1 : 0;
    }
    die "unexpected query: $sql";
  };

  my $name = $deploy->_create_temp_db($temp_dbh);
  $deploy->_drop_temp_db($temp_dbh, $name);

  # RESPELLED (karr k46), claims unchanged: the log used to be exactly
  # COMMIT, CREATE, DROP at positions 0..2. The USE master / USE <original>
  # bracket around each statement (pinned in t/43-deploy-temp-db-context.t)
  # moved CREATE and DROP to other positions, so they are found by content;
  # what is asserted about them -- committed first, both present, both under
  # AutoCommit -- is what it was, except the first claim (k96).
  my @log = @{ $temp_dbh->{log} };
  my ($create_at) = grep { $log[$_] =~ /^CREATE \s+ DATABASE \s+ \Q$name\E (?: \s+ ON \s+ default \s* = \s* '\d+M' )? $/xi } 0..$#log;
  my ($drop_at)   = grep { $log[$_] =~ /^DROP \s+ DATABASE \s+ \Q$name\E$/xi } 0..$#log;

  is($executed_ddl, 0,
    'CREATE/DROP DATABASE bypass _execute_ddl -- the capability never sees them');
  ok(!(grep { /^COMMIT$/i } @log),
    'no COMMIT is sent: the methods end no transaction of the handle (karr k96)');
  ok(defined $create_at, 'the temp database is created ...');
  ok(defined $drop_at && $drop_at > ($create_at // -1), '... and dropped');
  ok($option_set{$name}, 'abort tran on log full is set on the temp database (sp_dboption)');
  ok(@autocommit_at_do > 0, 'statements were sent');
  is_deeply([ @autocommit_at_do ], [ (1) x @autocommit_at_do ],
    'every statement runs under the AutoCommit the handle came with');
  is($temp_dbh->{AutoCommit}, 1, '... which is left as it was');
}

done_testing;
