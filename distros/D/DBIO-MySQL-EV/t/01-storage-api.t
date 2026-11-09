use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::MySQL::EV::Storage;

# --- API surface check ---

my $storage = DBIO::MySQL::EV::Storage->new(undef);

# Not plain Future since karr k48: the blocking methods ->get the Futures,
# which only a Future that can run the EV loop survives (ADR 0001 addendum).
is $storage->future_class, 'DBIO::MySQL::EV::Future', 'future_class is DBIO::MySQL::EV::Future';
ok $storage->future_class->isa('Future'), 'a Future';

can_ok $storage, qw(
  select_async select_single_async insert_async update_async delete_async
  txn_do_async pipeline
  select select_single insert update delete txn_do
  sql_maker pool connect_info connected disconnect
);

# --- SQL Maker ---

my $sm = $storage->sql_maker;
isa_ok $sm, 'DBIO::SQLMaker';

my ($sql, @bind) = $sm->select('artist', ['name'], { id => 1 });
like $sql, qr/SELECT.*`name`.*FROM.*`artist`/i, 'SQL maker generates backtick-quoted SQL';
is_deeply \@bind, [1], 'bind values correct';

done_testing;