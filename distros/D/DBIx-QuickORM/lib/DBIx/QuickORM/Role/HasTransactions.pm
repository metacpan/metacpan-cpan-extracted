package DBIx::QuickORM::Role::HasTransactions;
use strict;
use warnings;

our $VERSION = '0.000001';

use DBIx::QuickORM::Util qw/alias/;

use Role::Tiny;

requires 'connection';
requires 'transactions';

alias 'txn' => 'transaction';
sub txn { my $t = $_[0]->transactions; return undef unless $t && @$t; return $t->[-1] }

sub txns { shift->transactions(@_) }

alias in_txn => 'in_transaction';
sub in_txn {
    my $self = shift;

    my $txns = $self->transactions;
    if (my $cnt = @{$txns}) {
        return $cnt;
    }

    # Yes, but not ours
    return -1 if $self->connection->in_external_transaction;

    return 0;
}

1;
