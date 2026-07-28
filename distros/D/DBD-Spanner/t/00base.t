use strict;
use warnings;
use Test::More tests => 2;
use DBI;
use_ok('DBD::Spanner');
my $drh = DBI->install_driver('Spanner');
ok($drh, 'Driver installed');
