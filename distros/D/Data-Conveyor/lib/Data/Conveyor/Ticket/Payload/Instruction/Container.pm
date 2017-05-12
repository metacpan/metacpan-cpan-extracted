use 5.008;
use strict;
use warnings;

package Data::Conveyor::Ticket::Payload::Instruction::Container;
BEGIN {
  $Data::Conveyor::Ticket::Payload::Instruction::Container::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

# ptags: DCTPIC
use parent qw(
  Data::Container
  Class::Scaffold::Storable
);

# Override stringification to return an unblessed copy of the object's hash
# because our items don't stringify well.
sub stringify { +{%{$_[0]}} }

sub check {
    my ($self, $exception_container, $ticket) = @_;
    $_->check($exception_container, $ticket) for $self->items;
}

sub get_item_by_type {
    my ($self, $type) = @_;
    for my $instruction ($self->items) {
        return $instruction if $instruction->type eq $type;
    }
    undef;
}

# apply_fields_to_object() only handles single values; if you expect a list,
# use this method and apply the instructions yourself.
sub get_items_of_type {
    my ($self, $type) = @_;
    my @retval = grep { $_->type eq $type } $self->items;
    wantarray ? @retval : \@retval;
}

sub apply_fields_to_object {
    my ($self, $object, %field_map) = @_;
    while (my ($type, $field) = each %field_map) {
        my $instruction = $self->get_item_by_type($type);
        next unless defined $instruction;
        $object->$field($instruction->value);
    }
}
1;


__END__
=pod

=head1 NAME

Data::Conveyor::Ticket::Payload::Instruction::Container - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

=head1 METHODS

=head2 apply_fields_to_object

FIXME

=head2 check

FIXME

=head2 get_item_by_type

FIXME

=head2 get_items_of_type

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

