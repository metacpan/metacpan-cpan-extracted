package Local::Service;
# ABSTRACT: A runnable service to test Beam::Minion

=head1 SYNOPSIS

    # t/share/container.yml
    task_name:
        $class: Local::Service
        exit_code: 0

=head1 DESCRIPTION

This is a test service to be used to test the L<Beam::Minion> tasks.

=head1 SEE ALSO

L<Beam::Minion>

=cut

use Moo;

=attr exit_code

The exit code to return from this runnable service.

=cut

has exit_code => (
    is => 'ro',
);

=method run

Run the task, returning the exit code.

=cut

sub run {
    my ( $self, @args ) = @_;
    return $self->exit_code;
}

our $DESTROYED = 0;
sub DESTROY {
    $DESTROYED++;
}

1;

