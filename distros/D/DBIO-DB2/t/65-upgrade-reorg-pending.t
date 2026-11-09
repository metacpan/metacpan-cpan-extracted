use strict;
use warnings;

use Test::More;

use DBIO::DB2::Deploy;
use DBIO::DB2::Diff;
use DBIO::DB2::Diff::Reorg;

# OFFLINE (karr k48, ADR 0008 addendum; core k399, ADR 0080). $deploy->apply
# (and so ->upgrade, which is Deploy::Base's diff plus apply) asks in
# _check_before_apply the server which
# tables are reorg-pending (SYSIBMADM.ADMINTABINFO.REORG_PENDING) and runs the
# REORG for those before it executes the diff -- a table that was left pending
# by an earlier stop, a failed REORG or an ALTER by hand has no column
# operation in the diff to bring a REORG along, and its CREATE INDEX or first
# INSERT dies with SQL0668N rc 7. t/64 is the live counterpart.
#
# The tables asked about are those the diff can touch: a table (not a view)
# present in the source AND the target model, in the live schema only
# (TABSCHEMA bind). A table only in the source is dropped, one only in the
# target is created -- a REORG is wasted on the first and impossible on the
# second.
#
# Everything here runs on a recording handle and a deploy whose diff, apply
# step and handle are replaced; nothing connects.

{
  package Mock::Dbh;
  sub new { bless { log => $_[1], pending => $_[2] }, $_[0] }
  sub selectrow_array { push @{ $_[0]{log} }, ['value', $_[1]]; return ('APP   ') }
  sub selectcol_arrayref {
    my ($self, $sql, $attr, @bind) = @_;
    push @{ $self->{log} }, ['query', $sql, @bind];
    return [ @{ $self->{pending} } ];
  }
  sub do { push @{ $_[0]{log} }, ['do', $_[1]]; 1 }

  package Mock::Deploy;
  our @ISA = ('DBIO::DB2::Deploy');
  sub _dbh { $_[0]{dbh} }
  sub diff { $_[0]{diff} }
  sub _execute_ddl { my ($self, $dbh, @sql) = @_; push @{ $self->{log} }, ["run", join "\n", @sql]; 1 }
}

sub model {
  my ($tables, $indexes) = @_;
  return {
    tables => { map { $_->[0] => { table_name => $_->[0], kind => $_->[1] // 'table' } } @$tables },
    columns => { map { $_->[0] => [] } @$tables },
    indexes => $indexes // {},
    foreign_keys => {},
  };
}

# Runs one upgrade; returns (log, warnings, result).
sub run {
  my (%a) = @_;
  my @log;
  my $diff = DBIO::DB2::Diff->new(source => $a{source}, target => $a{target});
  my $deploy = Mock::Deploy->new(
    dbh  => Mock::Dbh->new(\@log, $a{pending} // []),
    diff => $diff,
    log  => \@log,
  );
  my @warn;
  my $res = do { local $SIG{__WARN__} = sub { push @warn, @_ };
    $deploy->upgrade(allow_destructive => $a{allow_destructive}) };
  return (\@log, \@warn, $res);
}

my $INDEX = { 'a' => { ia => { index_name => 'ia', table_name => 'a', columns => ['x'] } } };

# ============================================================================
# 1. A pending table in both models: the REORG runs first, before the diff's
#    statements (the CREATE INDEX that would die), and the query is scoped.
# ============================================================================
{
  my ($log, $warn, $res) = run(
    source  => model([ ['a'], ['b'] ]),
    target  => model([ ['a'], ['b'] ], $INDEX),
    pending => ['a'],
  );
  my @kinds = map { $_->[0] } grep { $_->[0] ne 'value' } @$log;
  is_deeply \@kinds, [qw(query run run)], 'one query, the REORG, then the diff';

  my ($q) = grep { $_->[0] eq 'query' } @$log;
  like $q->[1], qr/sysibmadm\.admintabinfo/i, 'the query reads SYSIBMADM.ADMINTABINFO';
  like $q->[1], qr/tabschema\s*=\s*\?/i, '... scoped on TABSCHEMA with a bind value';
  like $q->[1], qr/reorg_pending\s*=\s*'Y'/i, '... for the pending ones';
  is_deeply [ @$q[2 .. $#$q] ], ['APP'], '... the bind is the current schema, trimmed';

  my @runs = grep { $_->[0] eq 'run' } @$log;
  is $runs[0][1], DBIO::DB2::Diff::Reorg->new(action => 'reorg', table_name => 'a')->as_sql,
    'the first statement is the REORG exactly as Diff::Reorg renders it';
  like $runs[1][1], qr/CREATE INDEX/, 'the second is the diff, with its CREATE INDEX';
  ok $res, 'upgrade returns the diff';
  is scalar(@$warn), 1, 'one warning';
  like $warn->[0], qr/reorg/i, '... says REORG';
  like $warn->[0], qr/\ba\b/, '... names the table';
}

# ============================================================================
# 2. Nothing pending: no REORG, no warning, the diff runs as before.
# ============================================================================
{
  my ($log, $warn) = run(
    source  => model([ ['a'] ]),
    target  => model([ ['a'] ], $INDEX),
    pending => [],
  );
  is scalar(grep { $_->[0] eq 'run' } @$log), 1, 'no pending table: only the diff runs';
  ok !(grep { $_->[0] eq 'run' && $_->[1] =~ /REORG/ } @$log), '... no REORG';
  is_deeply $warn, [], '... and no warning';
}

# ============================================================================
# 3. "Affected" is the narrow reading: in both models, and a table. Pending
#    answers for a view, a table only in the source (dropped), a table only in
#    the target (created) and a table the models do not know are not reorged.
# ============================================================================
{
  my ($log, $warn) = run(
    source  => model([ ['a'], ['v', 'view'], ['gone'] ]),
    target  => model([ ['a'], ['v', 'view'], ['new'] ], $INDEX),
    pending => [qw(a v gone new other)],
    allow_destructive => 1,    # the diff drops the table "gone"
  );
  my @reorgs = map { $_->[1] } grep { $_->[0] eq 'run' && $_->[1] =~ /REORG/ } @$log;
  is_deeply \@reorgs,
    [ DBIO::DB2::Diff::Reorg->new(action => 'reorg', table_name => 'a')->as_sql ],
    'only the table in both models is reorganised';
}

# ============================================================================
# 4. Several tables, in a stable order; an identifier with quotes is quoted and
#    its apostrophe doubled (the Diff::Reorg renderer).
# ============================================================================
{
  my $odd = q{we'ird"t};
  my ($log) = run(
    source  => model([ ['b'], ['a'], [$odd] ]),
    target  => model([ ['b'], ['a'], [$odd] ], $INDEX),   # a diff with a change: an empty one is not applied
    pending => [ 'b', $odd, 'a' ],
  );
  my @reorgs = map { split /\n/, $_->[1] } grep { $_->[0] eq 'run' && $_->[1] =~ /REORG/ } @$log;
  is_deeply \@reorgs, [
    map { DBIO::DB2::Diff::Reorg->new(action => 'reorg', table_name => $_)->as_sql } sort('a', 'b', $odd)
  ], 'sorted, each as Diff::Reorg renders it';
  like join('', @reorgs), qr/we''ird""t/, 'the apostrophe is doubled inside the literal';
}

# ============================================================================
# 5. No table in both models: the server is not asked at all.
# ============================================================================
{
  my ($log) = run(
    source  => model([]),
    target  => model([ ['new'] ]),
    pending => ['new'],
  );
  ok !(grep { $_->[0] eq 'query' } @$log), 'nothing the diff can touch: no ADMINTABINFO query';
}

# ============================================================================
# 6. A pending table and an empty diff: since core k399 (ADR 0080) the checks
#    belong to apply (_check_before_apply), and apply returns for a diff without
#    changes before it looks at anything. The claim "the REORG runs also for an
#    empty diff" of karr k48 is replaced by: an empty diff touches nothing, the
#    server is not asked, upgrade answers undef.
# ============================================================================
{
  my ($log, $warn, $res) = run(
    source  => model([ ['a'] ]),
    target  => model([ ['a'] ]),
    pending => ['a'],
  );
  is scalar(@$log), 0, 'empty diff, pending table: nothing is asked and nothing runs';
  is_deeply $warn, [], '... no warning';
  ok !$res, '... upgrade answers undef: the diff had no changes';
}

# ============================================================================
# 7. apply takes the same route as upgrade: _check_before_apply on a handed
#    diff, once, and not for dry_run.
# ============================================================================
{
  my @log;
  my $diff = DBIO::DB2::Diff->new(source => model([ ['a'] ]), target => model([ ['a'] ], $INDEX));
  my $deploy = Mock::Deploy->new(dbh => Mock::Dbh->new(\@log, ['a']), diff => $diff, log => \@log);
  { local $SIG{__WARN__} = sub { }; $deploy->apply($diff); }
  is_deeply [ map { $_->[0] } grep { $_->[0] ne 'value' } @log ], [qw(query run run)],
    'apply: the pending tables are reorganised, then the diff runs';

  @log = ();
  $deploy->apply($diff, dry_run => 1);
  is scalar(@log), 0, 'dry_run: nothing is asked, nothing runs';
}

done_testing;
