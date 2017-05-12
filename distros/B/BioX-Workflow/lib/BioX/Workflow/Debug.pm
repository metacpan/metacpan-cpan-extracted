package BioX::Workflow::Debug;

use Storable qw(dclone);

use Moose::Role;

=head1 BioX::Workflow::Debug

Options for debugging. Stick your whole environment in memory, and figure out what went wrong.

=head2 Variables

=head3 save_object_env

Save object env. This will save all the variables. Useful for debugging, but gets unweildly for larger workflows.

=cut

has 'save_object_env' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
    predicate => 'has_save_object_env',
    clearer   => 'clear_save_object_env',
);

=head2 _classes

Saves a snapshot of the entire namespace for the initial environment, and each rule.

=cut

has '_classes' => (
    traits    => ['NoGetopt'],
    is        => 'rw',
    isa       => 'HashRef',
    default   => sub { return {} },
    required  => 0,
    predicate => 'has_classes',
    clearer   => 'clear_classes',
);

=head2 save_env

At each rule save the env for debugging purposes.

=cut

sub save_env {
    my $self = shift;

    return unless $self->save_object_env;

    $DB::single = 2;
    $self->_classes->{ $self->key } = dclone($self);
    return;
    $DB::single = 2;
}

1;
