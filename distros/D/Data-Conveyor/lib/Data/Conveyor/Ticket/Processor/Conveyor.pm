use 5.008;
use strict;
use warnings;

package Data::Conveyor::Ticket::Processor::Conveyor;
BEGIN {
  $Data::Conveyor::Ticket::Processor::Conveyor::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

use parent 'Class::Scaffold::Storable';
__PACKAGE__->mk_framework_object_accessors(ticket => 'ticket')
  ->mk_scalar_accessors(qw(poll_delegate))
  ->mk_boolean_accessors(qw(transactional_authority));

# the poll delegate allows the upper service layer to interrupt processing
# by throwing an exception, if it thinks it is necessary.
use constant DEFAULTS => (transactional_authority => 1);

sub run {
    my $self           = shift;
    my $previous_stage = '';
    while ($self->ticket->stage ne $previous_stage) {
        last if $self->ticket->stage eq $self->delegate->FINAL_TICKET_STAGE;
        $previous_stage = $self->ticket->stage;
        if (   $self->poll_delegate
            && $self->poll_delegate->can('callback')) {
            $self->poll_delegate->callback($self->ticket);
        }

        # We need to set the ticket to active, because it won't have been
        # open()ed - we just process a ticket from start to end, without
        # repeatedly writing and re-reading it.
        $self->ticket->stage->set_active;
        $self->delegate->make_obj('ticket_dispatcher')
          ->new(transactional_authority => $self->transactional_authority)
          ->dispatch($self->ticket);
    }
    $self->ticket->store;
}
1;


__END__
=pod

=head1 NAME

Data::Conveyor::Ticket::Processor::Conveyor - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

=head1 METHODS

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

