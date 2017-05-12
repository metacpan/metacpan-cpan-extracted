use 5.008;
use strict;
use warnings;

package Data::Conveyor::Value::Ticket::Number;
BEGIN {
  $Data::Conveyor::Value::Ticket::Number::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

use Date::Calc qw/Today_and_Now Decode_Date_US/;
use parent 'Class::Value';

sub is_well_formed_value {
    my ($self, $value) = @_;
    $self->SUPER::is_well_formed_value($value) && $value =~ /^\d{12}\.\d{9}$/;
}

sub new_from_now {
    my $self = shift;
    $self->new(value =>
          sprintf('%04d%02d%02d%02d%02d.%09d', (Today_and_Now)[ 0 .. 4 ], 0));
}

sub new_from_date {
    my ($self, $date) = @_;
    if ($date =~ /^\d{8}$/) {
        $date .= '0000.000000000';
    } else {
        $date =
          sprintf('%04d%02d%02d%02d%02d.%09d', Decode_Date_US($date), 0, 0, 0);
    }
    $self->new(value => $date);
}
1;


__END__
=pod

=head1 NAME

Data::Conveyor::Value::Ticket::Number - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

=head1 METHODS

=head2 is_well_formed_value

FIXME

=head2 new_from_date

FIXME

=head2 new_from_now

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

