use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::DB2::Deploy;
use DBIO::DB2::Diff;
use DBIO::DB2::Diff::Column;

# WHY (core k399, ADR 0080): apply runs a diff with a drop or a possibly lossy
# column change only with allow_destructive. Diff::Column::lossy decides the
# column half, on the catalog fields the diff compares: a widening Db2 casts
# without loss is free, everything else that changes the type needs the release.
# Offline: models by hand, a recording deploy; nothing connects.

sub col {
  my ($name, $type, $size, %rest) = @_;
  return { column_name => $name, catalog_type => $type, catalog_size => $size, not_null => 1, %rest };
}
sub model {
  my ($columns) = @_;
  return {
    tables => { map { $_ => { table_name => $_, kind => 'table' } } keys %$columns },
    columns => $columns, indexes => {}, foreign_keys => {}, unique_constraints => {},
  };
}
sub diff_of {
  my ($from, $to) = @_;
  return DBIO::DB2::Diff->new(source => model({ t => $from }), target => model({ t => $to }));
}
sub lossy_of {
  my ($from, $to) = @_;
  my @risky = diff_of([ $from ], [ $to ])->destructive_operations;
  return scalar @risky;
}

# --- the lossless pairs and sizes -----------------------------------------------------
ok !lossy_of(col('c', 'SMALLINT', 2), col('c', 'INTEGER', 4)), 'SMALLINT -> INTEGER keeps every value';
ok !lossy_of(col('c', 'SMALLINT', 2), col('c', 'BIGINT', 8)),  'SMALLINT -> BIGINT keeps every value';
ok !lossy_of(col('c', 'INTEGER', 4),  col('c', 'BIGINT', 8)),  'INTEGER -> BIGINT keeps every value';
ok !lossy_of(col('c', 'VARCHAR', 20), col('c', 'VARCHAR', 40)), 'a longer VARCHAR keeps every value';
ok !lossy_of(col('c', 'DECIMAL', '10,2'), col('c', 'DECIMAL', '12,2')), 'DECIMAL(10,2) -> (12,2) keeps every value';

# --- lossy ----------------------------------------------------------------------------
ok lossy_of(col('c', 'BIGINT', 8),  col('c', 'INTEGER', 4)),  'BIGINT -> INTEGER can lose values';
ok lossy_of(col('c', 'INTEGER', 4), col('c', 'SMALLINT', 2)), 'INTEGER -> SMALLINT can lose values';
ok lossy_of(col('c', 'VARCHAR', 40), col('c', 'VARCHAR', 20)), 'a shorter VARCHAR can truncate';
ok lossy_of(col('c', 'DECIMAL', '12,2'), col('c', 'DECIMAL', '12,4')), 'a changed scale can round';
ok lossy_of(col('c', 'VARCHAR', 20), col('c', 'INTEGER', 4)), 'a type across families can fail or alter values';

# --- not a type change ------------------------------------------------------------------
ok !lossy_of(col('c', 'INTEGER', 4, not_null => 0), col('c', 'INTEGER', 4)),
  'SET NOT NULL is not lossy (a NULL in the way is refused by _check_before_apply)';
ok !lossy_of(col('c', 'INTEGER', 4), col('c', 'INTEGER', 4, catalog_default => '5')), 'a default change is not lossy';
{
  my @ops = DBIO::DB2::Diff::Column->diff({ t => [ col('id', 'INTEGER', 4) ] },
    { t => [ col('id', 'INTEGER', 4), col('n', 'VARCHAR', 5) ] },
    { t => { kind => 'table' } }, { t => { kind => 'table' } });
  ok !$ops[0]->lossy, 'an added column is not lossy';
}

# --- a drop needs the release, through the base class ---------------------------------------
{
  my $diff = diff_of([ col('id', 'INTEGER', 4), col('old', 'INTEGER', 4) ], [ col('id', 'INTEGER', 4) ]);
  my @risky = $diff->destructive_operations;
  is scalar(@risky), 1, 'a dropped column is destructive';
}

# --- apply is the one of the base class, and holds the guard ----------------------------------
is +DBIO::DB2::Deploy->can('apply'),   \&DBIO::Deploy::Base::apply,   'the deploy class inherits apply';
is +DBIO::DB2::Deploy->can('upgrade'), \&DBIO::Deploy::Base::upgrade, '... and upgrade';

{
  package Mock::Deploy;
  our @ISA = ('DBIO::DB2::Deploy');
  sub _dbh { undef }    # the checks are replaced, nothing reads the handle
  sub _check_before_apply { $_[0]{checked}++ }
  sub _execute_ddl { my ($self, $dbh, @sql) = @_; push @{ $self->{ran} }, @sql; 1 }
}

{
  my $diff = diff_of([ col('c', 'BIGINT', 8) ], [ col('c', 'INTEGER', 4) ]);
  my $deploy = Mock::Deploy->new;
  throws_ok { $deploy->apply($diff) } qr/allow_destructive.*\n.*c/s,
    'a lossy column change is refused without allow_destructive, the column named';
  ok !$deploy->{ran} && !$deploy->{checked}, '... nothing ran and no check either';

  lives_ok { $deploy->apply($diff, allow_destructive => 1) } 'with allow_destructive it runs';
  ok $deploy->{checked}, '... after _check_before_apply';
  like join('', @{ $deploy->{ran} || [] }), qr/SET DATA TYPE INTEGER/, '... and executes the statement';
}

{
  my $diff = diff_of([ col('c', 'INTEGER', 4) ], [ col('c', 'BIGINT', 8) ]);
  my $deploy = Mock::Deploy->new;
  lives_ok { $deploy->apply($diff) } 'a lossless widening runs without the release';
}

done_testing;
