# -*- perl -*-

use strict;
use warnings;
use Test::More;

use FindBin '$Bin';
use lib "$Bin/lib";
use TestEnv;

use SQL::Translator 0.11016;

use_ok( 'DBIx::Class::AuditAny' );

use TestSchema::Two;

my @connect = ('dbi:SQLite::memory:','','', { on_connect_call => 'use_foreign_keys' });

ok(
  my $schema = TestSchema::Two->connect(@connect),
  "Initialize Test Database"
);

$schema->deploy;


ok(
  my $Auditor = DBIx::Class::AuditAny->track(
    schema => $schema, 
    track_all_sources => 1,
    collector_class => 'Collector::AutoDBIC',
    collector_params => {
      sqlite_db => TestEnv->vardir->file('audit_two_015.db')->stringify,
    },
    datapoints => [
      (qw(schema schema_ver changeset_ts changeset_elapsed)),
      (qw(change_elapsed action source pri_key_value)),
      (qw(column_name old_value new_value)),
    ],
    rename_datapoints => {
      changeset_elapsed => 'total_elapsed',
      change_elapsed => 'elapsed',
      pri_key_value => 'row_key',
      new_value => 'new',
      old_value => 'old',
      column_name => 'column',
    },
  ),
  "Setup tracker configured to write to auto configured schema"
);


ok( 
  $schema->resultset('Team')->create({
    id => 1,
    name => 'Denver Broncos' 
  }),
  "Insert a test row (Team table)"
);


ok( 
  my $Position = $schema->resultset('Position')->create({
    name => 'Quarterback',
    players => [
      {
        first => 'Payton',
        last => 'Manning',
        team_id => 1,
      },
      {
        first => 'Trevor',
        last => 'Trevor Siemian',
        team_id => 1,
      }
    
    ]
  }),
  "Create a test row (Position) with nested related rows (players)"
);



ok(
  my $chrows = [ $Auditor->collector->target_schema
    ->resultset('AuditChange')
    ->search_rs(undef,{ 
      columns => [qw/action changeset_id id row_key source/],
      result_class => 'DBIx::Class::ResultClass::HashRefInflator' 
    })
    ->all
  ],
  "Fetch AuditChange rows"
);

is_deeply(
  $chrows, &_expected_audit_change_rows,
  "AuditChange rows match what was expected exactly"
);

sub _expected_audit_change_rows {[
  {
    action => "insert",
    changeset_id => 1,
    id => 1,
    row_key => 1,
    source => "Team"
  },
  {
    action => "insert",
    changeset_id => 2,
    id => 2,
    row_key => "Quarterback",
    source => "Position"
  },
  {
    action => "insert",
    changeset_id => 2,
    id => 3,
    row_key => 1,
    source => "Player"
  },
  {
    action => "insert",
    changeset_id => 2,
    id => 4,
    row_key => 2,
    source => "Player"
  }
]}

done_testing;



## This test isn't reliable because the column order can differ. If I really want to test
## this I'd just have to write some deeper inspection logic
#ok(
#  my $rows = [ $Auditor->collector->target_schema
#    ->resultset('AuditChangeColumn')
#    ->search_rs(undef,{ result_class => 'DBIx::Class::ResultClass::HashRefInflator' })
#    ->all
#  ],
#  "Fetch AuditChangeColumn rows"
#);
#
#use Data::Dumper::Concise;
#is(
#  Dumper($rows), Dumper(&_expected_audit_change_column_rows),
#  "AuditChangeColumn rows match what was expected exactly"
#);
#
#
#sub _expected_audit_change_column_rows {[
#  {
#    change_id => 1,
#    column => "name",
#    id => 1,
#    new => "Denver Broncos",
#    old => undef
#  },
#  {
#    change_id => 1,
#    column => "id",
#    id => 2,
#    new => 1,
#    old => undef
#  },
#  {
#    change_id => 2,
#    column => "name",
#    id => 3,
#    new => "Quarterback",
#    old => undef
#  },
#  {
#    change_id => 3,
#    column => "first",
#    id => 4,
#    new => "Payton",
#    old => undef
#  },
#  {
#    change_id => 3,
#    column => "last",
#    id => 5,
#    new => "Manning",
#    old => undef
#  },
#  {
#    change_id => 3,
#    column => "position",
#    id => 6,
#    new => "Quarterback",
#    old => undef
#  },
#  {
#    change_id => 3,
#    column => "team_id",
#    id => 7,
#    new => 1,
#    old => undef
#  },
#  {
#    change_id => 3,
#    column => "id",
#    id => 8,
#    new => 1,
#    old => undef
#  },
#  {
#    change_id => 4,
#    column => "first",
#    id => 9,
#    new => "Trevor",
#    old => undef
#  },
#  {
#    change_id => 4,
#    column => "last",
#    id => 10,
#    new => "Trevor Siemian",
#    old => undef
#  },
#  {
#    change_id => 4,
#    column => "position",
#    id => 11,
#    new => "Quarterback",
#    old => undef
#  },
#  {
#    change_id => 4,
#    column => "team_id",
#    id => 12,
#    new => 1,
#    old => undef
#  },
#  {
#    change_id => 4,
#    column => "id",
#    id => 13,
#    new => 2,
#    old => undef
#  }
#]}