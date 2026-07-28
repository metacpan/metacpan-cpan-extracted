use strict;
use warnings;
use Test::More tests => 3;
use DBI;

my $dbh1 = DBI->connect('dbi:Spanner:projects/p/instances/i/databases/d', '', '');
is($dbh1->FETCH('spanner_transport'), 'grpc', 'Default transport is gRPC');

my $dbh2 = DBI->connect('dbi:Spanner:projects/p/instances/i/databases/d;transport=rest', '', '');
is($dbh2->FETCH('spanner_transport'), 'rest', 'DSN transport=rest specified');

$ENV{SPANNER_TRANSPORT} = 'rest';
my $dbh3 = DBI->connect('dbi:Spanner:projects/p/instances/i/databases/d', '', '');
is($dbh3->FETCH('spanner_transport'), 'rest', 'SPANNER_TRANSPORT=rest env var specified');
