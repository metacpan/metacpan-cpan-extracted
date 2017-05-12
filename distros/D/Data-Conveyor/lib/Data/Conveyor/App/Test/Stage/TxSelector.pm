use 5.008;
use strict;
use warnings;

package Data::Conveyor::App::Test::Stage::TxSelector;
BEGIN {
  $Data::Conveyor::App::Test::Stage::TxSelector::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

use Test::More;
use Data::Dumper;
use parent 'Data::Conveyor::App::Test::Stage';
use constant DEFAULTS => (expected_stage_const => 'ST_TXSEL',);

sub plan_test {
    my ($self, $test, $run) = @_;
    $self->plan_ticket_expected_container($test, $run) + 1;
}

sub test_expectations {
    my $self = shift;
    $self->SUPER::test_expectations(@_);
    $self->check_ticket_expected_container;
    is_deeply_flex(
        $self->ticket->payload->comparable,
        $self->expect->{payload}->comparable,
        'resulting payload'
    ) or print Dumper $self->ticket->payload->comparable;
}
1;


__END__
=pod

=head1 NAME

Data::Conveyor::App::Test::Stage::TxSelector - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

=head1 METHODS

=head2 plan_test

FIXME

=head2 test_expectations

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

