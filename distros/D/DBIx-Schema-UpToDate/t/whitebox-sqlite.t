# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;
use Test::MockObject 1.09;
use DBI;

eval "require DBD::SQLite"
  or plan skip_all => 'DBD::SQLite required for this test';

my $mod = 'DBIx::Schema::UpToDate';
eval "require $mod" or die $@;

my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', undef, undef, {FetchHashKeyName => 'NAME_lc'});
my $schema = new_ok($mod, [dbh => $dbh, auto_update => 0]);

# current_version
is($schema->current_version, undef, 'not built');
$schema->initialize_version_table;
is($schema->current_version, 0, 'initialized');
$schema->dbh->do('INSERT INTO schema_version (version) VALUES(57)');
is($schema->current_version, 57, 'lying about version');
$schema->dbh->do('DROP TABLE schema_version');
is($schema->current_version, undef, 'not built');

# up_to_date()
my $updated = 0;
$schema->{updates} = [
  sub {
    $_[0]->dbh->do('CREATE TABLE goober (nut text)');
    ++$updated;
  },
  sub {
    $_[0]->dbh->do("INSERT INTO goober (nut) VALUES('butter')");
    $_[0]->dbh->do('CREATE TABLE nut (goober text)');
    ++$updated;
  },
];

$schema->up_to_date();
is($updated, 2, 'correct number of updates');
is($schema->current_version, 2, 'correct current version');
is(@{$schema->dbh->table_info('%', '%', 'goober')->fetchall_arrayref}, 1, 'table created');
is(@{$schema->dbh->table_info('%', '%', 'nut')->fetchall_arrayref}, 1, 'table created');
is_deeply($schema->dbh->selectall_arrayref('SELECT * FROM goober', {Slice => {}}),
  [{nut => 'butter'}], 'got records');

$updated = 0;
push(@{$schema->{updates}},
  sub {
    $_[0]->dbh->do("INSERT INTO goober (nut) VALUES('hazel')");
    ++$updated;
  }
);

$schema->up_to_date();
is($updated, 1, 'correct number of updates');
is($schema->current_version, 3, 'correct current version');
is_deeply($schema->dbh->selectall_arrayref('SELECT * FROM goober', {Slice => {}}),
  [{nut => 'butter'}, {nut => 'hazel'}], 'got records');

# reset and try again
$schema->dbh->do("DROP TABLE $_") for qw(schema_version goober nut);
$updated = 0;
$schema->up_to_date();
is($updated, 3, 'correct number of updates');
is($schema->current_version, 3, 'correct current version');
is_deeply($schema->dbh->selectall_arrayref('SELECT * FROM goober', {Slice => {}}),
  [{nut => 'butter'}, {nut => 'hazel'}], 'got records');

done_testing;
