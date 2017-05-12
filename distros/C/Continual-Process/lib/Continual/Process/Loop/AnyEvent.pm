package Continual::Process::Loop::AnyEvent;
use strict;
use warnings;

use parent 'Continual::Process::Loop';

use Class::Tiny qw(timer);

use AnyEvent;

=head1 NAME

Continual::Process::Loop::AnyEvent - loop with AnyEvent support

=head1 SYNOPSIS

    my $loop = Continual::Process::Loop::AnyEvent->new(
        instances => [
            Continual::Process::Instance->new(...),
        ]
    );
    $loop->run();

    my $tick = AnyEvent->timer(
        interval => 10,
        cb       => sub {
            say 'Tick each 10s';
        }
    );

    my $cv = AnyEvent->condvar();
    $cv->recv;

=head1 DESCRIPTION

This is implementation of L<Continual::Process::Loop> with L<AnyEvent>.

It is useful if you can use another L<AnyEvent> events in loop.

This module is really EXPERIMENTAL, for example C<die> is not catched yet.

=head1 METHODS

All methods inherit from L<Continual::Process::Loop>.

=cut

sub run {
    my ($self) = @_;

    $self->timer(
        AnyEvent->timer(
            after    => 0,
            interval => $self->interval,
            cb       => sub {
                $self->_check_and_run_death();
            }
        )
    );
}

=head1 LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jan Seidl E<lt>seidl@avast.comE<gt>

=cut

1;
