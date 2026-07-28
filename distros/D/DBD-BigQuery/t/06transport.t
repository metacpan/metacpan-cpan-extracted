use strict;
use warnings;
use Test::More tests => 3;
use DBI;

my $dbh1 = DBI->connect('dbi:BigQuery:project=p;dataset=d', '', '');
is($dbh1->FETCH('bq_transport'), 'rest', 'Default transport is REST');

my $dbh2 = DBI->connect('dbi:BigQuery:project=p;dataset=d;transport=grpc', '', '');
is($dbh2->FETCH('bq_transport'), 'grpc', 'DSN transport=grpc specified');

$ENV{BIGQUERY_TRANSPORT} = 'grpc';
my $dbh3 = DBI->connect('dbi:BigQuery:project=p;dataset=d', '', '');
is($dbh3->FETCH('bq_transport'), 'grpc', 'BIGQUERY_TRANSPORT=grpc env var specified');
