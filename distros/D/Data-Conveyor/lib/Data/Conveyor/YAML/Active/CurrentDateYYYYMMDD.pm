use 5.008;
use strict;
use warnings;

package Data::Conveyor::YAML::Active::CurrentDateYYYYMMDD;
BEGIN {
  $Data::Conveyor::YAML::Active::CurrentDateYYYYMMDD::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

use YAML::Active qw/assert_hashref hash_activate/;
use parent 'Class::Scaffold::YAML::Active';

sub yaml_activate {
    my ($self, $phase) = @_;
    assert_hashref($self);
    my $hash = hash_activate($self, $phase);
    my ($y, $m, $d) = sub { $_[5] + 1900, $_[4] + 1, $_[3] }
      ->(localtime);
    exists $hash->{year}  and $y += $hash->{year};
    exists $hash->{month} and $m += $hash->{month};
    exists $hash->{day}   and $d += $hash->{day};
    sprintf "%4d%02d%02d", $y, $m, $d;
}
1;


__END__
=pod

=head1 NAME

Data::Conveyor::YAML::Active::CurrentDateYYYYMMDD - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

=head1 METHODS

=head2 yaml_activate

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

