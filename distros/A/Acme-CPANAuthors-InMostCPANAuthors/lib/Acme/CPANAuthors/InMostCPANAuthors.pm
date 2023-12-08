package Acme::CPANAuthors::InMostCPANAuthors;

use strict;
use warnings;

use Acme::CPANAuthors::Register (
    'BINGOS' => '',
    'FLORA' => '',
    'MIYAGAWA' => '',
    'RJBS' => '',
    'SHLOMIF' => '',
    'BARBIE' => '',
    'ETHER' => '',
    'NUFFIN' => '',
    'PEVANS' => '',
    'TOKUHIROM' => '',
    'CORION' => '',
    'DAGOLDEN' => '',
    'DROLSKY' => '',
    'ISHIGAKI' => '',
    'MARCEL' => '',
    'MLEHMANN' => '',
    'SAPER' => '',
    'SMUELLER' => '',
    'TOBYINK' => '',
    'DMAKI' => '',
    'DOLMEN' => '',
    'NEILB' => '',
    'ZOFFIX' => '',
    'DANKOGAI' => '',
    'FRANCKC' => '',
    'GETTY' => '',
    'GUGOD' => '',
    'INGY' => '',
    'KARASIK' => '',
    'KENTNL' => '',
    'MELO' => '',
    'MRAMBERG' => '',
    'NWCLARK' => '',
    'PERLANCAR' => '',
    'SALVA' => '',
    'TIMB' => '',
    'XSAWYERX' => '',
    'ABIGAIL' => '',
    'ADAMK' => '',
    'AMBS' => '',
    'BOBTFISH' => '',
    'BOOK' => '',
    'BURAK' => '',
    'EXODIST' => '',
    'FAYLAND' => '',
    'HINRIK' => '',
    'JQUELIN' => '',
    'JROBINSON' => '',
    'KASEI' => '',
    'KENTARO' => '',
    'MSTROUT' => '',
    'OALDERS' => '',
    'OLIVER' => '',
    'PLICEASE' => '',
    'RENEEB' => '',
    'RGARCIA' => '',
    'RSAVAGE' => '',
    'RURBAN' => '',
    'SHARIFULN' => '',
    'SIMONW' => '',
    'SYP' => '',
    'TINITA' => '',
    'TYPESTER' => '',
);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-28'; # DATE
our $DIST = 'Acme-CPANAuthors-InMostCPANAuthors'; # DIST
our $VERSION = '0.001'; # VERSION

1;
# ABSTRACT: Authors who are listed in Acme::CPANAuthors::* the most

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANAuthors::InMostCPANAuthors - Authors who are listed in Acme::CPANAuthors::* the most

=head1 VERSION

This document describes version 0.001 of Acme::CPANAuthors::InMostCPANAuthors (from Perl distribution Acme-CPANAuthors-InMostCPANAuthors), released on 2023-11-28.

=head1 SYNOPSIS

=head1 DESCRIPTION

This module lists a selection of CPAN authors who are listed in
Acme::CPANAuthors::* the most. Currently the cut-off is 6 modules:

 | author    | num_lists | lists                                                                                                                                                                                                               |
 |-----------+-----------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
 | BINGOS    |        14 | Acme::CPANAuthors::Authors, BackPAN::OneHundred, British, CPAN::OneHundred, CPAN::TopDepended, CPAN::TopDepended::ByOthers, CPANTS::FiveOrMore, DualLife, European, GitHub, MetaSyntactic, POE, Pumpkings, ToBeLike |
 | FLORA     |        11 | Acme::CPANAuthors::Authors, BackPAN::OneHundred, CPAN::OneHundred, CPANTS::FiveOrMore, DebianDev, DualLife, European, German, GitHub, Pumpkings, ToBeLike                                                           |
 | MIYAGAWA  |        11 | AnyEvent, BackPAN::OneHundred, CPAN::OneHundred, CPAN::TopDepended, CPAN::TopDepended::ByOthers, CPANTS::FiveOrMore, CodeRepos, GitHub, Japanese, POE, Pumpkings                                                    |
 | RJBS      |        11 | BackPAN::OneHundred, CPAN::OneHundred, CPAN::TopDepended, CPAN::TopDepended::ByOthers, CPANTS::FiveOrMore, DualLife, GitHub, Misanthrope, POE, Pumpkings, ToBeLike                                                  |
 | SHLOMIF   |        11 | Acme::CPANAuthors::Authors, BackPAN::OneHundred, CPAN::MostScripts, CPAN::OneHundred, CPAN::TopDepended, CPAN::TopDepended::ByOthers, CPANTS::FiveOrMore, GitHub, Israeli, MetaSyntactic, ToBeLike                  |
 | BARBIE    |        10 | Acme::CPANAuthors::Authors, BackPAN::OneHundred, British, CPAN::OneHundred, CPAN::TopDepended, CPAN::TopDepended::ByOthers, CPANTS::FiveOrMore, European, GitHub, POE                                               |
 | ETHER     |        10 | Acme::CPANAuthors::Authors, BackPAN::OneHundred, CPAN::OneHundred, CPAN::TopDepended, CPAN::TopDepended::ByOthers, Canadian, DualLife, GitHub, Nonhuman, POE                                                        |
 | NUFFIN    |        10 | AnyEvent, Austrian, BackPAN::OneHundred, CPAN::OneHundred, CPANTS::FiveOrMore, CodeRepos, European, GitHub, Israeli, POE                                                                                            |
 | PEVANS    |        10 | BackPAN::OneHundred, British, CPAN::OneHundred, CPAN::TopDepended, CPAN::TopDepended::ByOthers, CPANTS::FiveOrMore, DualLife, European, GitHub, POE                                                                 |
 | TOKUHIROM |        10 | AnyEvent, BackPAN::OneHundred, CPAN::OneHundred, CPAN::TopDepended, CPAN::TopDepended::ByOthers, CPANTS::FiveOrMore, CodeRepos, GitHub, Japanese, ToBeLike                                                          |
 | CORION    |         9 | CPAN::MostScripts, CPAN::TopDepended, CPAN::TopDepended::ByOthers, CPANTS::FiveOrMore, DualLife, European, German, GitHub, Pumpkings                                                                                |
 | DAGOLDEN  |         9 | BackPAN::OneHundred, CPAN::OneHundred, CPAN::TopDepended, CPAN::TopDepended::ByOthers, CPANTS::FiveOrMore, DualLife, GitHub, Pumpkings, ToBeLike                                                                    |
 | DROLSKY   |         9 | BackPAN::OneHundred, CPAN::OneHundred, CPAN::TopDepended, CPAN::TopDepended::ByOthers, CPANTS::FiveOrMore, CodeRepos, DualLife, GitHub, Pumpkings                                                                   |
 | ISHIGAKI  |         9 | Acme::CPANAuthors::Authors, CPAN::TopDepended, CPAN::TopDepended::ByOthers, CPANTS::FiveOrMore, CodeRepos, DualLife, GitHub, Japanese, POE                                                                          |
 | MARCEL    |         9 | Acme::CPANAuthors::Authors, Austrian, BackPAN::OneHundred, CPAN::OneHundred, CPANTS::FiveOrMore, CodeRepos, European, GitHub, ToBeLike                                                                              |
 | MLEHMANN  |         9 | AnyEvent, BackPAN::OneHundred, CPAN::OneHundred, CPAN::TopDepended, CPAN::TopDepended::ByOthers, CPANTS::FiveOrMore, European, German, POE                                                                          |
 | SAPER     |         9 | Acme::CPANAuthors::Authors, CPANTS::FiveOrMore, DebianDev, DualLife, European, French, GitHub, MetaSyntactic, POE                                                                                                   |
 | SMUELLER  |         9 | BackPAN::OneHundred, CPAN::OneHundred, CPAN::TopDepended, CPAN::TopDepended::ByOthers, CPANTS::FiveOrMore, DualLife, European, German, GitHub                                                                       |
 | TOBYINK   |         9 | Australian, BackPAN::OneHundred, British, CPAN::OneHundred, CPAN::TopDepended, CPAN::TopDepended::ByOthers, CPANTS::FiveOrMore, European, GitHub                                                                    |
 | DMAKI     |         8 | AnyEvent, BackPAN::OneHundred, CPAN::OneHundred, CPANTS::FiveOrMore, CodeRepos, GitHub, Japanese, POE                                                                                                               |
 | DOLMEN    |         8 | CPAN::TopDepended, CPAN::TopDepended::ByOthers, CPANTS::FiveOrMore, European, French, GitHub, Nonhuman, POE                                                                                                         |
 | NEILB     |         8 | BackPAN::OneHundred, British, CPAN::OneHundred, CPAN::TopDepended, CPAN::TopDepended::ByOthers, DualLife, European, GitHub                                                                                          |
 | ZOFFIX    |         8 | Acme::CPANAuthors::Authors, BackPAN::OneHundred, CPANTS::FiveOrMore, Canadian, European, GitHub, POE, Russian                                                                                                       |
 | DANKOGAI  |         7 | CPAN::TopDepended, CPAN::TopDepended::ByOthers, CPANTS::FiveOrMore, CodeRepos, DualLife, GitHub, Japanese                                                                                                           |
 | FRANCKC   |         7 | AnyEvent, CPANTS::FiveOrMore, DebianDev, European, French, GitHub, POE                                                                                                                                              |
 | GETTY     |         7 | BackPAN::OneHundred, CPAN::MostScripts, European, German, GitHub, POE, ToBeLike                                                                                                                                     |
 | GUGOD     |         7 | Acme::CPANAuthors::Authors, AnyEvent, BackPAN::OneHundred, CPAN::OneHundred, CPANTS::FiveOrMore, GitHub, Taiwanese                                                                                                  |
 | INGY      |         7 | BackPAN::OneHundred, CPAN::MostScripts, CPAN::OneHundred, CPAN::TopDepended, CPANTS::FiveOrMore, DebianDev, GitHub                                                                                                  |
 | KARASIK   |         7 | AnyEvent, CPANTS::FiveOrMore, Danish, European, GitHub, POE, Russian                                                                                                                                                |
 | KENTNL    |         7 | BackPAN::OneHundred, CPAN::OneHundred, CPAN::TopDepended, CPAN::TopDepended::ByOthers, CPANTS::FiveOrMore, GitHub, MBTI::INTP                                                                                       |
 | MELO      |         7 | AnyEvent, CPANTS::FiveOrMore, European, GitHub, POE, Portuguese, ToBeLike                                                                                                                                           |
 | MRAMBERG  |         7 | BackPAN::OneHundred, CPAN::OneHundred, CPANTS::FiveOrMore, CodeRepos, European, GitHub, Norwegian                                                                                                                   |
 | NWCLARK   |         7 | British, CPAN::TopDepended, CPAN::TopDepended::ByOthers, CPANTS::FiveOrMore, DualLife, European, Pumpkings                                                                                                          |
 | PERLANCAR |         7 | BackPAN::OneHundred, CPAN::MostScripts, CPAN::OneHundred, CPAN::TopDepended, GitHub, Indonesian, MetaSyntactic                                                                                                      |
 | SALVA     |         7 | Acme::CPANAuthors::Authors, BackPAN::OneHundred, CPAN::OneHundred, CPANTS::FiveOrMore, DualLife, GitHub, Spanish                                                                                                    |
 | TIMB      |         7 | British, CPAN::TopDepended, CPAN::TopDepended::ByOthers, CPANTS::FiveOrMore, European, GitHub, Pumpkings                                                                                                            |
 | XSAWYERX  |         7 | CPAN::TopDepended, CPAN::TopDepended::ByOthers, CPANTS::FiveOrMore, DebianDev, DualLife, GitHub, POE                                                                                                                |
 | ABIGAIL   |         6 | Acme::CPANAuthors::Authors, CPANTS::FiveOrMore, European, GitHub, MetaSyntactic, Pumpkings                                                                                                                          |
 | ADAMK     |         6 | BackPAN::OneHundred, CPAN::MostScripts, CPAN::OneHundred, CPANTS::FiveOrMore, GitHub, POE                                                                                                                           |
 | AMBS      |         6 | CPAN::MostScripts, CPANTS::FiveOrMore, DualLife, European, GitHub, Portuguese                                                                                                                                       |
 | BOBTFISH  |         6 | BackPAN::OneHundred, British, CPAN::OneHundred, CPANTS::FiveOrMore, European, GitHub                                                                                                                                |
 | BOOK      |         6 | CPANTS::FiveOrMore, European, French, GitHub, MetaSyntactic, POE                                                                                                                                                    |
 | BURAK     |         6 | Acme::CPANAuthors::Authors, CPANTS::FiveOrMore, European, GitHub, ToBeLike, Turkish                                                                                                                                 |
 | EXODIST   |         6 | BackPAN::OneHundred, CPAN::TopDepended, CPAN::TopDepended::ByOthers, CPANTS::FiveOrMore, DualLife, GitHub                                                                                                           |
 | FAYLAND   |         6 | Acme::CPANAuthors::Authors, BackPAN::OneHundred, CPAN::OneHundred, CPANTS::FiveOrMore, Chinese, GitHub                                                                                                              |
 | HINRIK    |         6 | Acme::CPANAuthors::Authors, CPANTS::FiveOrMore, European, GitHub, Icelandic, POE                                                                                                                                    |
 | JQUELIN   |         6 | CPANTS::FiveOrMore, European, French, GitHub, MetaSyntactic, POE                                                                                                                                                    |
 | JROBINSON |         6 | British, CPANTS::FiveOrMore, CodeRepos, European, GitHub, POE                                                                                                                                                       |
 | KASEI     |         6 | British, CPAN::TopDepended, CPAN::TopDepended::ByOthers, CPANTS::FiveOrMore, European, GitHub                                                                                                                       |
 | KENTARO   |         6 | Acme::CPANAuthors::Authors, CPANTS::FiveOrMore, CodeRepos, GeekHouse, GitHub, Japanese                                                                                                                              |
 | MSTROUT   |         6 | British, CPANTS::FiveOrMore, CodeRepos, European, Misanthrope, Pumpkings                                                                                                                                            |
 | OALDERS   |         6 | CPAN::TopDepended, CPAN::TopDepended::ByOthers, CPANTS::FiveOrMore, Canadian, GitHub, POE                                                                                                                           |
 | OLIVER    |         6 | British, CPAN::MostScripts, CPANTS::FiveOrMore, DebianDev, European, GitHub                                                                                                                                         |
 | PLICEASE  |         6 | BackPAN::OneHundred, CPAN::MostScripts, CPAN::OneHundred, CPAN::TopDepended, CPAN::TopDepended::ByOthers, GitHub                                                                                                    |
 | RENEEB    |         6 | BackPAN::OneHundred, CPAN::OneHundred, CPANTS::FiveOrMore, European, German, GitHub                                                                                                                                 |
 | RGARCIA   |         6 | CPANTS::FiveOrMore, DualLife, European, French, GitHub, Pumpkings                                                                                                                                                   |
 | RSAVAGE   |         6 | Australian, BackPAN::OneHundred, CPAN::MostScripts, CPAN::OneHundred, CPANTS::FiveOrMore, GitHub                                                                                                                    |
 | RURBAN    |         6 | Austrian, CPAN::TopDepended::ByOthers, CPANTS::FiveOrMore, DualLife, European, GitHub                                                                                                                               |
 | SHARIFULN |         6 | Acme::CPANAuthors::Authors, CPANTS::FiveOrMore, European, GitHub, POE, Russian                                                                                                                                      |
 | SIMONW    |         6 | British, CPANTS::FiveOrMore, DualLife, European, GitHub, POE                                                                                                                                                        |
 | SYP       |         6 | Brazilian, CPAN::TopDepended, CPAN::TopDepended::ByOthers, European, GitHub, Russian                                                                                                                                |
 | TINITA    |         6 | CPAN::TopDepended, CPAN::TopDepended::ByOthers, CPANTS::FiveOrMore, European, German, GitHub                                                                                                                        |
 | TYPESTER  |         6 | AnyEvent, CPANTS::FiveOrMore, CodeRepos, GitHub, Japanese, POE                                                                                                                                                      |

Note: Some lists are excluded (see this distribution's C<devscript/update-data>
for more details).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANAuthors-InMostCPANAuthors>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANAuthors-InMostCPANAuthors>.

=head1 SEE ALSO

L<Acme::CPANAuthors> - Main class to manipulate this one.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANAuthors-InMostCPANAuthors>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
