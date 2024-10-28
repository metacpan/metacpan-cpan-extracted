package DBIx::QuickORM::Transaction;
use strict;
use warnings;

our $VERSION = '0.000004';

use Carp qw/croak carp cluck/;

use DBIx::QuickORM::Util::HashBase qw{
    <connection
    <savepoint
    <name
    <caller
    +debug

    on_finalize
    <finalized
    <parent
    <child

    <for_row
};

sub init {
    my $self = shift;

    croak "The 'connection' is required" unless $self->{+CONNECTION};

    my $fr = $self->{+FOR_ROW} = {};
    if (my $parent = $self->{+PARENT}) {
        $fr->{+PARENT} = $parent->for_row;
    }
}

sub add_finalize_callback {
    my $self = shift;
    push @{$self->{+ON_FINALIZE} //= []} => @_;
}

sub debug {
    my $self = shift;

    return $self->{+DEBUG} if $self->{+DEBUG};

    my $name = $self->{+NAME} // 'UNNAMED';
    $name = "<$name>";

    my $caller = $self->{+CALLER} or return $self->{+DEBUG} = $name;
    my $trace = "(started at file $caller->[1] line $caller->[2])";

    return $self->{+DEBUG} = "$name $trace";
}

sub set_child {
    my $self = shift;
    my ($txn) = @_;

    if (my $child = $self->{+CHILD}) {
        return if $child == $txn;
        croak "Transaction " . $self->debug . "already has open child transaction " . $child->debug . ". Cannot add new child transaction " . $txn->debug
            unless defined($child->{+FINALIZED});
    }

    weaken($self->{+CHILD} = $txn);
}

sub _can_finalize {
    my $self = shift;
    my ($action) = @_;

    my $f = $self->{+FINALIZED};
    if (defined $f) {
        my $debug = $self->debug;
        $f = $f ? 'commit' : 'rollback';
        croak "Transaction $debug has already closed via '$f'";
    }

    if(my $child = $self->{+CHILD}) {
        my $debug = $self->debug;
        croak "Attempt to finalize transaction $debug while nested one " . $child->debug . "is still open"
            unless defined($child->{+FINALIZED});
    }

    return 1;
}

sub commit {
    my $self = shift;

    $self->_can_finalize('commit');

    if (my $sp = $self->{+SAVEPOINT}) {
        $self->{+CONNECTION}->commit_savepoint($sp);
    }
    else {
        $self->{+CONNECTION}->commit_txn;
    }

    $self->_finalize(1);
}

sub rollback {
    my $self = shift;

    $self->_can_finalize('rollback');

    if (my $sp = $self->{+SAVEPOINT}) {
        $self->{+CONNECTION}->rollback_savepoint($sp);
    }
    else {
        $self->{+CONNECTION}->rollback_txn;
    }

    $self->_finalize(0);
}

sub _finalize {
    my $self = shift;
    my ($val) = @_;

    $_->{+FINALIZED} = $val for $self, $self->{+FOR_ROW};

    my $ok = eval { $_->(transaction => $self, commited => !!$val, rolled_back => !$val) for @{$self->{+ON_FINALIZE} // []}; 1 };
    my $err = $@;

    weaken($self->{+PARENT}) if $self->{+PARENT};

    die $err unless $ok;

    return $val;
}

sub DESTROY {
    my $self = shift;
    return if defined $self->{+FINALIZED};
    return unless $self->{+CONNECTION}; # Cannot do anything without this, likely in cleanup

    my $debug = $self->debug;

    cluck "Unfinalized transaction $debug has gone out of scope, will attempt to roll back";

    local ($?, $!, $@);
    eval { $self->rollback(); 1 } or warn "Failed to rollback: $@";

    $self->_finalize(0);

    delete $self->{+PARENT};
    delete $self->{+CHILD};
}

1;
