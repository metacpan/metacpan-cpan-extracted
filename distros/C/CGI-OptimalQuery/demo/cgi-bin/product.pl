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
  'title' => 'The Product Catalog',
  'select' => {
    'U_ID' => ['product', 'product.id', 'SYS ID', { always_select => 1 }],
    'NAME' => ['product', 'product.name', 'Name'],
    'PRODNO' => ['product', 'product.prodno', 'Product No.'],
    'BARCODES' => ['inventory', 'inventory.barcode', 'Barcodes'],
    'MANUFACT' => ['manufact', 'manufact.name', 'Manufacturer']
  },
  'show' => "NAME,MANUFACT",
  'joins' => {
    'product' => [undef, 'product'],
    'manufact' => ['product', 'LEFT JOIN manufact ON (product.manufact=manufact.id)'],
    'inventory' => ['product', 'LEFT JOIN inventory ON (product.id=inventory.product)', undef,
      { new_cursor => 1, new_cursor_order_by => "inventory.barcode DESC" }]
  },
  'options' => {
    'CGI::OptimalQuery::InteractiveQuery' => {
      'editLink' => 'record.pl'
    }
  }
);

CGI::OptimalQuery->new(\%schema)->output();
