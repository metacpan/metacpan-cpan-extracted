use 5.008;
use strict;
use warnings;

package Data::Conveyor::Ticket::Dispatcher;
BEGIN {
  $Data::Conveyor::Ticket::Dispatcher::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

use Error ':try';
use parent 'Class::Scaffold::Storable';
use constant DEFAULTS => (transactional_authority => 1);
__PACKAGE__->mk_scalar_accessors(qw(stage))
  ->mk_framework_object_accessors(ticket => 'ticket')
  ->mk_boolean_accessors(qw(transactional_authority));

sub dispatch {
    my $self = shift;
    $self->ticket(+shift) if @_;
    my $stage_name = $self->ticket->stage->name;
    try {
        $self->stage($self->delegate->make_stage_object($stage_name));
        $self->stage->ticket($self->ticket) if $self->stage->can('ticket');
        $self->stage->run;
        $self->finish_ticket;
    }
    catch Error with {
        my $E = shift;
        throw $E unless $self->transactional_authority;
        require Data::Dumper;
        local $Data::Dumper::Indent = 1;
        throw Error::Hierarchy::Internal::CustomMessage(
            custom_message => sprintf(
                'exception while processing stage [%s]: %s',
                $stage_name, Data::Dumper::Dumper($E)
            )
        );
    };
}

# Close_ticket is a method so subclasses get a chance to do additional things.
sub close_ticket {
    my $self = shift;
    $self->ticket->close;
}

sub finish_ticket {
    my $self = shift;

    # If there's an internal error, rollback any actions done so far (e.g.,
    # half-finished delegations). However, do store the errors and leave the
    # ticket with RC_INTERNAL_ERROR. To do so, we explicitly store and close
    # the ticket after the rollback. Without doing so, the ticket wouldn't be
    # closed and would remain in 'aktiv_*', plus the errors wouldn't be
    # recorded.
    #
    # If the ticket has TS_RUNNING (regardless of the rc, which could be RC_OK
    # or RC_ERROR), we close and shift the ticket; in any other case (e.g.,
    # TS_HOLD), we close the ticket, but don't shift it.
    if ($self->ticket->rc eq $self->delegate->RC_INTERNAL_ERROR) {

        # special case for conveyor/epp: we want the container to be
        # thrown. the engine will log a dump of the ticket and roll it
        # back.
        my $container =
          $self->ticket->filter_exceptions_by_rc(
            $self->delegate->RC_INTERNAL_ERROR);
        $self->log->info($container);
        if ($self->transactional_authority) {
            $self->delegate->rollback;
            $self->ticket->store;
            $self->close_ticket;
        } else {
            throw $container;
        }
    } elsif ($self->ticket->status eq $self->delegate->TS_RUNNING) {
        $self->close_ticket;
        $self->ticket->shift_stage if $self->stage->will_shift_ticket;
    } else {
        $self->close_ticket;
    }

    # the conveyor needs the possibility to leave rollback/commit to a
    # higher instance.
    return unless $self->transactional_authority;

    # We need to commit or rollback the changes made while this ticket was
    # processed, because the dispatcher processes a potentially large number
    # of tickets and we wouldn't rollback everything just because the 300th
    # ticket has a problem. Besides, committing is necessary for the ticket
    # provider to keep handing out tickets to other processes (since the
    # transaction under which the database changes are done are limited to
    # this process only.
    # Class::Scaffold::App::Test sets the rollback_mode, which is ok since we
    # want the storages to respect that. But at this point we want to
    # commit in test mode regardless of whether rollback_mode is set (so
    # integration tests work).
    if ($self->delegate->rollback_mode && !$self->delegate->test_mode) {
        $self->delegate->rollback;
    } else {
        $self->delegate->commit;
    }
}
1;


__END__
=pod

=head1 NAME

Data::Conveyor::Ticket::Dispatcher - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

=head1 METHODS

=head2 close_ticket

FIXME

=head2 dispatch

FIXME

=head2 finish_ticket

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

