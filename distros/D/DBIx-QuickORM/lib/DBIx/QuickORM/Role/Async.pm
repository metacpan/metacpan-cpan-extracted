package DBIx::QuickORM::Role::Async;
use strict;
use warnings;

our $VERSION = '0.000015';

use Time::HiRes qw/sleep/;
use Role::Tiny;

with 'DBIx::QuickORM::Role::STH';

requires qw{
    source
    only_one
    dialect
    ready
    done
    set_done
    cancel
    cancel_supported
    next
    result
    got_result
    clear
};

sub wait { sleep 0.1 until $_[0]->ready }

sub DESTROY {
    my $self = shift;

    return if $self->done;

    unless ($self->got_result) {
        if ($self->cancel_supported) {
            $self->cancel;
        }
        else {
            $self->wait;
        }
    }

    $self->set_done;
}

1;
