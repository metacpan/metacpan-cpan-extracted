use 5.008;
use strict;
use warnings;

package Data::Conveyor::Exception::Container;
BEGIN {
  $Data::Conveyor::Exception::Container::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

# implements a container object.
use Data::Miscellany qw/set_push flex_grep/;
use parent 'Class::Scaffold::Exception::Container';

sub get_disruptive_items {
    my ($self, $ticket) = @_;
    return
      grep { !$ticket->ignores_exception($_) && !$_->is_optional } $self->items;
}

# determines the overall rc of the item's exceptions
sub rc {
    my ($self, $ticket, $payload_item) = @_;
    my $handler = $self->delegate->make_obj('exception_handler');
    my $rc =
      $self->delegate->make_obj('value_ticket_rc', $self->delegate->RC_OK);
    $rc += $handler->rc_for_exception_class($_, $payload_item)
      for $self->get_disruptive_items($ticket);
    $rc;
}

# determines the overall status of the item's exceptions
sub status {
    my ($self, $ticket, $payload_item) = @_;
    my $handler = $self->delegate->make_obj('exception_handler');
    my $status =
      $self->delegate->make_obj('value_ticket_status',
        $self->delegate->TS_RUNNING);

    # Add the status only for exceptions that have an rc that's equal to the
    # ticket's rc -- assuming the ticket's rc has been calculated before, of
    # course. For an explanation, assume the following situation:
    #
    # A ticket has recorded two exceptions: One with RC_OK and TS_HOLD, the
    # other with RC_ERROR and TS_RUNNING. If we just added rc's and stati
    # independently of each other, we'd end up with RC_ERROR and TS_HOLD. This
    # is not what we want. The ticket should go on hold -- for manual
    # inspection -- only if there weren't more serious issues. After all, we
    # don't want to waste a person's time only to later declare that the
    # ticket has serious problems anyway and to abort processing.
    #
    # What we want to end up with in the above situation is RC_ERROR and
    # TS_RUNNING so that the ticket is aborted. We do this by applying the
    # stati of only those exceptions that caused the ticket's overall rc.
    #
    # In our example, that's the exception that caused the RC_ERROR. Since
    # that exception has TS_RUNNING, that's the status we end up with. Which
    # is nice.
    $status += $handler->status_for_exception_class($_, $payload_item)
      for $self->filter_exceptions_by_rc($ticket, $ticket->rc);
    $status;
}

sub filter_exceptions_by_rc {
    my ($self, $ticket, @filter) = @_;
    my $handler = $self->delegate->make_obj('exception_handler');
    grep { flex_grep($handler->rc_for_exception_class($_), @filter) }
      $self->get_disruptive_items($ticket);
}

sub filter_exceptions_by_status {
    my ($self, $ticket, @filter) = @_;
    my $handler = $self->delegate->make_obj('exception_handler');
    grep { flex_grep($handler->status_for_exception_class($_), @filter) }
      $self->get_disruptive_items($ticket);
}

# Transactions ask their item (which asks their exception container) whether
# it has problematic exceptions that should cause the transaction's status to
# be set to $self->delegate->TXS_ERROR. See Data::Conveyor::Ticket::Transaction.
#
# Ordinarily, exceptions with an rc of RC_ERROR or RC_INTERNAL_ERROR are
# considered problematic. The exception's status can also have an effect on
# the tx's status. For example, in NICAT, an ::Onwait exception will have
# RC_OK and TS_HOLD, which should leave the tx on TXS_RUNNING in non-mass
# tickets (i.e., the legal department will decide whether to shift the ticket
# to the delegation stage). Same for RC_MANUAL. I.e., set the tx status only
# to TXS_ERROR if the exception indicates an RC_ERROR or an RC_INTERNAL_ERROR.
# In mass tickets, we don't want to hold up the ticket - just set the
# corresponding exception to TXS_ERROR - but only for optional exceptions.
sub has_problematic_exceptions {
    my ($self, $ticket, $payload_item) = @_;
    my $handler = $self->delegate->make_obj('exception_handler');

    # Don't use get_disruptive_items() because that would weed out exceptions
    # marked with is_optional() as well. But even optional exceptions should
    # cause a TXS_ERROR, if they aren't RC_OK.
    my @exceptions =
      grep { !$ticket->ignores_exception($_) } $self->items;
    for my $exception (@exceptions) {
        my $rc = $handler->rc_for_exception_class($exception, $payload_item);
        my $status = $handler->status_for_exception_class($exception);
        return 1
          if $rc eq $self->delegate->RC_ERROR
              || $rc eq $self->delegate->RC_INTERNAL_ERROR
              || !(
                     $status eq $self->delegate->TS_RUNNING
                  || $status eq $self->delegate->TS_HOLD
                  || $status eq $self->delegate->TS_PENDING
              );
    }
    return 0;
}
1;


__END__
=pod

=for stopwords rc

=head1 NAME

Data::Conveyor::Exception::Container - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

=head1 METHODS

=head2 filter_exceptions_by_rc

FIXME

=head2 filter_exceptions_by_status

FIXME

=head2 get_disruptive_items

FIXME

=head2 has_problematic_exceptions

FIXME

=head2 rc

FIXME

=head2 status

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

