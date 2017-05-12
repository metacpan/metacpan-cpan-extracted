use strict;
use warnings;

use Test::More 0.98 tests => 5;
use t::Util;

use_ok 'DBIx::TransactionManager::Extended';

my $dbh = create_mock_dbh();
my $manager = DBIx::TransactionManager::Extended->new($dbh);
isa_ok $manager, 'DBIx::TransactionManager::Extended';

is_deeply $manager->{_context_data},        {}, '_context_data is empty';
is_deeply $manager->{_hooks_before_commit}, [], '_hooks_before_commit is empty';
is_deeply $manager->{_hooks_after_commit},  [], '_hooks_after_commit is empty';
