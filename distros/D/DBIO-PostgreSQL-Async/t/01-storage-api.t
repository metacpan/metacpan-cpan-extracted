use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::PostgreSQL::Async::Storage;

# --- API surface check ---

my $storage = DBIO::PostgreSQL::Async::Storage->new(undef);

is $storage->future_class, 'Future', 'future_class is Future';

can_ok $storage, qw(
  select_async select_single_async insert_async update_async delete_async
  txn_do_async pipeline listen unlisten copy_in
  select select_single insert update delete txn_do
  sql_maker pool connect_info connected disconnect
);

# --- SQL Maker ---

my $sm = $storage->sql_maker;
isa_ok $sm, 'DBIO::SQLMaker';

my ($sql, @bind) = $sm->select('artist', ['name'], { id => 1 });
like $sql, qr/SELECT.*"name".*FROM.*"artist"/i, 'SQL maker generates quoted SQL';
is_deeply \@bind, [1], 'bind values correct';

done_testing;
