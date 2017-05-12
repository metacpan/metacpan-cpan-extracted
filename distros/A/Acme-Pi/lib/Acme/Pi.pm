use strict;
use warnings;
package Acme::Pi;
# ABSTRACT: Mmm, pie
# vim: set ts=8 sts=4 sw=4 tw=115 et :

use utf8;

my $version = atan2(1,1) * 4; $Acme::Pi::VERSION = substr("$version", 0, 16);

use Exporter 5.57 'import';
our @EXPORT = ('$π');
our $π = atan2(1,1) * 4;

1;
__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::Pi - Mmm, pie

=head1 VERSION

version 3.14159265358979

=head1 SYNOPSIS

    use Acme::Pi;

    my $area = $π * $radius**2;

=head1 DESCRIPTION

This distribution was created to celebrate L<Pi Day|http://www.piday.org/> 2014,
as well as to demonstrate yet another example of a pathological C<$VERSION>.

Additionally, it exports a single variable, C<$π>, defined as:

    atan2(1,1) * 4;

This module also defines its own C<$VERSION> as π.
It is intended that version parsers in the toolchain (L<Module::Metadata>,
L<ExtUtils::MakeMaker>'s C<< MM->parse_version >>, L<Parse::PMFile>) should
be capable of statically parsing this package's C<$VERSION>.

=head1 ACKNOWLEDGEMENTS

=for stopwords QA Hackathon

This module was brought to you by the
L<2014 QA Hackathon in Lyon, France|http://act.qa-hackathon.org/qa2014>, as well as
the number L<π|http://en.wikipedia.org/wiki/Pi>.

=head1 AFTERWORD

          3.141592653589793238462643383279
        5028841971693993751058209749445923
       07816406286208998628034825342117067
       9821    48086         5132
      823      06647        09384
     46        09550        58223
     17        25359        4081
               2848         1117
               4502         8410
               2701         9385
              21105        55964
              46229        48954
              9303         81964
              4288         10975
             66593         34461
            284756         48233
            78678          31652        71
           2019091         456485       66
          9234603           48610454326648
         2133936            0726024914127
         3724587             00660631558
         817488               152092096

=head1 SEE ALSO

=over 4

=item *

L<David Golden: Real $VERSIONs on CPAN|http://www.dagolden.com/index.php/2191/real-versions-on-cpan/>

=item *

L<David Golden: version numbers should be boring|http://www.dagolden.com/index.php/369/version-numbers-should-be-boring/>

=item *

L<Dinosaur comics on Pi Day|http://www.qwantz.com/index.php?comic=955>

=item *

L<Usage of pi in TeX versions|http://en.wikipedia.org/wiki/TeX#History>

=item *

L<lambda/λ>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-Pi>
(or L<bug-Acme-Pi@rt.cpan.org|mailto:bug-Acme-Pi@rt.cpan.org>).

I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
