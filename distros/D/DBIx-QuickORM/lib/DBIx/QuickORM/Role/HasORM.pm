package DBIx::QuickORM::Role::HasORM;
use strict;
use warnings;

our $VERSION = '0.000004';

use Carp qw/croak/;
use DBIx::QuickORM::Util qw/alias/;

use Role::Tiny;

alias start_transaction => 'start_txn';
alias transaction_do    => 'txn_do';
alias transactions      => 'txns';
with 'DBIx::QuickORM::Role::HasTransactions';

requires qw{orm};

sub connection { my $orm = $_[0]->orm; $orm ? $orm->connection      : croak "This instance no longer references an ORM" }
sub db         { my $orm = $_[0]->orm; $orm ? $orm->db              : croak "This instance no longer references an ORM" }
sub dbh        { my $orm = $_[0]->orm; $orm ? $orm->connection->dbh : croak "This instance no longer references an ORM" }
sub cache      { my $orm = $_[0]->orm; $orm ? $orm->cache           : croak "This instance no longer references an ORM" }
sub schema     { my $orm = $_[0]->orm; $orm ? $orm->schema          : croak "This instance no longer references an ORM" }
sub row_class  { my $orm = $_[0]->orm; $orm ? $orm->row_class       : croak "This instance no longer references an ORM" }
sub reconnect  { my $orm = $_[0]->orm; $orm ? $orm->reconnect       : croak "This instance no longer references an ORM" }

sub async_active { $_[0]->connection->async_started       ? 1 : 0 }
sub aside_active { $_[0]->connection->has_side_connection ? 1 : 0 }

sub busy { $_[0]->connection->busy }

sub start_transaction { shift->orm->start_transaction(@_) }
sub transaction_do    { shift->orm->transaction_do(@_) }
sub transactions      { shift->orm->transactions }

1;
