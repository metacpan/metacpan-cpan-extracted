use 5.008;
use strict;
use warnings;

package Data::Conveyor::Ticket::Payload::Common_TEST;
BEGIN {
  $Data::Conveyor::Ticket::Payload::Common_TEST::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

use Test::More;
use parent 'Data::Conveyor::Test';

sub PLAN {
    my $self = shift;

    # $::delegate->TS and ->RC in numeric context return the arrayref
    $::delegate->TS_COUNT + $::delegate->RC_COUNT + 4;
}

sub run {
    my $self = shift;
    $self->SUPER::run(@_);
    my $obj = $self->make_real_object;
    $self->obj_ok($obj->default_rc,     'value_ticket_rc');
    $self->obj_ok($obj->default_status, 'value_ticket_status');
    my $ticket = $self->delegate->make_obj('ticket');
    is($obj->rc($ticket), $self->delegate->RC_OK,
        'rc without exceptions is RC_OK');
    is( $obj->status($ticket),
        $self->delegate->TS_RUNNING,
        'status without exceptions is TS_RUNNING'
    );

    for my $rc (sort $self->delegate->RC) {
        $obj->default_rc($rc);
        is($obj->rc($ticket), $rc, "effect of default [$rc] on rc");
    }
    for my $status (sort $self->delegate->TS) {
        $obj->default_status($status);
        is($obj->status($ticket), $status,
            "effect of default [$status] on status");
    }
}
1;


__END__
=pod

=head1 NAME

Data::Conveyor::Ticket::Payload::Common_TEST - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

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

