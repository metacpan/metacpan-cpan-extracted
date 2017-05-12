use 5.008;
use strict;
use warnings;

package Data::Conveyor::Charset::ViaHash::ASCIIPunctuation;
BEGIN {
  $Data::Conveyor::Charset::ViaHash::ASCIIPunctuation::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

use parent 'Data::Conveyor::Charset::ViaHash';
use constant CHARACTERS => (

    # 0x0020 - 0x007E
    #
    # (without all characters imported from
    # Registry::Charset::ViaHash::LatinSmallLetters,
    # Registry::Charset::ViaHash::LatinCapitalLetters and
    # Registry::Charset::ViaHash::Digits)
    '0020' => 'SPACE',
    '0021' => 'EXCLAMATION MARK',
    '0022' => 'QUOTATION MARK',
    '0023' => 'NUMBER SIGN',
    '0024' => 'DOLLAR SIGN',
    '0025' => 'PERCENT SIGN',
    '0026' => 'AMPERSAND',
    '0027' => 'APOSTROPHE',
    '0028' => 'LEFT PARENTHESIS',
    '0029' => 'RIGHT PARENTHESIS',
    '002A' => 'ASTERISK',
    '002B' => 'PLUS SIGN',
    '002C' => 'COMMA',
    '002D' => 'HYPHEN-MINUS',
    '002E' => 'FULL STOP',
    '002F' => 'SOLIDUS',
    '003A' => 'COLON',
    '003B' => 'SEMICOLON',
    '003C' => 'LESS-THAN SIGN',
    '003D' => 'EQUALS SIGN',
    '003E' => 'GREATER-THAN SIGN',
    '003F' => 'QUESTION MARK',
    '0040' => 'COMMERCIAL AT',
    '005B' => 'LEFT SQUARE BRACKET',
    '005C' => 'REVERSE SOLIDUS',
    '005D' => 'RIGHT SQUARE BRACKET',
    '005E' => 'CIRCUMFLEX ACCENT',
    '005F' => 'LOW LINE',
    '0060' => 'GRAVE ACCENT',
    '007B' => 'LEFT CURLY BRACKET',
    '007C' => 'VERTICAL LINE',
    '007D' => 'RIGHT CURLY BRACKET',
    '007E' => 'TILDE',
);
1;


__END__
=pod

=head1 NAME

Data::Conveyor::Charset::ViaHash::ASCIIPunctuation - Stage-based conveyor-belt-like ticket handling system

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

