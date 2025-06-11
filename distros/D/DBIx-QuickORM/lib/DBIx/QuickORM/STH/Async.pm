package DBIx::QuickORM::STH::Async;
use strict;
use warnings;

our $VERSION = '0.000014';

use Role::Tiny::With qw/with/;
with 'DBIx::QuickORM::Role::STH';
with 'DBIx::QuickORM::Role::Async';

use Carp qw/croak/;
use Time::HiRes qw/sleep/;

use parent 'DBIx::QuickORM::STH';
use DBIx::QuickORM::Util::HashBase qw{
    <got_result
};

sub deferred_result { 1 }

sub cancel_supported { $_[0]->dialect->async_cancel_supported }

sub clear { $_[0]->{+CONNECTION}->clear_async($_[0]) }

sub cancel {
    my $self = shift;

    return if $self->{+DONE};

    unless ($self->ready && defined $self->result) {
        $self->dialect->async_cancel(dbh => $self->{+DBH}, sth => $self->{+STH});
    }

    $self->set_done;
}

sub result {
    my $self = shift;
    return $self->{+GOT_RESULT} if $self->{+GOT_RESULT};

    # Blocking
    $self->{+GOT_RESULT} = $self->dialect->async_result(sth => $self->{+STH}, dbh => $self->{+DBH});

    if ($self->no_rows) {
        $self->{+READY} = 1;
        $self->next;
        $self->set_done;
    }

    return $self->{+GOT_RESULT};
}

sub ready {
    my $self = shift;
    return $self->{+READY} if $self->{+READY};
    $self->{+READY} = $self->dialect->async_ready(dbh => $self->{+DBH}, sth => $self->{+STH});
    return 0 unless $self->{+READY};

    if ($self->no_rows) {
        $self->next;
        $self->set_done;
    }

    return $self->{+READY};
}

1;
