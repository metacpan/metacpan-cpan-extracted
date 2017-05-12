#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use DBI;
use DBIx::SimpleMigration;
use File::Temp 'tempdir';

use Test::More tests => 4;

#################################
## Set up
my $tmp = tempdir(CLEANUP => 1);
BAIL_OUT('Error creating temp directory') unless -d $tmp;

open F1, '>', $tmp . '/01.sql' or BAIL_OUT('Error creating temp file');
open F2, '>', $tmp . '/02.sql' or BAIL_OUT('Error creating temp file');

print F1 <<EOL;
create table aabb (id int primary key not null, name text not null);
EOL

print F2 <<EOL;
create table ccdd (id int primary key not null, name text not null);
EOL

close F1;
close F2;
#################################

# Can't use :memory: as the handle gets cloned inside the module and we need to test it later
my $dbh = DBI->connect("dbi:SQLite:dbname=$tmp/sqlite.db");
my $migration = DBIx::SimpleMigration->new(
  dbh => $dbh,
  source => $tmp
);

isa_ok $migration, 'DBIx::SimpleMigration', 'DBIx::SimpleMigration->new returns blessed object';
eval { $migration->apply };
is $@, '', 'No errors detected';

my $result = $dbh->selectall_arrayref('SELECT * FROM migrations', {Slice => {}});
is @{$result}, 2, 'Correct number of migrations inserted';

ok(($result->[0]->{name} eq '01.sql' && $result->[1]->{name} eq '02.sql'), 'Migrations inserted in order');
