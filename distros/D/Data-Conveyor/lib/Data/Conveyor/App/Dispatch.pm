use 5.008;
use strict;
use warnings;

package Data::Conveyor::App::Dispatch;
BEGIN {
  $Data::Conveyor::App::Dispatch::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

use Time::HiRes 'usleep';
use Data::Conveyor::Lock::Dispatcher;
use parent 'Class::Scaffold::App::CommandLine';
__PACKAGE__->mk_framework_object_accessors(
    ticket_provider   => 'ticket_provider',
    ticket_dispatcher => 'dispatcher',
  )->mk_scalar_accessors(
    qw(
      done stage_class dispatcher_sleep lockpath lockhandler
      )
  )->mk_integer_accessors(qw(ticket_count));
use constant GETOPT => qw/lockpath=s/;

sub app_init {
    my $self = shift;
    $self->SUPER::app_init(@_);
    $self->delegate->make_obj('ticket_payload');

    # If several dispatchers are running, we want to know which log message
    # came from which process. Can be done only now that
    # Class::Scaffold::App->app_init will have instantiated the log singleton.
    $self->log->set_pid;
    $self->ticket_count(0) unless defined $self->ticket_count;
    $self->dispatcher_sleep($self->delegate->dispatcher_sleep || 10);
    $self->lockpath($self->delegate->lockpath);
    $self->delegate->control->filename($self->delegate->control_filename);
}

sub check_lockfile {
    my $self = shift;
    return 1 if $self->delegate->ignore_locks;
    $self->lockhandler
      || $self->lockhandler(
        Data::Conveyor::Lock::Dispatcher->new(lockpath => $self->lockpath));
    $self->lockhandler->lockstate;
}

sub app_code {
    my $self = shift;
    $self->log->info("starting");
    $self->SUPER::app_code(@_);

    # keep EINTR from looping over into the next sleep call;
    # this also should rollback the interrupted transaction,
    # which is exactly what we want. -ac
    local $SIG{INT} = sub { exit };
    my $success;
    while (!$self->done) {

        # this could stay here
        unless ($self->check_lockfile) {
            $self->done(1);
            last;
        }
        $self->ticket_count_inc;
        $self->done(1)
          if $self->ticket_count >= $self->delegate->max_tickets_per_dispatcher;
        unless ($self->delegate->control->read) {
            $self->log->info("control returned false, exiting.");
            $self->done(1);
            last;
        }
        my $ticket;

        # If there aren't any tickets waiting to be processed, don't exit,
        # just sleep. We don't want to keep starting and stopping dispatcher
        # processes just because there are no more tickets for a few seconds.
        unless (
            defined(
                $ticket = $self->ticket_provider->get_next_ticket(
                    [ $self->delegate->control->allowed_stages_keys ], $success
                )
            )
          ) {
            $self->log->info("sleep %ss", $self->dispatcher_sleep);
            sleep($self->dispatcher_sleep);
            next;
        }

        # XXX: $ticket->stage should already be a ticket stage value object,
        # so we'd only need to do $ticket->stage->name.
        #my $stage = $self->delegate->make_obj('value_ticket_stage')->new(
        #    value => $ticket->stage)->name;
        # Try to open the ticket - this can still fail if another dispatcher
        # process has already opened the ticket.
        # try_open sets the stage to aktiv_* and commits - we don't want that
        # any more in nic.at
        # we should try to get the db locks instead.
        $self->log_line($ticket, '>');
        if ($self->open_ticket($ticket)) {
            $success = 1;

            # $self->log_line($ticket, $success);
        } else {
            $success = 0;

            # $self->log_line($ticket, $success);
            # cool it a little
            usleep(200_000);
            next;
        }

        # Now we have an opened ticket; process it.
        $self->process_ticket($ticket);
    }
    $self->log->info("exiting");
}

sub log_line {
    my ($self, $ticket, $success) = @_;
    $self->log->info("%s [%s] [% 3s] %s",
        $ticket->ticket_no, $success, $ticket->nice, $ticket->stage->name);
}

sub open_ticket {
    my ($self, $ticket) = @_;
    $ticket->try_open;
}

sub process_ticket {
    my ($self, $ticket) = @_;
    $self->dispatcher->dispatch($ticket);
}
1;


__END__
=pod

=head1 NAME

Data::Conveyor::App::Dispatch - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

=head1 METHODS

=head2 check_lockfile

FIXME

=head2 log_line

FIXME

=head2 open_ticket

FIXME

=head2 process_ticket

FIXME

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Conveyor>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/Data-Conveyor/>.

The development version lives at L<http://github.com/hanekomu/Data-Conveyor>
and may be cloned from L<git://github.com/hanekomu/Data-Conveyor>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

=head1 AUTHORS

=over 4

=item *

Marcel Gruenauer <marcel@cpan.org>

=item *

Florian Helmberger <fh@univie.ac.at>

=item *

Achim Adam <ac@univie.ac.at>

=item *

Mark Hofstetter <mh@univie.ac.at>

=item *

Heinz Ekker <ek@univie.ac.at>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

