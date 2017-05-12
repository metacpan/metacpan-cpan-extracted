package Continual::Process::Loop::Simple;
use strict;
use warnings;

use parent 'Continual::Process::Loop';

use Class::Tiny { 
    tick => sub {1}    
};

=head1 NAME

Continual::Process::Loop::Simple - simple while/sleep loop

=head1 SYNOPSIS
    my $loop = Continual::Process::Loop::Simple->new(
        instances => [
            Continual::Process::Instance->new(...)
        ]
    );

    $loop->add(Continual::Process::Instance->new(...));

    $loop->run();

=head1 DESCRIPTION

This simple loop implementation of L<Continual::Process::Loop> only check each interval (1 sec) all instances and restart death.

=head1 METHODS

All methods are inherits from L<Continual::Process::Loop>.

=cut
sub run {
    my ($self) = @_;

    while ($self->tick->()) {
        $self->_check_and_run_death();

        sleep 1;
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
