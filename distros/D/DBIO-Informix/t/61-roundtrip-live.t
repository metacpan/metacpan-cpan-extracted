use strict;
use warnings;

use Test::More;
use DBIO::Optional::Dependencies ();

# deploy -> introspect -> diff is empty for the cases that used to differ
# (karr k22), against a real Informix server:
#   1. DATETIME and INTERVAL defaults are read so the DDL can write them again
#   2. a CURRENT default keeps its qualifier
#   3. a foreign key the server named (r<tabid>_<n>) is no difference, and is
#      added back without a name
#   4. SERIAL8 and BIGSERIAL columns are auto-increment and stay what they are
# Creates and drops only the tables "zz_ix_rt_*".

plan skip_all => 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_informix')
  unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_informix');

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_INFORMIX_$_" } qw/DSN USER PASS/};
plan skip_all => 'Set $ENV{DBIO_TEST_INFORMIX_DSN}, _USER and _PASS to run this test'
  unless $dsn;

use DBIO::Informix::Deploy;
use DBIO::Informix::Introspect;
use DBIO::Informix::Diff::ForeignKey;

{
  package T::Dt;
  use base 'DBIO::Core';
  __PACKAGE__->table('zz_ix_rt_dt');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer' },
    d  => { data_type => 'datetime year to day', default_value => \'DATETIME(2026-01-01) YEAR TO DAY' },
    h  => { data_type => 'datetime hour to minute', default_value => \'DATETIME(10:30) HOUR TO MINUTE' },
    i  => { data_type => 'interval day(3) to day', default_value => \'INTERVAL(5) DAY(3) TO DAY' },
    y  => { data_type => 'interval year(4) to month', default_value => \'INTERVAL(2-03) YEAR(4) TO MONTH' },
    s  => { data_type => 'datetime year to second', default_value => \'CURRENT YEAR TO SECOND' },
    f  => { data_type => 'datetime year to fraction(3)', default_value => \'CURRENT YEAR TO FRACTION(3)' },
  );
  __PACKAGE__->set_primary_key('id');

  package T::S8;
  use base 'DBIO::Core';
  __PACKAGE__->table('zz_ix_rt_s8');
  __PACKAGE__->add_columns(
    id => { data_type => 'serial8', is_auto_increment => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  package T::BS;
  use base 'DBIO::Core';
  __PACKAGE__->table('zz_ix_rt_bs');
  __PACKAGE__->add_columns(
    id => { data_type => 'bigserial', is_auto_increment => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  package T::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->storage_type('DBIO::Informix::Storage');
  __PACKAGE__->register_class(Dt => 'T::Dt');
  __PACKAGE__->register_class(S8 => 'T::S8');
  __PACKAGE__->register_class(BS => 'T::BS');
}

my $schema = T::Schema->connect($dsn, $user, $pass, { RaiseError => 1, PrintError => 0 });
my $dbh    = $schema->storage->dbh;

my @tables = qw(zz_ix_rt_dt zz_ix_rt_s8 zz_ix_rt_bs zz_ix_rt_c zz_ix_rt_p);
sub cleanup { eval { $dbh->do("DROP TABLE $_") } for @tables }
cleanup();
END { cleanup() if $dbh }

sub model { DBIO::Informix::Introspect->new(dbh => $dbh)->model }
sub ours  { my ($op) = @_; ($op->can('table_name') ? $op->table_name : '') =~ /\Azz_ix_rt_/ }

# --- 1, 2, 4: deploy, introspect, compare ------------------------------------
my $deploy = DBIO::Informix::Deploy->new(schema => $schema);
$deploy->install;

my $m = model();
my %dt = map { $_->{column_name} => $_ } @{ $m->{columns}{zz_ix_rt_dt} };
is_deeply $dt{d}{default_value}, \'DATETIME(2026-01-01) YEAR TO DAY', 'DATETIME default read with its qualifier';
is_deeply $dt{i}{default_value}, \'INTERVAL(5) DAY(3) TO DAY',         'INTERVAL default read with its qualifier';
is_deeply $dt{s}{default_value}, \'CURRENT YEAR TO SECOND',            'CURRENT YEAR TO SECOND stays';
is_deeply $dt{f}{default_value}, \'CURRENT YEAR TO FRACTION(3)',       'CURRENT YEAR TO FRACTION(3) stays';
is $m->{columns}{zz_ix_rt_s8}[0]{is_auto_increment}, 1, 'SERIAL8 is auto-increment';
is $m->{columns}{zz_ix_rt_s8}[0]{data_type}, 'serial8', 'and stays serial8';
is $m->{columns}{zz_ix_rt_bs}[0]{is_auto_increment}, 1, 'BIGSERIAL is auto-increment';
is $m->{columns}{zz_ix_rt_bs}[0]{data_type}, 'bigserial', 'and stays bigserial';

my $diff = $deploy->diff;
my @own  = grep { ours($_) } @{ $diff->operations };
is scalar @own, 0, 'compare after install: nothing to do for the tables'
  or diag join "\n", map { $_->summary } @own;

# a column definition written from the introspected model is accepted
{
  my ($col) = grep { $_->{column_name} eq 'd' } @{ $m->{columns}{zz_ix_rt_dt} };
  require DBIO::Informix::Diff::Column;
  my $sql = DBIO::Informix::Diff::Column->new(action => 'alter', table_name => 'zz_ix_rt_dt',
    column_info => $col, from_info => $col)->as_sql;
  $sql =~ s/;\z//;
  ok eval { $dbh->do($sql); 1 }, 'the introspected DATETIME column definition runs: ' . $sql
    or diag $@;
}

# --- 3: a server-named foreign key -------------------------------------------
$dbh->do('CREATE TABLE zz_ix_rt_p (id INTEGER NOT NULL, PRIMARY KEY (id))');
$dbh->do('CREATE TABLE zz_ix_rt_c (id INTEGER NOT NULL, pid INTEGER, PRIMARY KEY (id), '
  . 'FOREIGN KEY (pid) REFERENCES zz_ix_rt_p (id) ON DELETE CASCADE)');

my $fks = sub { +{ zz_ix_rt_c => [ @{ model()->{foreign_keys}{zz_ix_rt_c} // [] } ] } };
my $tabs = { zz_ix_rt_c => {}, zz_ix_rt_p => {} };

my $have = $fks->();
is scalar @{ $have->{zz_ix_rt_c} }, 1, 'the server holds one foreign key';
like $have->{zz_ix_rt_c}[0]{fk_name}, qr/\Ar\d+_\d+\z/, 'under a name it chose';

# the same key under another server's name is no difference
{
  my $other = { zz_ix_rt_c => [ { %{ $have->{zz_ix_rt_c}[0] }, fk_name => 'r999_9' } ] };
  is scalar(() = DBIO::Informix::Diff::ForeignKey->diff($have, $other, $tabs, $tabs)), 0,
    'a different server-assigned name is no change';
}

# drop it with the diff, add it back with the diff: no name written
{
  my @drop = DBIO::Informix::Diff::ForeignKey->diff($have, { zz_ix_rt_c => [] }, $tabs, $tabs);
  is scalar @drop, 1, 'one drop';
  (my $sql = $drop[0]->as_sql) =~ s/;\z//;
  ok eval { $dbh->do($sql); 1 }, "drop runs: $sql" or diag $@;
  is scalar @{ $fks->()->{zz_ix_rt_c} }, 0, 'the key is gone';

  my @add = DBIO::Informix::Diff::ForeignKey->diff({ zz_ix_rt_c => [] }, $have, $tabs, $tabs);
  is scalar @add, 1, 'one add';
  unlike $add[0]->as_sql, qr/CONSTRAINT\s+\S+;\z/s, 'written without a name';
  ($sql = $add[0]->as_sql) =~ s/;\z//;
  ok eval { $dbh->do($sql); 1 }, "add runs: $sql" or diag $@;

  my $again = $fks->();
  is scalar @{ $again->{zz_ix_rt_c} }, 1, 'the key is back';
  is scalar(() = DBIO::Informix::Diff::ForeignKey->diff($have, $again, $tabs, $tabs)), 0,
    'introspected again: no difference';
}

done_testing;
