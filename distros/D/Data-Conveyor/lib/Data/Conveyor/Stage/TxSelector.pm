use 5.008;
use strict;
use warnings;

package Data::Conveyor::Stage::TxSelector;
BEGIN {
  $Data::Conveyor::Stage::TxSelector::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

# Implements the transaction selector (txsel)
use Error::Hierarchy::Util 'assert_defined';
use parent 'Data::Conveyor::Stage::SingleTicket';

sub DEFAULTS {
    (expected_stage => $_[0]->delegate->ST_TXSEL);
}

# Return a list of object types that specifies in which order payload items
# should be traversed. Subclasses might need to override this with a specific
# order, for example, when new payload items are created implicitly.
#
# don't include transaction itself in calculating transactions
sub object_type_iteration_order {
    grep { $_ ne $_[0]->delegate->OT_TRANSACTION } $_[0]->delegate->OT;
}

sub main {
    my ($self, %args) = @_;
    $self->SUPER::main(%args);

    # Txsel handlers can create implicit payload items; to ensure idempotency,
    # we remove them before reprocessing the ticket.
    $self->ticket->payload->delete_implicit_items;
    $self->ticket->payload->transactions_clear;
    $self->before_object_type_iteration;
    for my $object_type ($self->object_type_iteration_order) {
        for my $payload_item (
            $self->ticket->payload->get_list_for_object_type($object_type)) {
            $self->calc_implicit_tx($object_type, $payload_item,
                $self->delegate->CTX_BEFORE);
            $self->calc_explicit_tx($object_type, $payload_item);
            $self->calc_implicit_tx($object_type, $payload_item,
                $self->delegate->CTX_AFTER);
        }
    }
    $self->after_object_type_iteration;
}

# Two events that subclasses might want to handle
sub before_object_type_iteration { }
sub after_object_type_iteration  { }

sub calc_explicit_tx {
    my ($self, $object_type, $payload_item) = @_;
    $self->ticket->payload->add_transaction(
        object_type  => $object_type,
        command      => $payload_item->command,
        type         => $self->delegate->TXT_EXPLICIT,
        status       => $self->delegate->TXS_RUNNING,
        payload_item => $payload_item,
        necessity    => $self->delegate->TXN_MANDATORY,
    );
}

# find and set implicit transactions in the current object.
sub calc_implicit_tx {
    my ($self, $object_type, $payload_item, $context) = @_;
    our $factory ||= $self->delegate->make_obj('transaction_factory');
    assert_defined $context,      'called without context.';
    assert_defined $object_type,  'called without object_type.';
    assert_defined $payload_item, 'called without payload item.';
    $factory->gen_txsel_handler(
        $object_type,
        $payload_item->{command},
        $context,
        payload_item => $payload_item,
        ticket       => $self->ticket,
    )->calc_implicit_tx;
}
1;


__END__
=pod

=head1 NAME

Data::Conveyor::Stage::TxSelector - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

=head1 METHODS

=head2 DEFAULTS

FIXME

=head2 after_object_type_iteration

FIXME

=head2 before_object_type_iteration

FIXME

=head2 calc_explicit_tx

FIXME

=head2 calc_implicit_tx

FIXME

=head2 main

FIXME

=head2 object_type_iteration_order

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

