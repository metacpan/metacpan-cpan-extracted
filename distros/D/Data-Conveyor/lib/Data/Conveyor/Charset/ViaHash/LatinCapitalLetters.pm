use 5.008;
use strict;
use warnings;

package Data::Conveyor::Charset::ViaHash::LatinCapitalLetters;
BEGIN {
  $Data::Conveyor::Charset::ViaHash::LatinCapitalLetters::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

use parent 'Data::Conveyor::Charset::ViaHash';
use constant CHARACTERS => (
    A => 'LATIN CAPITAL LETTER A',
    B => 'LATIN CAPITAL LETTER B',
    C => 'LATIN CAPITAL LETTER C',
    D => 'LATIN CAPITAL LETTER D',
    E => 'LATIN CAPITAL LETTER E',
    F => 'LATIN CAPITAL LETTER F',
    G => 'LATIN CAPITAL LETTER G',
    H => 'LATIN CAPITAL LETTER H',
    I => 'LATIN CAPITAL LETTER I',
    J => 'LATIN CAPITAL LETTER J',
    K => 'LATIN CAPITAL LETTER K',
    L => 'LATIN CAPITAL LETTER L',
    M => 'LATIN CAPITAL LETTER M',
    N => 'LATIN CAPITAL LETTER N',
    O => 'LATIN CAPITAL LETTER O',
    P => 'LATIN CAPITAL LETTER P',
    Q => 'LATIN CAPITAL LETTER Q',
    R => 'LATIN CAPITAL LETTER R',
    S => 'LATIN CAPITAL LETTER S',
    T => 'LATIN CAPITAL LETTER T',
    U => 'LATIN CAPITAL LETTER U',
    V => 'LATIN CAPITAL LETTER V',
    W => 'LATIN CAPITAL LETTER W',
    X => 'LATIN CAPITAL LETTER X',
    Y => 'LATIN CAPITAL LETTER Y',
    Z => 'LATIN CAPITAL LETTER Z',
);
1;


__END__
=pod

=head1 NAME

Data::Conveyor::Charset::ViaHash::LatinCapitalLetters - Stage-based conveyor-belt-like ticket handling system

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

