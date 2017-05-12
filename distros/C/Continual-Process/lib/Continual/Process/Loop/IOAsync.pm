package Continual::Process::Loop::IOAsync;
use strict;
use warnings;

use parent 'Continual::Process::Loop';

use Class::Tiny qw(timer);

use IO::Async::Timer::Periodic;

=head1 NAME

Continual::Process::Loop::IOAsync - loop with IO::Async support

=head1 SYNOPSIS

    my $loop = IO::Async::Loop->new;

    my $cp_loop = Continual::Process::Loop::IOAsync->new(
        instances => [
            Continual::Process::Instance->new(...),
        ]
    );
    $cp_loop->run();

    $loop->add( $cp_loop->timer );

    my $timer = IO::Async::Timer::Periodic->new(
        interval => 10,
 
        on_tick => sub {
            say 'Tick each 10s';
        },
    );

    $timer->start;

    $loop->add( $timer );

    $loop->run;

=head1 DESCRIPTION

This is implementation of L<Continual::Process::Loop> with L<AnyEvent>.

It is useful if you can use another L<AnyEvent> events in loop.

This module is really EXPERIMENTAL, for example C<die> is not catched yet.

=head1 METHODS

All methods inherit from L<Continual::Process::Loop>.

=cut

sub run {
    my ($self) = @_;

    my $timer = IO::Async::Timer::Periodic->new(
        interval => $self->interval,
        on_tick  => sub {
            $self->_check_and_run_death();
        }
    );

    $timer->start;
    
    $self->timer( $timer );        
}

=head1 LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Konstantin Yakunin E<lt>twinhooker@gmail.comE<gt>

=cut

1;
