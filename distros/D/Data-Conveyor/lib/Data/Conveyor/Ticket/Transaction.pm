use 5.008;
use strict;
use warnings;

package Data::Conveyor::Ticket::Transaction;
BEGIN {
  $Data::Conveyor::Ticket::Transaction::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

#
# Represents a single transaction as selected by txsel
use parent 'Class::Scaffold::Storable';
__PACKAGE__->mk_scalar_accessors(qw(
    payload_item object_type command type status necessity
));

sub is_optional {
    my $self = shift;
    $self->necessity eq $self->delegate->TXN_OPTIONAL;
}

sub update_status {
    my ($self, $ticket) = @_;

    # Apply a default value, but don't change transactions that are set to
    # TXS_IGNORE. This is relevant if you manually delete exceptions (via a
    # service interface) - then you also want to reset transaction stati.
    $self->status($self->delegate->TXS_RUNNING)
      if $self->status eq $self->delegate->TXS_ERROR;
    return unless $self->payload_item->has_problematic_exceptions($ticket);
    $self->status($self->delegate->TXS_ERROR);
}

# Check that the current transaction's command is allowed for the ticket's
# type. For example, a 'perscreate' must only contain 'create' commands.
#
# Don't check the value objects this transaction object consists of, like we
# do with business objects - we generated the transaction object, and we
# expect it to be correct. It should have been created with checks on, so
# illegal arguments should have been spotted then and there (probably in the
# txsel).
#
# Note that exceptions are recorded not into the exception container this
# method is given in the second arg, but into the exception container of the
# payload item this transaction points to. That's because update_status() checks
# the referenced payload item's exception container to see whether to set this
# transaction's status to TXS_ERROR; an illegal transaction given the current
# ticket type should certainly be considered a problematic exception.
sub check {
    my ($self, $ticket) = @_[0,2];
    $self->check_policy_allowed_tx_for_ticket_type($ticket);
}

sub check_policy_allowed_tx_for_ticket_type {
    my ($self, $ticket) = @_;
    return
      if $self->storage->policy_allowed_tx_for_ticket_type(
        ticket_type => $ticket->type,
        object_type => $self->object_type,
        command     => $self->command,
        txtype      => $self->type,
      );
    throw Data::Conveyor::Exception::CommandDenied(
        ticket_type => $ticket->type,
        object_type => $self->object_type,
        command     => $self->command,
    );
}
use constant SKIP_COMPARABLE_KEYS => ('payload_item');
1;


__END__
=pod

=head1 NAME

Data::Conveyor::Ticket::Transaction - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

=head1 METHODS

=head2 check

FIXME

=head2 check_policy_allowed_tx_for_ticket_type

FIXME

=head2 is_optional

FIXME

=head2 update_status

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

