use strict;
use warnings;
use Test::More tests => 2;
use DBI;
use_ok('DBD::BigQuery');
my $drh = DBI->install_driver('BigQuery');
ok($drh, 'Driver installed');
