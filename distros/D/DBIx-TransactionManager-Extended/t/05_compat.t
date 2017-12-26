use strict;
use warnings;

use Test::More 0.98 tests => 2;
use FindBin;
use lib "$FindBin::Bin/lib";
use t::Util;

use_ok 'DBIx::TransactionManager::Extended::Compat';

my $dbh = create_mock_dbh();
my $manager = DBIx::TransactionManager->new($dbh);
isa_ok $manager, 'DBIx::TransactionManager::Extended';
