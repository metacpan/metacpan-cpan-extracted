package Local::Required;
# ABSTRACT: A runnable service to test Beam::Minion handling constructor errors

=head1 SYNOPSIS

    # t/share/container.yml
    task_name:
        $class: Local::Required

=head1 DESCRIPTION

This is a test service to be used to test the L<Beam::Minion> tasks.

=head1 SEE ALSO

L<Beam::Minion>

=cut

use Moo;

=attr _required

This attribute is required, and failing to provide it throws an exception.
We use this to test Beam::Minion's handling of constructor exceptions.

=cut

has _required => (
    is => 'ro',
    required => 1,
);

=method run

Run the task, returning the exit code. This will never be run, because
the constructor should fail.

=cut

sub run {
    my ( $self, @args ) = @_;
    die "If you get here, you failed the test.";
}

1;
