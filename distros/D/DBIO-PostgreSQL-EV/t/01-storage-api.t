use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::PostgreSQL::EV::Storage;

# --- API surface check ---

my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);

# Not plain Future since karr k44: the blocking methods ->get the Futures,
# which only a Future that can run the EV loop survives (ADR 0001 amendment).
is $storage->future_class, 'DBIO::PostgreSQL::EV::Future',
  'future_class is the EV-waiting Future';
ok $storage->future_class->isa('Future'), '... a Future subclass';

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
