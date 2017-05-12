use 5.008;
use strict;
use warnings;

package Data::Conveyor::Stage::TransactionIterator;
BEGIN {
  $Data::Conveyor::Stage::TransactionIterator::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

use Error::Hierarchy::Util 'assert_defined';
use Error::Hierarchy;
use Error ':try';
use parent 'Data::Conveyor::Stage::SingleTicket';
__PACKAGE__->mk_scalar_accessors(qw(factory_method))
  ->mk_boolean_accessors(qw(done));

# Subclasses can override this if they don't want to process certain
# transactions, e.g., a notify stage might want to process all transactions,
# regardless of their status.
sub should_process_transaction {
    my ($self, $transaction) = @_;
    $transaction->status eq $self->delegate->TXS_RUNNING;
}

# Give subclasses a chance to do transaction-wide processing. Normally you
# could do this by subclassing main() and doing your special stuff after
# $self->SUPER::main(@_), but some things affect the transaction handlers
# themselves. Still we don't want to do this before $self->SUPER::main(@_)
# because that would preclude more basic checks (such as done by this class's
# superclass).
sub before_iteration { }

sub main {
    my $self = shift;
    $self->SUPER::main(@_);
    $self->before_iteration;

    # Skip the rest of the stage run if we're marked as done. this might
    # happen if very basic things didn't work out.
    return if $self->done;
    my @extra_tx;
    our $factory ||= $self->delegate->make_obj('transaction_factory');
    my $factory_method = $self->factory_method;
    for my $payload_tx ($self->ticket->payload->transactions) {
        next unless $self->should_process_transaction($payload_tx->transaction);
        try {
            my $transaction_handler = $factory->$factory_method(
                tx     => $payload_tx,
                ticket => $self->ticket,
                stage  => $self,
            );
            $transaction_handler->run;

            # The transaction handler will accumulate exceptions in the
            # exception container of the payload item pointed to by the
            # current transaction.
            #
            # Transaction handlers can ask for extra tx to be run by further
            # stages.  For example, the policy transaction handler for
            # person.update can, when asked to modify otherwise immutable
            # owner fields, downgrade an owner to a contact when that owner
            # isn't used in a delegation. To do so, it adds a
            # person.set-contact tx so that the delegation can downgrade the
            # person.
            #
            # Transaction handlers do so via an extra_tx_list attribute, which
            # is processed here. We don't just push onto
            # $self->ticket->payload->transactions because we are iterating
            # over just that, and it's not recommended to change a list while
            # iterating over it.
            #
            # A null transaction handler - produced by a Class::Null entry in
            # the relevant hashes of the transaction factory - returns another
            # Class::Null object on each of its method calls, so here we'd be
            # pushing a Class::Null object onto @extra_tx. Avoid that.
            if ($transaction_handler->extra_tx_list_count) {
                push @extra_tx => grep { !UNIVERSAL::isa($_, 'Class::Null') }
                  $transaction_handler->extra_tx_list;
            }
        }
        catch Error::Hierarchy with {

            # Exception that was thrown, not recorded.
            $payload_tx->transaction->payload_item->exception_container
              ->items_set_push($_[0]);
        };
    }
    $self->ticket->payload->add_transaction($_) for @extra_tx;
}
1;


__END__
=pod

=head1 NAME

Data::Conveyor::Stage::TransactionIterator - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

=head1 METHODS

=head2 before_iteration

FIXME

=head2 main

FIXME

=head2 should_process_transaction

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

