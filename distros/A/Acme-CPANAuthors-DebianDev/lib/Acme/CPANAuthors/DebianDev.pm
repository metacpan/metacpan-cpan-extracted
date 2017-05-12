package Acme::CPANAuthors::DebianDev;
$Acme::CPANAuthors::DebianDev::VERSION = '1.000';
use 5.006;
use strict;
use warnings;

use Acme::CPANAuthors::Register (
    ABE           =>   "Axel Beckert",
    ALEXBIO       =>   "Alessandro Ghedini",
    ALEXM         =>   "Alex Muntada",
    AMARSCHKE     =>   "Andreas Marschke",
    ARUN          =>   "Arun Venkataraman",
    BAS           =>   "Bas Zoetekouw",
    BBYRD         =>   "Brendan Byrd",
    BOGDAN        =>   "Bogdan Lucaciu",
    BRICAS        =>   "Brian Cassidy",
    CHILTS        =>   "Andrew Chilton",
    CJCOLLIER     =>   "C.J. Adams-Collier",
    COOK          =>   "Kees Cook",
    COSIMO        =>   "Cosimo Streppone",
    CVICENTE      =>   "Carlos Vicente",
    DAMOG         =>   "David Moreno",
    DAXIM         =>   "Lars D\x{26a}\x{1d07}\x{1d04}\x{1d0b}\x{1d0f}\x{1d21} \x{8fea}\x{62c9}\x{65af} (Lars Dieckow)",
    DDEIMEKE      =>   "Dirk Deimeke",
    DDUMONT       =>   "Dominique Dumont",
    DEEPAK        =>   "Deepak Tripathi",                # ID exists, but no modules
    DEXTER        =>   "Piotr Roszatycki",
    DIOCLES       =>   "Tim Retout",
    DKG           =>   "Daniel Kahn Gillmor",
    DKOGAN        =>   "Dima Kogan",
    DLINTOTT      =>   "Daniel Lintott",                 # ID exists, but no modules
    DOM           =>   "Dominic Hargreaves",
    DOMINIX       =>   "DominiX",                        # ID exists, but no modules
    DWILSON       =>   "Dean Wilson",
    EDWARD        =>   "Edward Betts",
    EREZ          =>   "Erez Schatz",
    EZRA          =>   "Ezra Pagel",
    FANGLY        =>   "Florent Angly",
    FCECCONI      =>   "Francesco Cecconi",
    FLORA         =>   "Florian Ragwitz",
    FRANCKC       =>   "Franck Cuny",
    FRL           =>   "Frank Lichtenheld",              # ID exists, but no modules
    GANGLION      =>   "Joel Roth",
    GLAUCO        =>   "THIAGO GLAUCO SANCHEZ",          # ID exists, but no modules
    GUIMARD       =>   "Xavier Guimard",
    HACHI         =>   "Jonathan Steinert",
    HAGGAI        =>   "Alan Haggai Alavi",
    HORNBURG      =>   "Stefan Hornburg (Racke)",
    INGY          =>   "Ingy d\x{f6}t Net (Ingy dot Net)",
    INTRIGERI     =>   "intrigeri",                      # ID exists, but no modules
    IOANR         =>   "Ioan Rogers",
    IVAN          =>   "Ivan Kohler",
    JALDHAR       =>   "\x{a9c}\x{ab2}\x{aa7}\x{ab0} \x{ab9}. \x{ab5}\x{acd}\x{aaf}\x{abe}\x{ab8} (Jaldhar H. Vyas)",
    JAME          =>   "Robert James Clay",
    JAWNSY        =>   "Jonathan Yu",
    JAYBONCI      =>   "Jay Bonci",
    JEB           =>   "James Bromberger",
    JEREMIAH      =>   "Jeremiah Foster",
    JKUTEJ        =>   "Jozef Kutej",
    JMEHNLE       =>   "Julian Mehnle",
    JOENIO        =>   "Joenio Costa",
    JOEY          =>   "Joey Hess",
    JONASS        =>   "Jonas Smedegaard",               # ID exists, but no modules
    JURUEN        =>   "Javier Uruen Val",
    KBLIN         =>   "Kai Blin",                       # ID exists, but no modules
    KHAREC        =>   "Sandro CAZZANIGA",
    KIMMEL        =>   "Kirk KImmel",                    # ID exists, but no modules
    KJETILK       =>   "Kjetil Kjernsmo",
    KRZKRZ        =>   "Krzysztof Krzy\x{17c}aniak (Krzysztof Krzyzaniak)", # ID exists, but no modules
    LAWSONK       =>   "Keith Lawson",
    LIGHTSEY      =>   "John Lightsey",
    LKUNDRAK      =>   "Lubomir Rintel",
    MARCC         =>   "Marc Chantreux",
    MGV           =>   "Marius Gavrilescu",
    MMJB          =>   "Marc Brockschmidt",              # ID exists, but no modules
    MOGAAL        =>   "Alejandro Garrido Mota",
    MSTPLBG       =>   "Michael Stapelberg",
    MXEY          =>   "Maximilian Ga\x{df} (Maximilian Gass)",
    MZEHRER       =>   "Michael Zehrer",                 # ID exists, but no modules
    NPF           =>   "Pierre Neyron",                  # ID exists, but no modules
    OLIVER        =>   "Oliver Gorwits",
    OLLY          =>   "Olly Betts",
    OLOF          =>   "Olof Johansson",
    ONLYJOB       =>   "Dmitry Smirnov",
    ONUR          =>   "Onur Aslan",
    PIETSCH       =>   "Christian Pietsch",              # ID exists, but no modules
    PJF           =>   "Paul Jamieson Fenwick",
    PMAKHOLM      =>   "Peter Makholm",
    POTYL         =>   "Emmanuel Rodriguez",
    RATCLIFFE     =>   "Jeffrey Ratcliffe",
    RICHIH        =>   "Richard Michael Hartmann",       # ID exists, but no modules
    RICK          =>   "Rick Scott",
    RKITOVER      =>   "Rafael Kitover",
    ROAM          =>   "Peter Pentchev",
    RRA           =>   "Russ Allbery",
    RSHADOW       =>   "Roman V. Nikolaev",
    RSN           =>   "Ryan Niebur",
    SAPER         =>   "S\x{e9}bastien Aperghis-Tramoni (Sebastien Aperghis-Tramoni)",
    SILASMONK     =>   "Nicholas Bamber",
    SJQUINNEY     =>   "Stephen Quinney",
    SMASH         =>   "Nuno Carvalho",
    SSM           =>   "Stig Sandbeck Mathisen",
    SUKRIA        =>   "Alexis Sukrieh",
    TEX           =>   "Dominik Schulz",
    UNERA         =>   "Dmitry E. Oboukhov",
    VDANJEAN      =>   "Vincent Danjean",
    WALLMARI      =>   "Richard Wallman",
    WILSOND       =>   "Dusty Wilson",
    WSDOOKADR     =>   "Petrea Corneliu \x{15e}tefan (Petrea Corneliu Stefan)",
    XSAWYERX      =>   "Sawyer X",
    YVESAGO       =>   "Yves Agostini",
    ZACS          =>   "S. Zachariah Sprackett",
    ZAKAME        =>   "Zak B. Elep",
);

'alioth';

__END__

=head1 NAME

Acme::CPANAuthors::DebianDev - CPAN authors who are Debian Developers

=head1 SYNOPSIS

    use Acme::CPANAuthors;

    my $authors  = Acme::CPANAuthors->new("DebianDev");

    my $number   = $authors->count;
    my @ids      = $authors->id;
    my @distros  = $authors->distributions("DDUMONT");
    my $url      = $authors->avatar_url("DDUMONT");
    my $kwalitee = $authors->kwalitee("DDUMONT");
    my $name     = $authors->name("DDUMONT");

See documentation for L<Acme::CPANAuthors> for more details.

=head1 DESCRIPTION

This class provides a hash of CPAN authors who are also Debian Developers
to the L<Acme::CPANAuthors> module.

=head1 RATIONALE

Although it lives in the C<Acme> namespace, this module was created for
a useful purpose: L<https://github.com/CPAN-API/cpan-api/issues/325>.

=head1 DATA SOURCE

The list is created with the help of the Debian
Perl Group member list, which is available at
L<https://alioth.debian.org/project/memberlist.php?group_id=30274>.

=head1 AUTHOR

Philippe Bruhat (BooK), C<book@cpan.org>.

=head1 COPYRIGHT

Copyright 2014, Philippe Bruhat (BooK).

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
