package Child::Link::Proc;
use strict;
use warnings;
use Carp;

use Carp;
use Child::Util;

use base 'Child::Link';

add_accessors qw/exit/;

sub is_complete {
    my $self = shift;
    $self->_wait();
    return defined($self->exit);
}

sub wait {
    my $self = shift;
    return unless $self->_wait(1);
    return !$self->exit;
}

sub exit_status {
    my $self = shift;
    return unless $self->is_complete;
    return ($self->exit >> 8);
}

sub unix_exit {
    my $self = shift;
    return unless $self->is_complete;
    return $self->exit;
}

sub _wait {
    my $self = shift;
    my ( $block ) = @_;
    #non-blocking to check if process was terminated
    #blocking to wait until it finishes
    unless ( defined $self->exit ) {
        my @flags;
        require POSIX unless $block;
        my $ret;
        my $x = 1;
        do {
            sleep(1) if defined $ret;
            $ret = waitpid( $self->pid, $block ? 0 : &POSIX::WNOHANG );
        } while ( $block && !$ret );
        return 0 unless $ret;
        if ($^O eq 'MSWin32') {
            croak( "wait returned $ret: No such process " . $self->pid )
                if $ret == -1; #forked threads on Win32 have negative pids
        } else {
            croak( "wait returned $ret: No such process " . $self->pid )
                if $ret < 0;
        }
        Child->_clean_proc($self);
        $self->_exit( $? );
    }
    return defined($self->exit);
}

sub kill {
    my $self = shift;
    my ( $sig ) = @_;
    kill( $sig, $self->pid );
}

1;

=head1 NAME

Child::Link::Proc - Proc object used by L<Child>.

=head1 SEE ALSO

This class inherits from:

=over 4

=item L<Child::Link>

=back

=head1 METHODS

=over 4

=item $bool = $proc->is_complete()

Check if the child is finished (non-blocking)

=item $proc->wait()

Wait until child terminates, destroy remaining zombie process (blocking)

=item $proc->kill($SIG)

Send the $SIG signal to the child process.

B<NOTE>: kill() is unpredictable on windows, strawberry perl sends the kill
signal to the parent as well as the child.

=item $proc->pid()

Returns the process PID.

=item $proc->exit_status()

Will be undef unless the process has exited, otherwise it will have the exit
status.

B<Note>: When you call exit($N) the actual unix exit status will be bit shifted
with extra information added. exit_status() will shift the value back for you.
That means exit_status() will return 2 when your child calls exit(2) see
unix_exit() if you want the actual value wait() assigned to $?.

=item $proc->unix_exit()

When you call exit($N) the actual unix exit status will be bit shifted
with extra information added. See exit_status() if you want the actual value
used in exit() in the child.

=back

=head1 HISTORY

Most of this was part of L<Parallel::Runner> intended for use in the L<Fennec>
project. Fennec is being broken into multiple parts, this is one such part.

=head1 FENNEC PROJECT

This module is part of the Fennec project. See L<Fennec> for more details.
Fennec is a project to develop an extendable and powerful testing framework.
Together the tools that make up the Fennec framework provide a potent testing
environment.

The tools provided by Fennec are also useful on their own. Sometimes a tool
created for Fennec is useful outside the greater framework. Such tools are
turned into their own projects. This is one such project.

=over 2

=item L<Fennec> - The core framework

The primary Fennec project that ties them all together.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Child is free software; Standard perl licence.

Child is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
