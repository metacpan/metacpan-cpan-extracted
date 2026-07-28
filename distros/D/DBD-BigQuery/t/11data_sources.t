use strict;
use warnings;
use Test::More tests => 1;
use DBI;
my @sources = DBI->data_sources('BigQuery');
ok(\@sources, 'data_sources query returned list');
