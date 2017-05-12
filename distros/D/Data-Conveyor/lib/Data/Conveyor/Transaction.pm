use 5.008;
use strict;
use warnings;

package Data::Conveyor::Transaction;
BEGIN {
  $Data::Conveyor::Transaction::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

# Base class for classes operating on transactions. Policy and delegation
# classes subclass this class.
use Error::Hierarchy::Util 'assert_defined';
use parent 'Class::Scaffold::Storable';
__PACKAGE__->mk_framework_object_accessors(
    ticket              => 'ticket',
    transaction_factory => 'factory',
)->mk_scalar_accessors(qw(tx stage))->mk_array_accessors(qw(extra_tx_list));

# ticket and tx are passed by Data::Conveyor::Transaction::Factory
# constructor call; the factory also passes itself as the factory
# attribute so the transaction can ask the factory to construct
# further objects.
# shortcuts to the item and its data referenced by the current transaction
sub payload_item      { $_[0]->tx->transaction->payload_item }
sub payload_item_data { $_[0]->payload_item->data }

# Cumulate exceptions here and throw them summarily in an exception container
# at the end. We do this because we want to be able to check as much as
# possible.
sub record {
    my $self = shift;

    # make record() invisible to caller when reporting exception location
    local $Error::Depth = $Error::Depth + 1;
    $self->payload_item->exception_container->record(@_,
        is_optional => $self->tx->transaction->is_optional,);
}

# Like record(), but records an actual exception object. This method would be
# called if you want to record an exception caught from somewhere else.
sub record_exception {
    my ($self, $E) = @_;
    $E->is_optional($self->tx->transaction->is_optional);
    $self->payload_item->exception_container->items_set_push($E);
}
sub run { }
1;


__END__
=pod

=head1 NAME

Data::Conveyor::Transaction - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

=head1 METHODS

=head2 payload_item

FIXME

=head2 payload_item_data

FIXME

=head2 record_exception

FIXME

=head2 run

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

