use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::DB2::Deploy;
use DBIO::DB2::Diff;
use DBIO::DB2::Diff::Column;

# OFFLINE (karr k57, conformance cases diff-column-added-not-null-populated and
# diff-not-null-over-nulls). Two changes Db2 refuses in the middle of an upgrade
# and has no value to fill the rows with: a NOT NULL column without a default
# added to a table (SQL0193N, whatever rows it holds) and a column made NOT NULL
# over a row where it is NULL (SQL0407N). apply and upgrade refuse both before the
# first statement, with a DBIO::Exception naming table and column; nothing is
# executed, and no value is made up. Recording handle and a deploy whose diff and
# handle are replaced, as in t/76; nothing connects.
#
{
  package Mock::Dbh;
  # $rows: table name => 1 when the table holds a row
  # $pending: the tables SYSIBMADM.ADMINTABINFO holds as reorg-pending
  sub new { bless { log => $_[1], rows => $_[2], pending => $_[3] || [] }, $_[0] }
  sub selectrow_array {
    my ($self, $sql, $attr, @bind) = @_;
    return ('APP') if $sql =~ /\AVALUES/;    # CURRENT SCHEMA, asked by upgrade
    push @{ $self->{log} }, ['query', $sql, @bind];
    my ($t) = $sql =~ /FROM\s+"([^"]+)"/;
    return $self->{rows}{$t // ''} ? (1) : ();
  }
  sub selectcol_arrayref {
    my ($self, $sql, $attr, @bind) = @_;
    push @{ $self->{log} }, ['pending', $sql, @bind];
    return [ @{ $self->{pending} } ];
  }
  sub do { push @{ $_[0]{log} }, ['do', $_[1]]; 1 }

  package Mock::Deploy;
  our @ISA = ('DBIO::DB2::Deploy');
  sub _dbh { $_[0]{dbh} }
  sub diff { $_[0]{diff} }
  sub _execute_ddl { my ($self, $dbh, @sql) = @_; push @{ $self->{log} }, ['run', @sql]; 1 }
}

sub col {
  my ($name, %rest) = @_;
  return { column_name => $name, catalog_type => 'INTEGER', catalog_size => 4, not_null => 1, %rest };
}
sub model {
  my ($columns) = @_;
  return {
    tables => { map { $_ => { table_name => $_, kind => 'table' } } keys %$columns },
    columns => $columns, indexes => {}, foreign_keys => {}, unique_constraints => {},
  };
}
sub run {
  my ($source, $target, %rows) = @_;
  my @log;
  my $pending = delete $rows{_pending};
  my $diff = DBIO::DB2::Diff->new(source => model($source), target => model($target));
  my $deploy = Mock::Deploy->new(dbh => Mock::Dbh->new(\@log, \%rows, $pending), diff => $diff, log => \@log);
  return ($deploy, $diff, \@log);
}

my $ID = col('id');

sub nullable { col($_[0], not_null => 0) }
sub executed { scalar grep { $_->[0] eq 'run' || $_->[0] eq 'do' } @{ $_[0] } }

# --- NOT NULL without a default, added ----------------------------------------
{
  my ($deploy, $diff, $log) = run({ t => [$ID] }, { t => [$ID, col('code')] });
  throws_ok { $deploy->apply($diff) } qr/refused.*column "code" to table "t".*NOT NULL without a default/s,
    'apply refuses a NOT NULL column without a default, naming table and column (empty table, too)';
  isa_ok $@, 'DBIO::Exception', '... the refusal';
  is executed($log), 0, '... nothing executed';
  throws_ok { $deploy->upgrade } qr/column "code" to table "t"/, 'upgrade refuses it the same way';
  is executed($log), 0, '... nothing executed';
  is scalar(grep { $_->[0] eq 'query' } @$log), 0, '... and the server is not asked: the rows do not matter';
}

# --- what is no such case -------------------------------------------------------
for my $ok (
  [ 'a default',   col('c', catalog_default => '0') ],
  [ 'nullable',    nullable('c') ],
  [ 'an identity', col('c', is_auto_increment => 1) ],
) {
  my ($deploy, $diff, $log) = run({ t => [$ID] }, { t => [$ID, $ok->[1]] });
  lives_ok { $deploy->apply($diff) } "a column that is $ok->[0] is added";
  is executed($log), 1, '... the diff is executed';
}
{
  my ($deploy, $diff, $log) = run({ t => [$ID] }, { t => [$ID, col('c', catalog_default => 'NULL')] });
  throws_ok { $deploy->apply($diff) } qr/column "c" to table "t"/, 'DEFAULT NULL is no default';
}
{
  my ($deploy, $diff, $log) = run({ t => [$ID] }, { t => [$ID], u => [$ID, col('code')] });
  lives_ok { $deploy->apply($diff) } 'a NOT NULL column in a new table is created, not added';
}

# --- SET NOT NULL over NULLs ----------------------------------------------------
{
  my ($deploy, $diff, $log) = run({ t => [$ID, nullable('c')] }, { t => [$ID, col('c')] }, t => 1);
  throws_ok { $deploy->apply($diff) } qr/refused.*column "c" NOT NULL: table "t" holds rows where it is NULL/s,
    'apply refuses SET NOT NULL over a NULL, naming table and column';
  isa_ok $@, 'DBIO::Exception', '... the refusal';
  is executed($log), 0, '... nothing executed';
  my ($q) = grep { $_->[0] eq 'query' } @$log;
  is $q->[1], 'SELECT 1 FROM "t" WHERE "c" IS NULL FETCH FIRST 1 ROW ONLY',
    '... the question is one NULL row of the quoted column';
  @$log = ();
  throws_ok { $deploy->upgrade } qr/column "c" NOT NULL: table "t"/, 'upgrade refuses it the same way';
  is executed($log), 0, '... nothing executed';
}
{
  my ($deploy, $diff, $log) = run({ t => [$ID, nullable('c')] }, { t => [$ID, col('c')] });
  # the mock answers a row for a table in %rows only; the column is the question
  lives_ok { $deploy->apply($diff) } 'no NULL where it becomes NOT NULL: applied';
  is executed($log), 1, '... the diff is executed';
  my ($first_run) = grep { $log->[$_][0] eq 'run' } 0 .. $#$log;
  my ($first_q)   = grep { $log->[$_][0] eq 'query' } 0 .. $#$log;
  ok $first_q < $first_run, '... after the question';
}
{
  my ($deploy, $diff, $log) = run({ t => [$ID, col('c')] }, { t => [$ID, nullable('c')] }, t => 1);
  lives_ok { $deploy->apply($diff) } 'DROP NOT NULL is no such case';
  ok !(grep { $_->[0] eq 'query' } @$log), '... and nothing is asked';
}

# --- a reorg-pending table cannot be read: apply reorganises it first --------------------
{
  my ($deploy, $diff, $log) = run({ t => [$ID, nullable('c')] }, { t => [$ID, col('c')] }, _pending => ['t']);
  my @warned;
  { local $SIG{__WARN__} = sub { push @warned, @_ };
    lives_ok { $deploy->apply($diff) } 'a reorg-pending table gets its SET NOT NULL'; }
  my @run = grep { $_->[0] eq 'run' } @$log;
  like $run[0][1], qr/REORG TABLE "t"/, '... REORG first';
  like "@warned", qr/\bt\b/, '... with a warning naming the table';
}

done_testing;
