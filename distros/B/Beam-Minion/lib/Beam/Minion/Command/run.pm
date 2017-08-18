package Beam::Minion::Command::run;
our $VERSION = '0.004';
# ABSTRACT: Command to enqueue a job on Beam::Minion job queue

#pod =head1 SYNOPSIS
#pod
#pod     beam minion run <container> <service> [<args>...]
#pod
#pod =head1 DESCRIPTION
#pod
#pod This command adds a job to the L<Minion> queue to execute the given
#pod C<service> from the given C<container>.
#pod
#pod In order for the job to run, you must run a Minion worker using the
#pod L<beam minion worker command|Beam::Minion::Command::worker>.
#pod
#pod =head1 ARGUMENTS
#pod
#pod =head2 container
#pod
#pod The container that contains the task to run. This can be an absolute
#pod path to a container file, a relative path from the current directory, or
#pod a relative path from one of the directories in the C<BEAM_PATH> environment
#pod variable (separated by C<:>).
#pod
#pod =head2 service
#pod
#pod The service that defines the task to run. Must be an object that consumes
#pod the L<Beam::Runner> role.
#pod
#pod =head1 ENVIRONMENT
#pod
#pod =head2 BEAM_MINION
#pod
#pod This variable defines the shared database to coordinate the Minion workers. This
#pod database is used to queue the job. This must be the same for all workers
#pod and every job running.
#pod
#pod See L<Beam::Minion/Getting Started> for how to set this variable.
#pod
#pod =head2 BEAM_PATH
#pod
#pod This variable is a colon-separated list of directories to search for
#pod containers.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Beam::Minion>, L<Minion>
#pod
#pod =cut

use strict;
use warnings;
use Beam::Minion;

sub run {
    my ( $class, $container, $service_name, @args ) = @_;
    Beam::Minion->enqueue( $container, $service_name, @args );
}

1;

__END__

=pod

=head1 NAME

Beam::Minion::Command::run - Command to enqueue a job on Beam::Minion job queue

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    beam minion run <container> <service> [<args>...]

=head1 DESCRIPTION

This command adds a job to the L<Minion> queue to execute the given
C<service> from the given C<container>.

In order for the job to run, you must run a Minion worker using the
L<beam minion worker command|Beam::Minion::Command::worker>.

=head1 ARGUMENTS

=head2 container

The container that contains the task to run. This can be an absolute
path to a container file, a relative path from the current directory, or
a relative path from one of the directories in the C<BEAM_PATH> environment
variable (separated by C<:>).

=head2 service

The service that defines the task to run. Must be an object that consumes
the L<Beam::Runner> role.

=head1 ENVIRONMENT

=head2 BEAM_MINION

This variable defines the shared database to coordinate the Minion workers. This
database is used to queue the job. This must be the same for all workers
and every job running.

See L<Beam::Minion/Getting Started> for how to set this variable.

=head2 BEAM_PATH

This variable is a colon-separated list of directories to search for
containers.

=head1 SEE ALSO

L<Beam::Minion>, L<Minion>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
