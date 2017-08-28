package Beam::Minion::Command::worker;
our $VERSION = '0.006';
# ABSTRACT: Command to run a Beam::Minion worker

#pod =head1 SYNOPSIS
#pod
#pod     beam minion worker <container>
#pod
#pod =head1 DESCRIPTION
#pod
#pod This command takes a L<Beam::Wire> container (optionally searching
#pod C<BEAM_PATH> a la L<Beam::Runner>) and starts a L<Minion::Worker> worker that
#pod will run any service inside.
#pod
#pod Service jobs are added to the queue using the L<beam minion run
#pod command|Beam::Minion::Command::run>.
#pod
#pod =head1 ARGUMENTS
#pod
#pod =head2 container
#pod
#pod The container of tasks for this worker to handle. This can be an absolute
#pod path to a container file, a relative path from the current directory, or
#pod a relative path from one of the directories in the C<BEAM_PATH> environment
#pod variable (separated by C<:>).
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
use Beam::Wire;
use Beam::Runner::Util qw( find_container_path );
use Beam::Minion::Util qw( minion );
use Scalar::Util qw( weaken );
use Mojolicious;
use Mojo::Log;
use Minion::Command::minion::worker;

sub run {
    my ( $class, $container ) = @_;
    my $app = Mojolicious->new(
        log => Mojo::Log->new, # Log to STDERR
    );

    push @{$app->commands->namespaces}, 'Minion::Command';

    my $minion = minion();
    weaken $minion->app($app)->{app};
    $app->helper(minion => sub {$minion});

    my $path = find_container_path( $container );
    my $wire = Beam::Wire->new( file => $path );
    my $config = $wire->config;
    for my $name ( keys %$config ) {
        next unless $wire->is_meta( $config->{ $name }, 1 );
        $minion->add_task( $name => sub {
            my ( $job, @args ) = @_;
            my $obj = $wire->get( $name );
            my $exit = $obj->run( @args );
            my $method = $exit ? 'fail' : 'finish';
            $job->$method( { exit => $exit } );
        } );
    }
    my $cmd = Minion::Command::minion::worker->new( app => $app );
    $cmd->run( '-q', $container );
}

1;

__END__

=pod

=head1 NAME

Beam::Minion::Command::worker - Command to run a Beam::Minion worker

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    beam minion worker <container>

=head1 DESCRIPTION

This command takes a L<Beam::Wire> container (optionally searching
C<BEAM_PATH> a la L<Beam::Runner>) and starts a L<Minion::Worker> worker that
will run any service inside.

Service jobs are added to the queue using the L<beam minion run
command|Beam::Minion::Command::run>.

=head1 ARGUMENTS

=head2 container

The container of tasks for this worker to handle. This can be an absolute
path to a container file, a relative path from the current directory, or
a relative path from one of the directories in the C<BEAM_PATH> environment
variable (separated by C<:>).

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
