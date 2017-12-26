use strict;
use warnings;

use Test::More 0.98 tests => 9;
use FindBin;
use lib "$FindBin::Bin/lib";
use t::Util;

use DBIx::TransactionManager::Extended;

my $dbh = create_mock_dbh();
my $manager = DBIx::TransactionManager::Extended->new($dbh);
is $dbh->called_count($_), 0, "$_ is not called yet" for qw/begin_work commit rollback/;

$manager->txn_begin();
is $dbh->called_count('begin_work'), 1, 'begin_work is called';

$manager->txn_commit();
is $dbh->called_count('commit'), 1, 'commit is called';
is $dbh->called_count('rollback'), 0, 'rollback is not called';

$manager->txn_begin();
is $dbh->called_count('begin_work'), 2, 'begin_work is called';

$manager->txn_rollback();
is $dbh->called_count('commit'), 1, 'commit is not called';
is $dbh->called_count('rollback'), 1, 'rollback is called';
