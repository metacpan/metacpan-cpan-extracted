use 5.008;
use strict;
use warnings;

package Data::Conveyor::Storage;
BEGIN {
  $Data::Conveyor::Storage::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

use Error::Hierarchy::Util 'assert_defined';
use Class::Scaffold::Exception::Util 'assert_object_type';
use parent 'Class::Scaffold::Base';
__PACKAGE__->mk_abstract_accessors(
    qw(
      ticket_update ticket_insert get_ticket_shift_data
      )
);

# Within Data-Conveyor, rollback_mode isn't taken from the superclass'
# property of the same name, but we ask the delegate.
# Class::Scaffold::App::Test will set the rollback_mode on the Environment
# (which is the delegate), for example.  Just be sure to place
# Data::Conveyor::Storage first in multiple inheritance, e.g., when inheriting
# both from Data::Conveyor::Storage and Data::Storage::*
sub rollback_mode       { $_[0]->delegate->rollback_mode }
sub set_rollback_mode   { $_[0]->delegate->set_rollback_mode }
sub clear_rollback_mode { $_[0]->delegate->clear_rollback_mode }

sub ticket_store {
    my ($self, $ticket) = @_;
    $ticket->assert_ticket_no;
    if ($self->ticket_exists($ticket)) {
        $self->ticket_update($ticket);
    } else {
        $self->ticket_insert($ticket);
    }
}

sub ticket_serialized_payload {
    my ($self, $payload) = @_;
    assert_object_type $payload, 'ticket_payload';
    $payload->version($self->delegate->PAYLOAD_VERSION);

    # Serialize the ticket payload using Storable. The serialized version is
    # stored in the dem_payload table. We need to enable the serialization of
    # code references.
    require Storable;
    $Storable::Deparse = 1;
    $payload           = Storable::nfreeze($payload);

    # compression
    require Compress::Zlib;
    Compress::Zlib::compress($payload)
      || throw Error::Hierarchy::Internal::CustomMessage(
        custom_message => 'zlib compress() failure');
}

sub ticket_deserialized_payload {
    my ($self, $payload) = @_;
    assert_defined $payload, 'called without defind serialized payload.';

    # compression
    require Compress::Zlib;
    $payload = Compress::Zlib::uncompress($payload)
      || throw Error::Hierarchy::Internal::CustomMessage(
        custom_message => 'zlib uncompress() failure');

    # deserialize the ticket payload using Storable if it exists.
    # we need to enable the deserialization of code references.
    require Storable;
    $Storable::Eval = 1;
    $payload        = Storable::thaw($payload);
    $payload->upgrade;
    $payload;
}

sub ticket_handle_exception {
    my ($self, $E) = @_;
    throw $E;
}
1;


__END__
=pod

=head1 NAME

Data::Conveyor::Storage - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

=head1 METHODS

=head2 clear_rollback_mode

FIXME

=head2 rollback_mode

FIXME

=head2 set_rollback_mode

FIXME

=head2 ticket_deserialized_payload

FIXME

=head2 ticket_handle_exception

FIXME

=head2 ticket_serialized_payload

FIXME

=head2 ticket_store

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

