use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::Deploy::Base;
use DBIO::Diff::Base;
use DBIO::Admin;

# The deploy applies a diff only as far as its classification allows (ADR 0080):
# a refusal never runs, a destructive or possibly lossy operation runs only
# with allow_destructive, dry_run runs nothing. No database: the handle only
# records the statements it is given.

{
  package Guard::DBH;
  sub new { bless { stmts => [], AutoCommit => 1 }, shift }
  sub do { push @{ $_[0]{stmts} }, $_[1]; 1 }

  package Guard::Storage;
  sub new { bless { dbh => $_[1] }, $_[0] }
  sub dbh { $_[0]{dbh} }
  sub connect_info { [] }
  sub access_broker { undef }

  package Guard::Schema;
  sub new { bless { storage => $_[1] }, $_[0] }
  sub storage { $_[0]{storage} }

  package Guard::Op;
  sub new { my ($c, %a) = @_; bless {%a}, $c }
  sub action   { $_[0]{action} }
  sub summary  { $_[0]{summary} }
  sub as_sql   { $_[0]{sql} }
  sub replaced { $_[0]{replaced} }

  package Guard::LossyOp;
  our @ISA = ('Guard::Op');
  sub lossy { 1 }

  package Guard::Diff;
  our @ISA = ('DBIO::Diff::Base');
  sub _build_operations { $_[0]{ops} }

  package Guard::Deploy;
  our @ISA = ('DBIO::Deploy::Base');
  sub _ddl_class        { 'Guard::DDL' }
  sub _introspect_class { 'Guard::Introspect' }
  sub _diff_class       { 'Guard::Diff' }
  sub _build_target_model { {} }
  sub _introspect_current { {} }
  sub diff { Guard::Diff->new(ops => $_[0]{ops}) }
}

sub add_op   { Guard::Op->new(action => 'create', summary => '+table: users', sql => 'CREATE TABLE users (id int);') }
sub drop_op  { Guard::Op->new(action => 'drop',   summary => '-table: reports', sql => 'DROP TABLE reports;') }
sub type_op  { Guard::LossyOp->new(action => 'alter', summary => '~column: users.score', sql => 'ALTER TABLE users ALTER COLUMN score TYPE int;') }
sub refuse_op { Guard::Op->new(action => 'refuse', summary => '!table: users (case only)', sql => '-- refused') }

sub setup {
  my (@ops) = @_;
  my $dbh = Guard::DBH->new;
  my $deploy = Guard::Deploy->new(schema => Guard::Schema->new(Guard::Storage->new($dbh)), ops => \@ops);
  return ($deploy, $dbh);
}

# --- contract: the optional lossy method and destructive_operations ----------
{
  my $diff = Guard::Diff->new(ops => [ add_op(), drop_op(), type_op(),
    Guard::Op->new(action => 'drop', replaced => 1, summary => '-index: i', sql => 'DROP INDEX i;') ]);
  is_deeply [ map { $_->summary } $diff->destructive_operations ],
    [ '-table: reports', '~column: users.score' ],
    'destructive_operations: an unreplaced drop and a lossy operation, not a replaced drop';
  is $diff->classify->{class}, 'destructive', 'classify itself is unchanged';
}

# --- additive and changing diffs run without a release -----------------------
{
  my ($deploy, $dbh) = setup(add_op());
  ok $deploy->apply($deploy->diff), 'an additive diff runs';
  is scalar(@{ $dbh->{stmts} }), 1, '... and ran its statement';
}

# --- destructive: no release, nothing runs -----------------------------------
for my $case ([ drop => drop_op() ], [ lossy => type_op() ]) {
  my ($name, $op) = @$case;
  my ($deploy, $dbh) = setup(add_op(), $op);

  throws_ok { $deploy->apply($deploy->diff) } 'DBIO::Exception',
    "$name: apply without allow_destructive throws";
  like $@, qr/allow_destructive/, "$name: the message names the option";
  like $@, qr/\Q@{[ $op->summary ]}\E/, "$name: the message names the summary of the operation";
  unlike $@, qr/DROP TABLE|ALTER TABLE/, "$name: the message carries no SQL";
  is scalar(@{ $dbh->{stmts} }), 0, "$name: no statement ran, not even the additive one";

  throws_ok { $deploy->upgrade } 'DBIO::Exception', "$name: upgrade throws as well";
  is scalar(@{ $dbh->{stmts} }), 0, "$name: upgrade ran nothing";

  ok $deploy->apply($deploy->diff, allow_destructive => 1), "$name: argument releases the run";
  is scalar(@{ $dbh->{stmts} }), 2, "$name: both statements ran";

  my ($d2, $h2) = setup(add_op(), $op);
  $d2->allow_destructive(1);
  ok $d2->apply($d2->diff), "$name: the attribute releases the run";
  is scalar(@{ $h2->{stmts} }), 2, "$name: both statements ran";

  my ($d3, $h3) = setup(add_op(), $op);
  isa_ok $d3->upgrade(allow_destructive => 1), 'Guard::Diff', "$name: upgrade with the argument returns the diff";
  is scalar(@{ $h3->{stmts} }), 2, "$name: upgrade ran both statements";

  my ($d4, $h4) = setup($op);
  throws_ok { $d4->apply($d4->diff, allow_destructive => 0) } 'DBIO::Exception',
    "$name: an argument of 0 overrides the attribute";
  $d4->allow_destructive(1);
  throws_ok { $d4->apply($d4->diff, allow_destructive => 0) } 'DBIO::Exception',
    "$name: ... also over an attribute set to 1";
  is scalar(@{ $h4->{stmts} }), 0, "$name: nothing ran";
}

# --- refusals: never, with or without the release ----------------------------
{
  my ($deploy, $dbh) = setup(add_op(), refuse_op());
  throws_ok { $deploy->apply($deploy->diff, allow_destructive => 1) } 'DBIO::Exception',
    'a refusal throws with allow_destructive';
  like $@, qr/\Q!table: users (case only)\E/, '... and names the summary of the refusing operation';
  $deploy->allow_destructive(1);
  throws_ok { $deploy->apply($deploy->diff) } 'DBIO::Exception', '... also with the attribute';
  throws_ok { $deploy->upgrade(allow_destructive => 1) } 'DBIO::Exception', '... and in upgrade';
  is scalar(@{ $dbh->{stmts} }), 0, 'no statement ran';

  my ($d2, $h2) = setup(drop_op(), refuse_op());
  throws_ok { $d2->apply($d2->diff) } qr/case only/, 'a refusal beside a drop reports the refusal';
}

# --- dry_run -----------------------------------------------------------------
{
  my ($deploy, $dbh) = setup(add_op(), drop_op(), refuse_op());
  my $diff = $deploy->diff;
  my $seen = $deploy->apply($diff, dry_run => 1);
  is $seen, $diff, 'apply with dry_run returns the diff';
  like $seen->as_sql,  qr/DROP TABLE reports/, '... whose as_sql shows the statements';
  like $seen->summary, qr/-table: reports/,    '... and whose summary shows the operations';
  is scalar(@{ $dbh->{stmts} }), 0, 'dry_run ran nothing';

  my $up = $deploy->upgrade(dry_run => 1);
  isa_ok $up, 'Guard::Diff', 'upgrade with dry_run returns the diff';
  is scalar(@{ $dbh->{stmts} }), 0, 'upgrade dry_run ran nothing';

  my ($e, $eh) = setup();
  ok !$e->apply(Guard::Diff->new(ops => []), dry_run => 1), 'dry_run without changes returns false';
}

# --- unknown arguments, a diff that cannot classify --------------------------
{
  my ($deploy, $dbh) = setup(add_op());
  throws_ok { $deploy->apply($deploy->diff, allow_destructiv => 1) } qr/Unknown option 'allow_destructiv'/,
    'an unknown argument name throws, naming the name';
  throws_ok { $deploy->upgrade(bogus => 1) } qr/Unknown option 'bogus'/, '... in upgrade as well';

  {
    package Guard::PlainDiff;
    sub has_changes { 1 } sub as_sql { 'X;' } sub summary { 'x' }
  }
  throws_ok { $deploy->apply(bless {}, 'Guard::PlainDiff') } 'DBIO::Exception',
    'a diff that cannot classify is not applied';
  is scalar(@{ $dbh->{stmts} }), 0, '... and ran nothing';
}

# --- Admin upgrade: ask, force, dry-run, refusal -----------------------------
{
  package Guard::Admin;
  our @ISA = ('DBIO::Admin');
  our $DEPLOY;
  sub _native_deploy { $DEPLOY }
}

sub admin_for {
  my ($deploy, %args) = @_;
  $Guard::Admin::DEPLOY = $deploy;
  return Guard::Admin->new(schema => 1, %args);
}

{
  my $out = '';
  open my $fh, '>', \$out or die;
  my $old = select $fh;

  my ($deploy, $dbh) = setup(drop_op());
  {
    local *STDIN;
    open STDIN, '<', \"no\n" or die;
    is admin_for($deploy)->upgrade, 0, 'Admin upgrade without force and without YES does not run';
  }
  is scalar(@{ $dbh->{stmts} }), 0, '... nothing ran';

  ok admin_for($deploy, _confirm => 1)->upgrade, 'a confirmed upgrade runs';
  is scalar(@{ $dbh->{stmts} }), 1, '... its statement';

  my ($d3, $h3) = setup(drop_op());
  ok admin_for($d3, force => 1)->upgrade, 'force releases without asking';
  is scalar(@{ $h3->{stmts} }), 1, '... the statement ran';

  my ($d4, $h4) = setup(drop_op());
  ok admin_for($d4, dry_run => 1)->upgrade, 'dry_run returns the diff';
  is scalar(@{ $h4->{stmts} }), 0, '... and ran nothing';

  my ($d5, $h5) = setup(drop_op(), refuse_op());
  throws_ok { admin_for($d5, force => 1)->upgrade } qr/case only/, 'a refusal stops Admin upgrade, also with force';
  is scalar(@{ $h5->{stmts} }), 0, '... nothing ran';

  my ($d6, $h6) = setup(add_op());
  ok admin_for($d6)->upgrade, 'an additive upgrade needs no question';
  is scalar(@{ $h6->{stmts} }), 1, '... and ran';

  select $old;
  like $out, qr/-table: reports/, 'the question names the operation';
  like $out, qr/DROP TABLE reports/, 'dry_run prints the SQL';
}

# --- the two hooks of apply (ADR 0080) ---------------------------------------
{
  package Guard::Hooked;
  our @ISA = ('Guard::Deploy');
  our @LOG;
  sub _check_before_apply { push @LOG, 'check'; $_[0]->next::method($_[1]) }
  sub _execute_diff       { push @LOG, 'execute'; $_[1]->as_sql; return 1 }
}

{
  my $diff_ops = [ add_op(), drop_op() ];
  my $deploy = Guard::Hooked->new(schema => Guard::Schema->new(Guard::Storage->new(Guard::DBH->new)), ops => $diff_ops);

  @Guard::Hooked::LOG = ();
  throws_ok { $deploy->apply($deploy->diff) } 'DBIO::Exception', 'hooked: a destructive diff without release throws';
  is_deeply \@Guard::Hooked::LOG, [], '... before either hook ran';

  @Guard::Hooked::LOG = ();
  $deploy->apply($deploy->diff, dry_run => 1);
  is_deeply \@Guard::Hooked::LOG, [], 'hooked: dry_run runs neither hook';

  @Guard::Hooked::LOG = ();
  $deploy->apply(Guard::Diff->new(ops => []));
  is_deeply \@Guard::Hooked::LOG, [], 'hooked: a diff without changes runs neither hook';

  @Guard::Hooked::LOG = ();
  ok $deploy->apply($deploy->diff, allow_destructive => 1), 'hooked: a released diff runs';
  is_deeply \@Guard::Hooked::LOG, [ 'check', 'execute' ], '... the check first, then the execution';

  @Guard::Hooked::LOG = ();
  isa_ok $deploy->upgrade(allow_destructive => 1), 'Guard::Diff', 'hooked: upgrade';
  is_deeply \@Guard::Hooked::LOG, [ 'check', 'execute' ], '... runs the same hooks';
}

{
  package Guard::Checking;
  our @ISA = ('Guard::Deploy');
  sub _check_before_apply { DBIO::Exception->throw('check says no') }
}
{
  my $dbh = Guard::DBH->new;
  my $deploy = Guard::Checking->new(schema => Guard::Schema->new(Guard::Storage->new($dbh)), ops => [ add_op() ]);
  throws_ok { $deploy->apply($deploy->diff) } qr/check says no/, '_check_before_apply stops the run by throwing';
  is scalar(@{ $dbh->{stmts} }), 0, '... before a statement ran';
}

{
  my ($deploy, $dbh) = setup(add_op());
  can_ok 'DBIO::Deploy::Base', qw(_check_before_apply _execute_diff);
  is $deploy->_check_before_apply($deploy->diff), undef, 'the default check does nothing';
  ok $deploy->_execute_diff($deploy->diff), 'the default execution runs the statements';
  is scalar(@{ $dbh->{stmts} }), 1, '... through _execute_ddl';
}

# --- a driver class inherits apply and upgrade ------------------------------
is(Guard::Deploy->can('apply'),   DBIO::Deploy::Base->can('apply'),   'apply is the inherited one');
is(Guard::Deploy->can('upgrade'), DBIO::Deploy::Base->can('upgrade'), 'upgrade is the inherited one');

done_testing;
