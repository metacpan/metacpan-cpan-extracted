package Beam::Minion;
our $VERSION = '0.006';
# ABSTRACT: A distributed task runner for Beam::Wire containers

#pod =head1 SYNOPSIS
#pod
#pod     # Command-line interface
#pod     export BEAM_MINION=sqlite://test.db
#pod     beam minion worker <container>...
#pod     beam minion run <container> <service> [<args>...]
#pod     beam minion help
#pod
#pod     # Perl interface
#pod     local $ENV{BEAM_MINION} = 'sqlite://test.db';
#pod     Beam::Minion->enqueue( $container, $service, @args );
#pod
#pod =head1 DESCRIPTION
#pod
#pod L<Beam::Minion> is a distributed task runner. One or more workers are
#pod created to run tasks, and then each task is sent to a worker to be run.
#pod Tasks are configured as L<Beam::Runnable> objects by L<Beam::Wire>
#pod container files.
#pod
#pod =head1 GETTING STARTED
#pod
#pod =head2 Configure Minion
#pod
#pod To start running your L<Beam::Runner> jobs, you must first start
#pod a L<Minion> worker with the L<beam minion
#pod worker.command|Beam::Minion::Command::worker>.  Minion requires
#pod a database to coordinate workers, and communicates with this database
#pod using a L<Minion::Backend>.
#pod
#pod The supported Minion backends are:
#pod
#pod =over
#pod
#pod =item *
#pod
#pod L<Minion::Backend::SQLite> - C<< sqlite:<db_path> >>
#pod
#pod =item *
#pod
#pod L<Minion::Backend::Pg> - C<< postgresql://<user>:<pass>@<host>/<database> >>
#pod
#pod =item *
#pod
#pod L<Minion::Backend::mysql> - C<< mysql://<user>:<pass>@<host>/<database> >>
#pod
#pod =item *
#pod
#pod L<Minion::Backend::MongoDB> - C<< mongodb://<host>:<port> >>
#pod
#pod =back
#pod
#pod Once you've picked a database backend, configure the C<BEAM_MINION>
#pod environment variable with the URL. Minion will automatically deploy the
#pod database tables it needs, so be sure to allow the right permissions (if
#pod the database has such things).
#pod
#pod In order to communicate with Minion workers on other machines, it will
#pod be necessary to use a database accessible from the network (so, not
#pod SQLite).
#pod
#pod =head2 Start a Worker
#pod
#pod Once the C<BEAM_MINION> environment variable is set, you can start
#pod a worker with C<< beam minion worker <container> >>. Each worker can run
#pod jobs from one container, specified as the argument to the C<beam minion
#pod worker> command. Each worker will run up to 4 jobs concurrently.
#pod
#pod =head2 Spawn a Job
#pod
#pod Jobs are spawned with C<< beam minion run <container> <service> >>.
#pod The C<service> must be an object that consumes the L<Beam::Runnable>
#pod role. C<container> should be a path to a container file and can be
#pod an absolute path, a path relative to the current directory, or a
#pod path relative to one of the paths in the C<BEAM_PATH> environment
#pod variable (separated by C<:>).
#pod
#pod You can queue up jobs before you have workers running. As soon as
#pod a worker is available, it will start running jobs from the queue.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Beam::Wire>, L<Beam::Runner>, L<Minion>
#pod
#pod =cut

use strict;
use warnings;
use Beam::Minion::Util qw( minion );

#pod =sub enqueue
#pod
#pod     Beam::Minion->enqueue( $container_name, $task_name, @args );
#pod
#pod Enqueue the task named C<$task_name> from the container named C<$container_name>.
#pod The C<BEAM_MINION> environment variable must be set.
#pod
#pod =cut

sub enqueue {
    my ( $class, $container, $task, @args ) = @_;
    my $minion = minion();
    $minion->enqueue( $task, \@args, { queue => $container } );
}

1;

__END__

=pod

=head1 NAME

Beam::Minion - A distributed task runner for Beam::Wire containers

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    # Command-line interface
    export BEAM_MINION=sqlite://test.db
    beam minion worker <container>...
    beam minion run <container> <service> [<args>...]
    beam minion help

    # Perl interface
    local $ENV{BEAM_MINION} = 'sqlite://test.db';
    Beam::Minion->enqueue( $container, $service, @args );

=head1 DESCRIPTION

L<Beam::Minion> is a distributed task runner. One or more workers are
created to run tasks, and then each task is sent to a worker to be run.
Tasks are configured as L<Beam::Runnable> objects by L<Beam::Wire>
container files.

=head1 SUBROUTINES

=head2 enqueue

    Beam::Minion->enqueue( $container_name, $task_name, @args );

Enqueue the task named C<$task_name> from the container named C<$container_name>.
The C<BEAM_MINION> environment variable must be set.

=head1 GETTING STARTED

=head2 Configure Minion

To start running your L<Beam::Runner> jobs, you must first start
a L<Minion> worker with the L<beam minion
worker.command|Beam::Minion::Command::worker>.  Minion requires
a database to coordinate workers, and communicates with this database
using a L<Minion::Backend>.

The supported Minion backends are:

=over

=item *

L<Minion::Backend::SQLite> - C<< sqlite:<db_path> >>

=item *

L<Minion::Backend::Pg> - C<< postgresql://<user>:<pass>@<host>/<database> >>

=item *

L<Minion::Backend::mysql> - C<< mysql://<user>:<pass>@<host>/<database> >>

=item *

L<Minion::Backend::MongoDB> - C<< mongodb://<host>:<port> >>

=back

Once you've picked a database backend, configure the C<BEAM_MINION>
environment variable with the URL. Minion will automatically deploy the
database tables it needs, so be sure to allow the right permissions (if
the database has such things).

In order to communicate with Minion workers on other machines, it will
be necessary to use a database accessible from the network (so, not
SQLite).

=head2 Start a Worker

Once the C<BEAM_MINION> environment variable is set, you can start
a worker with C<< beam minion worker <container> >>. Each worker can run
jobs from one container, specified as the argument to the C<beam minion
worker> command. Each worker will run up to 4 jobs concurrently.

=head2 Spawn a Job

Jobs are spawned with C<< beam minion run <container> <service> >>.
The C<service> must be an object that consumes the L<Beam::Runnable>
role. C<container> should be a path to a container file and can be
an absolute path, a path relative to the current directory, or a
path relative to one of the paths in the C<BEAM_PATH> environment
variable (separated by C<:>).

You can queue up jobs before you have workers running. As soon as
a worker is available, it will start running jobs from the queue.

=head1 SEE ALSO

L<Beam::Wire>, L<Beam::Runner>, L<Minion>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
