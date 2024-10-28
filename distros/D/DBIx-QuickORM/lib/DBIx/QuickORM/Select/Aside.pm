package DBIx::QuickORM::Select::Aside;
use strict;
use warnings;

our $VERSION = '0.000004';

use Carp qw/croak/;

use parent 'DBIx::QuickORM::Select::Async';
use DBIx::QuickORM::Util::HashBase qw{
    orig_source
    +ignore_transactions
};

sub init {
    my $self = shift;

    $self->SUPER::init();

    $self->{+ORIG_SOURCE} //= $self->{+SOURCE};
    delete $self->{+SOURCE};
}

sub ignore_transactions {
    my $self = shift;
    my $val = shift // 1;
    $self->{+IGNORE_TRANSACTIONS} = $val;
    return $self;
}

sub ignoring_transactions { $_[0]->{+IGNORE_TRANSACTIONS} }

sub start {
    my $self = shift;

    croak "Aside query already started" if $self->{+STARTED};

    my $orig = $self->{+ORIG_SOURCE};
    $self->{+SOURCE} = $orig->orm->clone->source($orig->table->name);

    unless ($self->{+IGNORE_TRANSACTIONS}) {
        croak 'Currently inside a transaction, refusing to start a side connection (call $aside->ignore_transactions to override)'
            if $self->{+ORIG_SOURCE}->connection->in_transaction;
    }

    $self->{+STARTED} = $self->{+SOURCE}->do_select($self->params, async => $self, aside => $self->{+IGNORE_TRANSACTIONS} ? 0 : 1);

    return $self;
}

sub wait {
    my $self = shift;

    return if exists $self->{+RESULT};
    return if exists $self->{+ROWS};

    my $started = $self->{+STARTED} or croak 'Async query has not been started (did you forget to call $s->start)?';

    unless ($self->{+IGNORE_TRANSACTIONS}) {
        croak 'Main source is currently inside a transaction, refusing to taint program state (call $aside->ignore_transactions to override)'
            if $self->{+ORIG_SOURCE}->connection->in_transaction;
    }

    $self->{+READY}  = 1;
    $self->{+RESULT} = $started->{result}->();
    $self->{+ROWS}   = $started->{fetch}->($self->{+ORIG_SOURCE});

    delete $self->{+SOURCE};

    return $self;
}

sub discard {
    my $self = shift;

    my $done = 0;
    for my $field (ROWS(), READY(), RESULT()) {
        $done = 1 if delete $self->{$field};
    }

    if (my $started = delete $self->{+STARTED}) {
        $started->{cancel}->() unless $done;
    }

    delete $self->{+SOURCE};

    return $self;
}

1;
