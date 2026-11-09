use strict;
use warnings;
use Test::More;

# LIVE, karr k68 (maintainer's decision 2026-10-22): an auto-increment value of
# 0 handed to insert_async / upsert_async is "generate", as the server reads
# it, unless the session's sql_mode has NO_AUTO_VALUE_ON_ZERO.
#
#   a) default sql_mode: insert with id => 0 returns the id the server made
#      (what a SELECT finds), not 0
#   b) NO_AUTO_VALUE_ON_ZERO in the session (on_connect_do, replayed on every
#      pooled connection): the row is stored with id 0 and 0 comes back
#   c) an upsert with id => 0: the insert branch and the update branch both
#      name the row the server touched
#   d) the sync storage on the same data, for comparison (reported by diag,
#      not asserted: core's sync insert keeps a supplied 0, see karr k68)
#
# The table lives in a database of its own, mysql_ev_k68, created here and
# dropped at the end.

use DBI;
use DBIO::MySQL::EV::TestHarness;

BEGIN { DBIO::MySQL::EV::TestHarness->skip_all_unless_live }

alarm 120;

my $DB = 'mysql_ev_k68';
my ($DSN, $USER, $PASS) = map { $ENV{"DBIO_TEST_MYSQL_$_"} } qw( DSN USER PASS );

(my $own = $DSN) =~ s/(?<=[:;])(?:database|dbname|db)=[^;]*/database=$DB/
  or plan skip_all => 'DBIO_TEST_MYSQL_DSN names no database';

sub connect_sync {
  my ($dsn) = @_;
  return DBI->connect($dsn, $USER, $PASS, { RaiseError => 1, PrintError => 0, PrintWarn => 0 });
}

my $CREATED;
{
  my $dbh = connect_sync($DSN);
  $dbh->do("DROP DATABASE IF EXISTS $DB");
  $dbh->do("CREATE DATABASE $DB");
  $CREATED = 1;
  $dbh->disconnect;
}
END {
  return unless $CREATED;
  my $dbh = eval { connect_sync($DSN) } or return;
  eval { $dbh->do("DROP DATABASE IF EXISTS $DB") };
  $dbh->disconnect;
}
{
  my $dbh = connect_sync($own);
  $dbh->do('CREATE TABLE zero_artist (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(64) NOT NULL, UNIQUE KEY (name))');
  $dbh->disconnect;
}

{
  package K68::Live::Artist;
  use base 'DBIO::Core';
  __PACKAGE__->table('zero_artist');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 64 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint([qw( name )]);

  package K68::Live::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL');
  __PACKAGE__->register_class(Artist => 'K68::Live::Artist');
}

my @harness;
END { eval { $_->disconnect } for @harness }

sub harness {
  my (%attrs) = @_;
  my $h = DBIO::MySQL::EV::TestHarness->new(
    schema_class  => 'K68::Live::Schema',
    dsn           => $own, user => $USER, pass => $PASS,
    connect_attrs => { pool_size => 2, %attrs },
  );
  $h->warm_pool;
  push @harness, $h;
  return $h;
}

sub id_of {
  my ($dbh, $name) = @_;
  return $dbh->selectrow_array('SELECT id FROM zero_artist WHERE name = ?', undef, $name);
}

my $check = connect_sync($own);

for my $case (
  [ 'default sql_mode', {}, 0 ],
  [ 'NO_AUTO_VALUE_ON_ZERO', { on_connect_do => [
      q{SET SESSION sql_mode = CONCAT(@@sql_mode, ',NO_AUTO_VALUE_ON_ZERO')} ] }, 1 ],
) {
  my ($label, $attrs, $keeps) = @$case;
  $check->do('DELETE FROM zero_artist');
  $check->do('ALTER TABLE zero_artist AUTO_INCREMENT = 10');

  my $h = harness(%$attrs);
  my $async  = $h->async;
  my $source = $h->schema->source('Artist');

  my $r = $h->await($async->insert_async($source, { id => 0, name => "a-$keeps" }));
  my $stored = id_of($check, "a-$keeps");
  if ($keeps) {
    is $stored, 0, "$label: the row is stored with id 0";
    is $r->{id}, 0, "$label: 0 comes back";
  }
  else {
    is $stored, 10, "$label: the server generated the id";
    is $r->{id}, $stored, "$label: insert_async returns the generated id, not 0";
  }

  # upsert, insert branch then update branch
  $check->do('DELETE FROM zero_artist');
  $check->do('ALTER TABLE zero_artist AUTO_INCREMENT = 20');
  my $row = do {
    local $SIG{__WARN__} = sub { };    # the kept-0 upsert cannot name its row
    $h->await($h->schema->resultset('Artist')->upsert_async(
      { id => 0, name => "u-$keeps" }, { conflict_target => 'any' },
    ));
  };
  my $ustored = id_of($check, "u-$keeps");
  if ($keeps) {
    is $ustored, 0, "$label: upsert stores id 0";
    ok !$row || $row->id == 0, "$label: upsert resolves the row with id 0 (or none)";
  }
  else {
    ok $row, "$label: upsert insert branch resolves a row";
    is $row && $row->id, $ustored, "$label: upsert insert branch names the generated id";
    my $again = $h->await($h->schema->resultset('Artist')->upsert_async(
      { id => 0, name => "u-$keeps" }, { conflict_target => 'any' },
    ));
    is $again && $again->id, $ustored, "$label: upsert update branch names the row it touched";
  }

  # the sync storage, for the record
  $check->do('DELETE FROM zero_artist');
  my $s = eval { $h->schema->resultset('Artist')->create({ id => 0, name => "s-$keeps" }) };
  diag "$label: sync create(id => 0) returned id " . ($s ? ($s->id // 'undef') : "error $@")
     . ", stored " . (id_of($check, "s-$keeps") // 'undef');
}

done_testing;
