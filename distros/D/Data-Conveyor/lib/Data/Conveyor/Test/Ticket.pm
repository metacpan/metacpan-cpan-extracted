use 5.008;
use strict;
use warnings;

package Data::Conveyor::Test::Ticket;
BEGIN {
  $Data::Conveyor::Test::Ticket::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

# Utilities for writing tests pertaining to tickets.
use Error::Hierarchy::Util 'assert_defined';
use parent 'Class::Scaffold::Storable';
use constant TST_EMAIL => 'fh@univie.ac.at';

sub make_whole_ticket {
    my $self = shift;
    my %args = @_ == 1 ? %{ $_[0] } : @_;
    assert_defined $self->delegate, 'called without delegate.';
    our $cnt;
    $cnt++;
    my $ticket_args = {
        $self->delegate->DEFAULT_TICKET_PROPERTIES,
        ticket_no => $args{ticket_no}
          || $self->gen_temp_ticket_no(suffix => $cnt),
        type   => $self->delegate->TT_PERSCREATE,
        origin => $self->delegate->OR_TEST,
        cltid  => $self->gen_temp_ticket_no(suffix => $cnt),
        %{ $args{ticket} },
    };
    my $ticket = $self->delegate->make_obj('ticket', %$ticket_args);
    if ($args{facets}) {

        while (my ($key, $value) = each %{ $args{facets} }) {
            $ticket->facets->$key($value);
        }
    }
    if ($args{default_rc}) {
        $ticket->set_default_rc($args{default_rc});
    }
    if ($args{default_status}) {
        $ticket->set_default_status($args{default_status});
    }
    if (exists $args{payload} && exists $args{payload}{transactions}) {
        for my $payload_tx ($args{payload}->transactions) {
            my $item_spec = $payload_tx->transaction->payload_item;
            next if ref $item_spec;
            if ($item_spec =~ /^(\w+)\.(\d+)$/) {
                my ($accessor, $index) = ($1, $2 - 1);
                next
                  unless $payload_tx->transaction->status eq
                      $self->delegate->TXS_ERROR;
                $args{payload}->$accessor->[$index]
                  ->exception_container->record(
                    'Class::Value::Contact::Exception::Email',
                    email       => 'exception set by make_whole_ticket',
                    is_optional => 1,
                  );
            }
        }
    }
    $ticket->payload($args{payload});
    $ticket;
}

sub gen_temp_ticket_no {
    my $self = shift;
    my %args = @_;

    # Make sure the pid has a maxlen of 5 digits and is zero-padded.
    # Also the suffix has to be a number and has a maxlen of 4, also
    # zero-padded.
    our $temp_ticket_no_prefix ||= '200101010101';
    $args{prefix} ||= $temp_ticket_no_prefix++;
    sprintf "%s.%05d%04d", $args{prefix}, substr($$, -5),
      substr($args{suffix} || int(rand 10000), -4);
}
1;


__END__
=pod

=head1 NAME

Data::Conveyor::Test::Ticket - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

=head1 METHODS

=head2 gen_temp_ticket_no

FIXME

=head2 make_whole_ticket

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

