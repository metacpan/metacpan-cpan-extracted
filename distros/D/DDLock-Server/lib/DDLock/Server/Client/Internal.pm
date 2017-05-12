package DDLock::Server::Client::Internal;

use strict;
use warnings;

use base 'DDLock::Server::Client';

our (%holder);  # hash of lock -> Client object holding it
# TODO: out %waiters, lock -> arrayref of client waiters (waker should check not closed)

sub _setup {
    # Nothing to set up.
}

sub _trylock {
    my DDLock::Server::Client::Internal $self = shift;
    my $lock = shift;

    return $self->err_line("empty_lock") unless length($lock);
    return $self->err_line("taken") if defined $holder{$lock};

    $holder{$lock} = $self;
    $self->{locks}{$lock} = 1;

    return $self->ok_line();
}

sub _release_lock {
    my DDLock::Server::Client::Internal $self = shift;
    my $lock = shift;

    # TODO: notify waiters
    delete $self->{locks}{$lock};
    delete $holder{$lock};
    return 1;
}

sub _get_locks {
    return map { "  $_ = " . $holder{$_}->as_string } (sort keys %holder);
}

1;
