use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::DB2::Deploy;
use DBIO::DB2::Diff;
use DBIO::DB2::Diff::Column;

# OFFLINE (karr k54, ADR 0012 addendum). ADD COLUMN with an identity gives every
# row that exists the value 0 (the column is added NOT NULL DEFAULT 0, the
# identity is set afterwards). The diff knows no rows, so $deploy->apply asks
# the server, once the diff is built and before its first statement runs, for
# each table that gets such a column: a row there and the apply is refused with
# an exception naming table and column, nothing executed. An empty table is
# taken as before. diff and as_sql stay reads. t/77 is the live counterpart.
#
# Runs on a recording handle and a deploy whose diff and handle are replaced;
# nothing connects (pattern of t/65).

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
my $N  = col('n', is_auto_increment => 1);

# --- a table with rows: refused, nothing executed -----------------------------
{
  my ($deploy, $diff, $log) = run({ t => [$ID] }, { t => [$ID, $N] }, t => 1);
  throws_ok { $deploy->apply($diff) } qr/column "n" to table "t"/,
    'apply is refused for an identity column added to a table with rows, naming table and column';
  throws_ok { $deploy->apply($diff) } qr/\b0\b/, '... and says what would have happened (the rows get 0)';
  is scalar(grep { $_->[0] eq 'run' || $_->[0] eq 'do' } @$log), 0, '... no statement was executed';
  my ($q) = grep { $_->[0] eq 'query' } @$log;
  is $q->[1], 'SELECT 1 FROM "t" FETCH FIRST 1 ROW ONLY', '... the question is one row of the quoted table';

  @$log = ();
  throws_ok { $deploy->upgrade } qr/column "n" to table "t"/, 'upgrade is refused the same way';
  is scalar(grep { $_->[0] eq 'run' } @$log), 0, '... nothing executed';
}

# --- an empty table: as built --------------------------------------------------
{
  my ($deploy, $diff, $log) = run({ t => [$ID] }, { t => [$ID, $N] });
  lives_ok { $deploy->apply($diff) } 'an empty table takes the identity column';
  my @run = grep { $_->[0] eq 'run' } @$log;
  is scalar(@run), 1, '... the diff is executed';
  like $run[0][1], qr/ADD COLUMN "n" INTEGER NOT NULL DEFAULT 0;/, '... as built (ADR 0012)';
  my @q = grep { $_->[0] eq 'query' } @$log;
  is scalar(@q), 1, '... one question asked';
  my ($first_run) = grep { $log->[$_][0] eq 'run' } 0 .. $#$log;
  my ($first_q)   = grep { $log->[$_][0] eq 'query' } 0 .. $#$log;
  ok $first_q < $first_run, '... before the first statement';
}

# --- no identity add: the server is not asked -------------------------------------
{
  my ($deploy, $diff, $log) = run({ t => [$ID] }, { t => [$ID, col('plain', catalog_default => '0')] }, t => 1);
  lives_ok { $deploy->apply($diff) } 'a plain column added to a table with rows is fine';
  ok !(grep { $_->[0] eq 'query' } @$log), '... and nothing is asked';

  ($deploy, $diff, $log) = run({ t => [$ID, col('n')] }, { t => [$ID, $N] }, t => 1);
  lives_ok { $deploy->apply($diff) } 'a column that becomes identity (not added) is not this check';
  ok !(grep { $_->[0] eq 'query' } @$log), '... nothing asked';

  ($deploy, $diff, $log) = run({ t => [$ID] }, { t => [$ID], u => [$ID, $N] }, t => 1, u => 1);
  lives_ok { $deploy->apply($diff) } 'a new table with an identity column is created, not altered';
  ok !(grep { $_->[0] eq 'query' } @$log), '... nothing asked';
}

# --- several tables: the one with rows is named, each table asked once -------------
{
  my ($deploy, $diff, $log) = run(
    { a => [$ID], b => [$ID] },
    { a => [$ID, $N, col('m', is_auto_increment => 1)], b => [$ID, $N] },
    b => 1);
  throws_ok { $deploy->apply($diff) } qr/column "n" to table "b"/, 'the table with rows is named';
  unlike $@, qr/table "?a"?/, '... not the empty one';
  is scalar(grep { $_->[0] eq 'query' } @$log), 2, '... one question per table';
}

# --- a read stays a read -------------------------------------------------------------
{
  my ($deploy, $diff, $log) = run({ t => [$ID] }, { t => [$ID, $N] }, t => 1);
  lives_ok { $diff->as_sql; $diff->summary } 'as_sql and summary do not look at rows';
  is scalar(@$log), 0, '... the handle is not touched';
}

# --- a reorg-pending table (karr k55) -------------------------------------------------
# A table made reorg-pending by hand cannot be read (SQL0668N rc 7), so the question
# above died with that error on a bare apply. apply and upgrade run the same
# _check_before_apply (core k399): the REORG of the pending tables (karr k48), then the question.
{
  my ($deploy, $diff, $log) = run({ t => [$ID] }, { t => [$ID, $N] }, _pending => ['t']);
  my @warned;
  { local $SIG{__WARN__} = sub { push @warned, @_ };
    lives_ok { $deploy->apply($diff) } 'apply of an identity ADD onto a reorg-pending, empty table'; }
  my @kinds = map { $_->[0] } grep { $_->[0] ne 'pending' } @$log;
  is_deeply \@kinds, [qw(run query run)], '... order: the question comes after the REORG, the diff last'
    or diag explain $log;
  my @run = grep { $_->[0] eq 'run' } @$log;
  like $run[0][1], qr/REORG TABLE "t"/, '... the first statement is the REORG of the table';
  like $run[1][1], qr/ADD COLUMN "n"/, '... the diff follows';
  ok scalar(grep { /reorg/i && /\bt\b/ } @warned), '... and a warning names the table' or diag explain \@warned;
  my ($p) = grep { $_->[0] eq 'pending' } @$log;
  like $p->[1], qr/admintabinfo/i, '... pending state read from ADMINTABINFO';
  is $p->[2], 'APP', '... for the current schema';

  # rows: REORG first, then the refusal -- nothing of the diff executed
  ($deploy, $diff, $log) = run({ t => [$ID] }, { t => [$ID, $N] }, _pending => ['t'], t => 1);
  { local $SIG{__WARN__} = sub { };
    throws_ok { $deploy->apply($diff) } qr/column "n" to table "t"/, 'a pending table with rows is refused after the REORG'; }
  my @r = grep { $_->[0] eq 'run' } @$log;
  is scalar(@r), 1, '... only the REORG was executed';
  like $r[0][1], qr/REORG/, '... and it was the REORG';

  # since core k399 the REORG covers every pending table of both models (one rule
  # for apply and upgrade, t/65), the table with the identity ADD among them
  ($deploy, $diff, $log) = run({ t => [$ID], u => [$ID] }, { t => [$ID, $N], u => [$ID, col('p', catalog_default => '0')] },
    _pending => ['t', 'u']);
  { local $SIG{__WARN__} = sub { };
    $deploy->apply($diff); }
  my @reorg = grep { $_->[0] eq 'run' && $_->[1] =~ /REORG/ } @$log;
  is scalar(@reorg), 1, 'the pending tables are reorganised in one step';
  like $reorg[0][1], qr/REORG TABLE "t".*REORG TABLE "u"/s, '... "t" and "u", in name order';

  # not pending, no identity ADD, a table only in one model: no REORG, no question
  ($deploy, $diff, $log) = run({ t => [$ID] }, { t => [$ID, $N] });
  $deploy->apply($diff);
  ok !(grep { $_->[0] eq 'run' && $_->[1] =~ /REORG/ } @$log), 'a table that is not pending gets no REORG';
  ($deploy, $diff, $log) = run({ t => [$ID] }, { t => [$ID, col('p', catalog_default => '0')] }, _pending => ['t']);
  { local $SIG{__WARN__} = sub { }; $deploy->apply($diff); }
  ok !(grep { $_->[0] eq 'query' } @$log), 'no identity ADD: no rows are asked';
  ok scalar(grep { $_->[0] eq 'run' && $_->[1] =~ /REORG TABLE "t"/ } @$log),
    '... the pending table is reorganised all the same (one rule, core k399)';

  # upgrade does not do the work twice
  ($deploy, $diff, $log) = run({ t => [$ID] }, { t => [$ID, $N] }, _pending => ['t']);
  { local $SIG{__WARN__} = sub { };
    $deploy->upgrade; }
  is scalar(grep { $_->[0] eq 'pending' } @$log), 1, 'upgrade asks for the pending tables once';
  is scalar(grep { $_->[0] eq 'run' && $_->[1] =~ /REORG/ } @$log), 1, '... and reorganises once';
  is scalar(grep { $_->[0] eq 'query' } @$log), 1, '... and asks for rows once';
}

# --- the predicate ---------------------------------------------------------------------
{
  my @ops = DBIO::DB2::Diff::Column->diff({ t => [$ID] }, { t => [$ID, $N, col('p', catalog_default => '0')] },
    { t => { kind => 'table' } }, { t => { kind => 'table' } });
  is_deeply [ map { $_->column_name . '=' . ($_->adds_identity ? 1 : 0) } @ops ], ['n=1', 'p=0'],
    'adds_identity is true for the added identity column only';
}

done_testing;
