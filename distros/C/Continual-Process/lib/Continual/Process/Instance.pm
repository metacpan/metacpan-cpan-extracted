package Continual::Process::Instance;
use strict;
use warnings;

use constant WINDOWS => ($^O eq 'MSWin32');

BEGIN {
    if (WINDOWS) {
        ## no critic (ProhibitStringyEval)
        eval q{
            use Win32::Process;
        };

        die $@ if $@;
    }
}

use POSIX qw(:sys_wait_h);
use Class::Tiny qw(name instance_id code pid parent_pid), {
    id => sub {
        my ($self) = @_;

        return sprintf '%s.%s', $self->name, $self->instance_id;
    }
};

=head1 NAME

Continual::Process::Instance - one instance

=head1 SYNOPSIS

    $instance = Continual::Process::Instance->new(
        name => 'job1',
        instance_id => 1,
        code => sub {
            ...
            return $pid;
        }
    )->start();

    while(1) {
        if (!$instance->is_alive()) {
            $instance->start();
        }
    }

=head1 DESCRIPTION

This class represents one instance of L<Continual::Process>

=head1 METHODS

=head2 new(%attributes)

=head3 %attributes

=head4 name

name of process

=head4 instance_id

id of instance (number)

=head4 code

CodeRef

=cut

sub BUILD {
    my ($self) = @_;

    foreach my $req (qw/name instance_id code/) {
        die "$req attribute required" if !defined $self->$req;
    }

    if (ref $self->code ne 'CODE') {
        die 'code attribute must be CodeRef';
    }

    $self->parent_pid($$);
}

=head2 start()

start this instance

=cut

sub start {
    my ($self) = @_;

    $self->pid($self->_pid_check($self->code->($self)));

    print "# Start " . $self->id . " and run with pid: " . $self->pid . "\n" if $ENV{C_P_DEBUG};

    return $self;
}

sub _pid_check {
    my ($self, $pid) = @_;

    if (!defined $pid) {
        die 'Undefined PID';
    }
    if ($pid !~ /^(?:-)?\d+$/) {
        die "Returned PID ($pid) " . $self->name . " isn't number!";
    }

    return $pid;
}

=head2 is_alive()

is this instance alive?

=cut

sub is_alive {
    my ($self) = @_;

    return defined $self->pid && !waitpid $self->pid, WNOHANG;
}

sub DESTROY {
    my ($self) = @_;

    # destroy only in parent (main) process
    # ignore pseudo-process (<0) is threads and threads died with main
    if (defined $self->parent_pid && $self->parent_pid == $$ && $self->pid && $self->pid > 0) {
        print "# Kill PID ".$self->pid."\n" if $ENV{C_P_DEBUG};

        if (WINDOWS) {
            Win32::Process::KillProcess($self->pid, 0);
        }
        else {
            kill 15, $self->pid;
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
