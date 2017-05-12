package Continual::Process::Loop::Mojo;
use strict;
use warnings;

use parent 'Continual::Process::Loop';

use Mojo::Base 'Mojo::EventEmitter';

use Mojo::IOLoop;
use Try::Tiny;
use Class::Tiny {
    on_catch => sub {
        Mojo::IOLoop->stop();
        die @_;
    }
};

=head1 NAME

Continual::Process::Loop::Mojo - loop with Mojo::IOLoop support

=head1 SYNOPSIS

    my $loop = Continual::Process::Loop::Mojo->new(
        instances => [
            Continual::Process::Instance->new(...),
        ]
    );

    Mojo::IOLoop->recurrent(
        10 => sub { say 'Tick each 10s' }
    );

    $loop->run();

=head1 DESCRIPTION

This is implementation of L<Continual::Process::Loop> with L<Mojo::IOLoop>.

It is useful if you use other L<Mojo::IOLoop> events in loop.

This module is really EXPERIMENTAL, for example C<die> is not catched yet.

=head1 METHODS

All methods inherit from L<Continual::Process::Loop>.

=cut

sub run {
    my ($self) = @_;

    my $loop = Mojo::IOLoop->singleton();

    $loop->recurring(
        $self->interval => sub {
                $self->_check_and_run_death()
        }
    );

    $self->on(
        error => sub {
            warn "Mojo exception @_";

        }
    );

    $loop->start() if !$loop->is_running();
}

=head1 LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jan Seidl E<lt>seidl@avast.comE<gt>

=cut

1;
