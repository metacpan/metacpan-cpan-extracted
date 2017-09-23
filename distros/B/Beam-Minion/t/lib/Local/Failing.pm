package Local::Failing;
# ABSTRACT: A runnable service to test Beam::Minion failure handling

=head1 SYNOPSIS

    # t/share/container.yml
    task_name:
        $class: Local::Failing

=head1 DESCRIPTION

This is a test service to be used to test the L<Beam::Minion> tasks.

=head1 SEE ALSO

L<Beam::Minion>

=cut

use Moo;

=attr exception

The exception to throw when run

=cut

has exception => (
    is => 'ro',
);

=method run

Run the task, returning the exit code.

=cut

sub run {
    my ( $self, @args ) = @_;
    die $self->exception;
}

1;
