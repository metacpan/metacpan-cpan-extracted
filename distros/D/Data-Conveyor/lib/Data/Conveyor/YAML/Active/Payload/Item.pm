use 5.008;
use strict;
use warnings;

package Data::Conveyor::YAML::Active::Payload::Item;
BEGIN {
  $Data::Conveyor::YAML::Active::Payload::Item::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

use parent 'Class::Scaffold::YAML::Active::Hash';
__PACKAGE__->mk_scalar_accessors(qw(__payload_item));

# generic; subclass should override with the proper
# mk_framework_object_accessors()
sub run_plugin {
    my $self = shift;
    $self->SUPER::run_plugin(@_);
    $self->clear___payload_item;
    $self->__payload_item($self->make_payload_item);
    $self->populate_payload_item;
    $self->__payload_item;
}

# Might be empty if a subclass uses an autovivifying framework_object
sub make_payload_item { }

sub populate_payload_item {
    my $self = shift;

    # Some args are set on the payload object, others are passed to the
    # payload's data object
    $self->set_payload_item_properties;
    $self->populate_payload_item_data;
}

sub move_payload_item_property_from_hash {
    my ($self, $property) = @_;
    return unless $self->__hash_exists($property);
    $self->__payload_item->$property($self->__hash->{$property});
    $self->__hash_delete($property);
}

sub set_payload_item_properties {
    my $self = shift;
    $self->move_payload_item_property_from_hash($_)
      for qw/command exception_container implicit instruction_container/;
}

sub populate_payload_item_data {
    my $self = shift;
    local $Class::Value::SkipChecks = 1;
    while (my ($key, $value) = each %{ $self->__hash }) {
        $self->__payload_item->data->$key($value);
    }
}
1;


__END__
=pod

=head1 NAME

Data::Conveyor::YAML::Active::Payload::Item - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

=head1 METHODS

=head2 make_payload_item

FIXME

=head2 move_payload_item_property_from_hash

FIXME

=head2 populate_payload_item

FIXME

=head2 populate_payload_item_data

FIXME

=head2 run_plugin

FIXME

=head2 set_payload_item_properties

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

