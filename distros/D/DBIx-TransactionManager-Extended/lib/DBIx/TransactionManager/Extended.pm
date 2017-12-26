package DBIx::TransactionManager::Extended;
use 5.010001;
use strict;
use warnings;

our $VERSION = "0.03";

use parent qw/DBIx::TransactionManager/;

use Carp qw/croak/;
use DBIx::TransactionManager::Extended::Txn;

sub context_data {
    my $self = shift;
    croak 'CANNOT call context_data out of the transaction' unless $self->in_transaction;
    return $self->{_context_data};
}

# override
sub txn_scope { DBIx::TransactionManager::Extended::Txn->new(@_) }

# override
sub txn_begin {
    my ($self) = @_;
    unless ($self->in_transaction) {
        # create new context
        $self->{_context_data}        = {};
        $self->{_hooks_before_commit} = [];
        $self->{_hooks_after_commit}  = [];
    }
    goto &DBIx::TransactionManager::txn_begin; ## XXX: hack to adjust the caller
}

# override
sub txn_commit {
    my $self = shift;
    return $self->SUPER::txn_commit() if @{ $self->active_transactions } != 1; # if it's a real commit

    my $context_data        = $self->{_context_data};
    my $hooks_before_commit = $self->{_hooks_before_commit};
    my $hooks_after_commit  = $self->{_hooks_after_commit};

    if (@$hooks_before_commit) {
        eval { $_->($context_data) for @$hooks_before_commit };
        if ($@) {
            $self->txn_rollback();
            croak $@;
        }
        @$hooks_before_commit = ();
    }

    my $ret = eval {
        $self->SUPER::txn_commit();
    };
    if ($@) {
        $self->_reset_all();
        croak $@;
    }

    if (@$hooks_after_commit) {
        eval { $_->($context_data) for @$hooks_after_commit };
        if ($@) {
            $self->_reset_all();
            croak $@;
        }
        @$hooks_after_commit = ();
    }
    %$context_data = ();

    return $ret;
}

# override
sub txn_rollback {
    my $self = shift;
    $self->_reset_all();
    $self->SUPER::txn_rollback();
}

sub _reset_all {
    %{$_[0]->{_context_data}}
        = @{$_[0]->{_hooks_before_commit}}
        = @{$_[0]->{_hooks_after_commit}}
        = ();
}

sub add_hook_before_commit {
    my ($self, $hook) = @_;
    croak 'CANNOT call add_hook_before_commit out of the transaction' unless $self->in_transaction;
    push @{ $self->{_hooks_before_commit} } => $hook;
    return $hook;
}

sub add_hook_after_commit {
    my ($self, $hook) = @_;
    croak 'CANNOT call add_hook_after_commit out of the transaction' unless $self->in_transaction;
    push @{ $self->{_hooks_after_commit} } => $hook;
    return $hook;
}

sub remove_hook_before_commit {
    my ($self, $hook) = @_;
    croak 'CANNOT call remove_hook_before_commit out of the transaction' unless $self->in_transaction;
    _remove_hook($self->{_hooks_before_commit}, $hook);
}

sub remove_hook_after_commit {
    my ($self, $hook) = @_;
    croak 'CANNOT call remove_hook_after_commit out of the transaction' unless $self->in_transaction;
    _remove_hook($self->{_hooks_after_commit}, $hook);
}

sub _remove_hook {
    my ($hooks, $hook) = @_;

    my $found;
    for my $i (0..$#{$hooks}) {
        if ($hook == $hooks->[$i]) {
            $found = $i;
            last;
        }
    }
    splice @$hooks, $found, 1 if $found;
    return $found ? $hook : undef;
}

1;
__END__

=encoding utf-8

=head1 NAME

DBIx::TransactionManager::Extended - extended DBIx::TransactionManager

=head1 SYNOPSIS

    use DBI;
    use DBIx::TransactionManager::Extended;

    my $dbh = DBI->connect('dbi:SQLite:');
    my $tm = DBIx::TransactionManager::Extended->new($dbh);

    # begin transaction
    $tm->txn_begin;

        # execute query
        $dbh->do("insert into foo (id, var) values (1,'baz')");
        # And you can do multiple database operations here

        for my $data (@data) {
            push @{ $txn->context_data->{data} } => $data;
            $tm->add_hook_after_commit(sub {
                my $context_data = shift; # with the current (global) transaction
                my @data = @{ $context_data->{data} };
                return unless @data;

                ...

                $context_data->{data} = [];
            });
        }

    # and commit it.
    $tm->txn_commit;

=head1 DESCRIPTION

DBIx::TransactionManager::Extended is extended DBIx::TransactionManager.
This module provides some useful methods for application development.

=head1 EXTENDED METHODS

=head2 context_data

This is a accessor for a context data.
The context data is a associative array about a current transaction's context data.

=head2 add_hook_before_commit

Adds hook that run at before the commit all transactions.

=head2 add_hook_after_commit

Adds hook that run at after the commit all transactions.

=head2 remove_hook_before_commit

Removes hook that run at before the commit all transactions.

=head2 remove_hook_after_commit

Removes hook that run at after the commit all transactions.

=head1 SEE ALSO

L<DBIx::TransactionManager>

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut

