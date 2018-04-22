package Beam::Minion::Command::job;
our $VERSION = '0.014';
# ABSTRACT: Command to manage minion jobs

#pod =head1 SYNOPSIS
#pod
#pod     beam minion job [-R] [-f] [--remove] [-S <state>] [-q <queue>]
#pod         [-t <task>] [-w] [-l <limit>] [-o <offset>] [<id>]
#pod
#pod =head1 DESCRIPTION
#pod
#pod This command manages the minion queue, lists jobs, lists workers, and
#pod allows re-running failed jobs.
#pod
#pod =head1 ARGUMENTS
#pod
#pod =head2 <id>
#pod
#pod The ID of a job or worker (with the C<-w> option) to display.
#pod
#pod =head1 OPTIONS
#pod
#pod =head2 C<-R> C<--retry>
#pod
#pod Retry the given job by putting it back in the queue. See C<-f> to retry
#pod the job in the current process.
#pod
#pod =head2 C<-f> C<--foreground>
#pod
#pod Retry the given jobs right away in the current process (useful for
#pod debugging). See C<-R> to retry the job in the queue.
#pod
#pod =head2 C<--remove>
#pod
#pod Remove the given job(s) from the database.
#pod
#pod =head2 C<< -S <state> >> C<< --state <state> >>
#pod
#pod Only show jobs with the given C<state>. The state can be one of: C<inactive>,
#pod C<active>, C<finished>, or C<failed>.
#pod
#pod =head2 C<< -q <queue> >> C<< --queue <queue> >>
#pod
#pod Only show jobs in the given C<queue>. Defaults to showing jobs in all queues.
#pod The default queue for new jobs is C<default>.
#pod
#pod =head2 C<< -t <task> >> C<< --task <task> >>
#pod
#pod Only show jobs matching the given C<task>. L<Beam::Minion> task names are
#pod C<< <container>:<service> >>.
#pod
#pod =head2 C<-w> C<--workers>
#pod
#pod List workers instead of jobs.
#pod
#pod =head2 C<< -l <limit> >> C<< --limit <limit> >>
#pod
#pod Limit the list to C<limit> entries. Defaults to 100.
#pod
#pod =head2 C<< -o <offset> >> C<< --offset <offset> >>
#pod
#pod Skip C<offset> jobs when listing. Defaults to 0.
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
#pod =head1 SEE ALSO
#pod
#pod L<Beam::Minion>, L<Minion>
#pod
#pod =cut

use strict;
use warnings;
use Beam::Minion::Util qw( build_mojo_app );
use Minion::Command::minion::job;

sub run {
    my ( $class, @args ) = @_;
    my $app = build_mojo_app();
    my $cmd = Minion::Command::minion::job->new( app => $app );
    $cmd->run( @args );
}

1;

__END__

=pod

=head1 NAME

Beam::Minion::Command::job - Command to manage minion jobs

=head1 VERSION

version 0.014

=head1 SYNOPSIS

    beam minion job [-R] [-f] [--remove] [-S <state>] [-q <queue>]
        [-t <task>] [-w] [-l <limit>] [-o <offset>] [<id>]

=head1 DESCRIPTION

This command manages the minion queue, lists jobs, lists workers, and
allows re-running failed jobs.

=head1 ARGUMENTS

=head2 <id>

The ID of a job or worker (with the C<-w> option) to display.

=head1 OPTIONS

=head2 C<-R> C<--retry>

Retry the given job by putting it back in the queue. See C<-f> to retry
the job in the current process.

=head2 C<-f> C<--foreground>

Retry the given jobs right away in the current process (useful for
debugging). See C<-R> to retry the job in the queue.

=head2 C<--remove>

Remove the given job(s) from the database.

=head2 C<< -S <state> >> C<< --state <state> >>

Only show jobs with the given C<state>. The state can be one of: C<inactive>,
C<active>, C<finished>, or C<failed>.

=head2 C<< -q <queue> >> C<< --queue <queue> >>

Only show jobs in the given C<queue>. Defaults to showing jobs in all queues.
The default queue for new jobs is C<default>.

=head2 C<< -t <task> >> C<< --task <task> >>

Only show jobs matching the given C<task>. L<Beam::Minion> task names are
C<< <container>:<service> >>.

=head2 C<-w> C<--workers>

List workers instead of jobs.

=head2 C<< -l <limit> >> C<< --limit <limit> >>

Limit the list to C<limit> entries. Defaults to 100.

=head2 C<< -o <offset> >> C<< --offset <offset> >>

Skip C<offset> jobs when listing. Defaults to 0.

=head1 ENVIRONMENT

=head2 BEAM_MINION

This variable defines the shared database to coordinate the Minion workers. This
database is used to queue the job. This must be the same for all workers
and every job running.

See L<Beam::Minion/Getting Started> for how to set this variable.

=head1 SEE ALSO

L<Beam::Minion>, L<Minion>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
