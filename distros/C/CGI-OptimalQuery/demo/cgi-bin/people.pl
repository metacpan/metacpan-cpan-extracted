#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use lib "$Bin/../../lib"; # include project lib

use DBI();
use CGI::OptimalQuery();

chdir "$Bin/..";

my $dbh = DBI->connect("dbi:SQLite:dbname=db/dat.db","","", { RaiseError => 1, PrintError => 1 });

my %schema = (
  'dbh' => $dbh,
  'savedSearchUserID' => 12345,
  'canSaveDefaultSearches' => 1,
  'title' => 'The People',
  'select' => {
    'U_ID' => ['person', 'person.id', 'SYS ID', { always_select => 1 }],
    'NAME' => ['person', 'person.name', 'Name'],
    'EMAIL' => ['person', 'person.email', 'Email'],
    'ACTIVE_INVENTORY' => ['activeinv', 'activeinv.cnt', 'Total Active Inventory']
  },
  'show' => "NAME,EMAIL",
  'joins' => {
    'person' => [undef, 'person'],
    'activeinv' => ['person', '
LEFT JOIN (
  -- cast is necessary when using sqlite for some reason
  SELECT owner, CAST(count(id) AS INTEGER) cnt
  FROM inventory
  GROUP BY owner
) activeinv ON (person.id=activeinv.owner)']
  },
  'options' => {
    'CGI::OptimalQuery::InteractiveQuery' => {
      'editLink' => 'record.pl'
    }
  }
);

CGI::OptimalQuery->new(\%schema)->output();
