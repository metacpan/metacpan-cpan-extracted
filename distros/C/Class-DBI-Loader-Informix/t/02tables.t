#!/usr/bin/perl -w

use strict;

use DBI;

use Test::More tests => 1;

use Class::DBI::Loader::Informix;

my $datasource = ( DBI->data_sources('Informix'))[0];

SKIP:
{
   skip "No datasources for test",1 unless defined $datasource;

   eval
   {
     my $dbh = DBI->connect($datasource, {RaiseError => 0, PrintError => 0, PrintWarn => 0});
     $dbh->disconnect();
   };
   skip "Can't use the '$datasource'",1 if $@;
 
   ok(Class::DBI::Loader::Informix::_tables({_datasource => [$datasource]}),
      "_tables functions correctly");
}
