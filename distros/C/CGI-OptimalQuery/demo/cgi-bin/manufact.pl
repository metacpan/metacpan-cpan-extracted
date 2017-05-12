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
  'title' => 'Manufacturers',
  'select' => {
    'U_ID' => ['manufact', 'manufact.id', 'SYS ID', { always_select => 1 }],
    'NAME' => ['manufact', 'manufact.name', 'Name']
  },
  'show' => "NAME,MANUFACT",
  'joins' => {
    'manufact' => [undef, 'manufact']
  },
  'options' => {
    'CGI::OptimalQuery::InteractiveQuery' => {
      useAjax => 0,
      NewButton => "<a href=record.pl class=OQnewBut>new</a>",
      OQdataLCol => sub { my ($rec) = @_; return "<a class=OQeditBut href='record.pl?id=$$rec{U_ID}'></a>" },
    }
  }
);

CGI::OptimalQuery->new(\%schema)->output();
