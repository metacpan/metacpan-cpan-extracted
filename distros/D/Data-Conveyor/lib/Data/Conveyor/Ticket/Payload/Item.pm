use 5.008;
use strict;
use warnings;

package Data::Conveyor::Ticket::Payload::Item;
BEGIN {
  $Data::Conveyor::Ticket::Payload::Item::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

#
# Base class for Data::Conveyor::Ticket::Payload::* items
use parent 'Class::Scaffold::Storable';
__PACKAGE__->mk_abstract_accessors(qw(DATA_PROPERTY))
  ->mk_framework_object_accessors(exception_container => 'exception_container')
  ->mk_boolean_accessors(qw(implicit));

# implicit(): was this item created implicitly by txsel?
sub check {
    my ($self, $ticket) = @_;
    $self->data->check($self->exception_container, $ticket);
}

sub data {
    my $property = $_[0]->DATA_PROPERTY;
    return $_[0]->$property if @_ == 1;
    $_[0]->$property($_[1]);
}

# For rc() and status(), we pass the payload item's owning ticket object to
# the exception container. The container needs to ask the ticket whether to
# ignore an exception. Why do the payload object and the payload items have an
# owning ticket, but the exception container does not? Because exception
# containers are filled from various places, and are passed around. In
# contrast, payload containers and payload items are always tied to a ticket.
#
# We also pass the payload item itself because it will eventually be passed to
# the exception handler, which uses it to decide the rc and status of each
# exception it is ask to handle. That is, the rc and exception aren't
# determined by the exception type alone. The same exception can have
# different rc and status values depending on which object type and command it
# is associated with.
sub rc {
    my ($self, $ticket) = @_;
    $self->exception_container->rc($ticket, $self);
}

sub status {
    my ($self, $ticket) = @_;
    $self->exception_container->status($ticket, $self);
}

sub has_problematic_exceptions {
    my ($self, $ticket) = @_;
    $self->exception_container->has_problematic_exceptions($ticket, $self);
}

sub prepare_comparable {
    my $self = shift;
    $self->SUPER::prepare_comparable(@_);

    # Touch various accessors that will autovivify hash keys so we can be sure
    # they exist, which is a kind of normalization for the purpose of
    # comparing two objects of this class.
    $self->exception_container;
    $self->implicit;
}

# do nothing here; business objects will override
sub apply_instruction_container { }
1;


__END__
=pod

=for stopwords rc

=head1 NAME

Data::Conveyor::Ticket::Payload::Item - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

=head1 METHODS

=head2 apply_instruction_container

FIXME

=head2 check

FIXME

=head2 data

FIXME

=head2 has_problematic_exceptions

FIXME

=head2 prepare_comparable

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

