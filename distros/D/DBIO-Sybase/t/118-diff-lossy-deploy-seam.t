use strict;
use warnings;

use Test::More;

use DBIO::Sybase::Deploy;
use DBIO::Sybase::Diff;
use DBIO::Sybase::Diff::Column;

# WHY (core k399, ADR 0080): apply runs a diff with a drop or a possibly lossy
# column change only with allow_destructive. Diff::Column::Alter::lossy decides
# the column half: an integer widening ASE converts without loss is free,
# every other type change (and a shrinking size) needs the release. The NULL
# look of a NOT NULL change runs as the _check_before_apply seam of the
# inherited apply, after the guard and never for dry_run. Offline: models by
# hand, a recording deploy; nothing connects.

sub col {
  my ($name, $type, $size, %rest) = @_;
  return { column_name => $name, data_type => $type, size => $size,
           not_null => 1, default_value => undef, is_pk => 0, %rest };
}
sub model {
  my ($columns) = @_;
  return {
    tables => { map { $_ => { table_name => $_, kind => 'table' } } keys %$columns },
    columns => $columns, indexes => {}, foreign_keys => {},
  };
}
sub diff_of {
  my ($from, $to) = @_;
  return DBIO::Sybase::Diff->new(source => model({ t => $from }), target => model({ t => $to }));
}
sub lossy_of {
  my ($from, $to) = @_;
  return scalar diff_of([ col(id => 'int'), $from ], [ col(id => 'int'), $to ])
    ->destructive_operations;
}

# --- integer widenings are free -----------------------------------------------
for my $pair (qw(tinyint:smallint tinyint:int tinyint:bigint
                 smallint:int smallint:bigint int:bigint)) {
  my ($old, $new) = split /:/, $pair;
  ok !lossy_of(col(c => $old), col(c => $new)), "$old -> $new keeps every value";
}

# --- everything else that changes the type is not -----------------------------
for my $pair (qw(bigint:int int:smallint smallint:tinyint int:tinyint bigint:smallint
                 int:varchar varchar:int int:numeric numeric:int datetime:int
                 int:unsigned_int unsigned_int:int smallint:unsigned_smallint
                 tinyint:unsigned_smallint)) {
  my ($old, $new) = map { s/_/ /gr } split /:/, $pair;
  ok lossy_of(col(c => $old), col(c => $new)), "$old -> $new may lose values";
}

# --- same type: only a smaller size is lossy ----------------------------------
ok !lossy_of(col(c => 'varchar', 10), col(c => 'varchar', 20)), 'varchar(10) -> varchar(20) keeps every value';
ok !lossy_of(col(c => 'varchar', 10), col(c => 'varchar', 10, not_null => 0)),
  'a nullability change alone is not lossy';
ok  lossy_of(col(c => 'varchar', 20), col(c => 'varchar', 10)), 'varchar(20) -> varchar(10) may lose values';
ok !lossy_of(col(c => 'numeric', [10, 2]), col(c => 'numeric', [12, 2])), 'numeric(10,2) -> numeric(12,2) keeps every value';
ok  lossy_of(col(c => 'numeric', [10, 2]), col(c => 'numeric', [10, 1])), 'numeric(10,2) -> numeric(10,1) may lose values';
ok !lossy_of(col(c => 'int', undef, default_value => 1), col(c => 'int', undef, default_value => 2)),
  'a default change alone is not lossy';

# --- an added column is not lossy ---------------------------------------------
ok !scalar diff_of([ col(id => 'int') ], [ col(id => 'int'), col(c => 'int') ])->destructive_operations,
  'an added column is not lossy';

# --- apply: the guard, then the seam ------------------------------------------
{
  package K399::Dbh;
  sub new { bless { nulls => $_[1], queries => [] }, $_[0] }
  sub selectrow_array { my ($s, $sql) = @_; push @{ $s->{queries} }, $sql; $s->{nulls} }
}
{
  package K399::Deploy;
  our @ISA = ('DBIO::Sybase::Deploy');
  sub _dbh { $_[0]{dbh} }
  sub _execute_ddl { my ($self, $dbh, @sql) = @_; push @{ $self->{ran} }, @sql; 1 }
}
sub deploy { bless { dbh => K399::Dbh->new($_[0]) }, 'K399::Deploy' }

is(DBIO::Sybase::Deploy->can('apply'), DBIO::Deploy::Base->can('apply'),
  'apply is the one of DBIO::Deploy::Base');
is(DBIO::Sybase::Deploy->can('upgrade'), DBIO::Deploy::Base->can('upgrade'),
  'upgrade is the one of DBIO::Deploy::Base');

{
  my $deploy = deploy(0);
  my $diff   = diff_of([ col(id => 'int'), col(c => 'bigint') ], [ col(id => 'int'), col(c => 'int') ]);
  ok !eval { $deploy->apply($diff); 1 }, 'a narrowing type change is refused without the release';
  like "$@", qr/allow_destructive/, '... naming allow_destructive';
  is $deploy->{ran}, undef, '... and no statement was sent';
  is_deeply $deploy->{dbh}{queries}, [], '... no query was sent either';

  ok eval { $deploy->apply($diff, allow_destructive => 1); 1 }, 'allow_destructive releases it' or diag $@;
  like $deploy->{ran}[0], qr/MODIFY c INT NOT NULL/, '... and runs the MODIFY';
}
{
  my $deploy = deploy(0);
  my $diff   = diff_of([ col(id => 'int'), col(c => 'int') ], [ col(id => 'int'), col(c => 'bigint') ]);
  ok eval { $deploy->apply($diff); 1 }, 'a widening runs without the release' or diag $@;
  like $deploy->{ran}[0], qr/MODIFY c BIGINT NOT NULL/, '... as the MODIFY';
}
{
  my $deploy = deploy(1);
  my $diff   = diff_of([ col(id => 'int'), col(c => 'int', undef, not_null => 0) ],
                       [ col(id => 'int'), col(c => 'int', undef, not_null => 1) ]);
  ok !eval { $deploy->apply($diff); 1 }, 'NULL -> NOT NULL over a NULL is refused under the seam';
  like "$@", qr/table t, column c: making the column NOT NULL is refused/, '... naming table and column';
  is $deploy->{ran}, undef, '... and no statement was sent';
}
{
  my $deploy = deploy(1);
  my $diff   = diff_of([ col(id => 'int'), col(c => 'int', undef, not_null => 0) ],
                       [ col(id => 'int'), col(c => 'int', undef, not_null => 1) ]);
  my $returned = $deploy->apply($diff, dry_run => 1);
  is $returned, $diff, 'dry_run returns the diff';
  is_deeply $deploy->{dbh}{queries}, [], '... and looks at no table';
  is $deploy->{ran}, undef, '... and sends nothing';
}
{
  my $deploy = deploy(1);
  my $diff   = diff_of([ col(id => 'int'), col(c => 'bigint', undef, not_null => 0) ],
                       [ col(id => 'int'), col(c => 'int', undef, not_null => 1) ]);
  ok !eval { $deploy->apply($diff); 1 }, 'the guard comes first';
  like "$@", qr/allow_destructive/, '... a lossy diff is refused as such';
  is_deeply $deploy->{dbh}{queries}, [], '... before any table was looked at';
}

done_testing;
