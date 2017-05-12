package Continual::Process::Loop;
use strict;
use warnings;

use Class::Tiny { 
    instances   => [], 
    interval    => 1,
    on_interval => undef,
};

=head1 NAME

Continual::Process::Loop - base class for loop

=head1 DESCRIPTION

Base class for implementing loops.

=head1 METHODS

=head2 new(%attributes)

=head3 %attributes

=head4 instances

I<ArrayRef> of instances - default is empty (C<[]>)

=head4 interval

interval of alive checking

default is I<1>sec

=head4 on_interval

CodeRef which is called each check interval

default is I<disabled>

=head2 add($instance)

add C<$instance> (instance of L<Continual::Process::Instance>) to loop

=cut
sub add {
    my ($self, $instance) = @_;

    push @{ $self->tasks }, $instance;
}

=head2 run()

start this loop

=cut
sub run {
    my ($self) = @_;

    die "Method run must be implemented";
}

sub _check_and_run_death {
    my ($self) = @_;

    $self->on_interval->() if defined $self->on_interval;

    foreach my $task (@{ $self->instances }) {
        if (!$task->is_alive) {
            $task->start();
        }
    }
}

=head1 LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jan Seidl E<lt>seidl@avast.comE<gt>

=cut

1;
