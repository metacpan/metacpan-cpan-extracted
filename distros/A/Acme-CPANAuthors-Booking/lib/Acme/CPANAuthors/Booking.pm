package Acme::CPANAuthors::Booking;

use 5.006;
use strict;
use warnings;
no  warnings 'syntax';

our $VERSION = '2016073001';

use Acme::CPANAuthors::Register (
    ALEXT         =>   "Alex Timoshenko",                # ID exists, but no modules
    ANDRE         =>   "Andr\x{e9} Walker (Andre Walker)",
    ANDREASG      =>   "Andreas Gu\x{f0}mundsson (Andreas Gudmundsson)",
    APOC          =>   "Victor Apocalypse Rodrigues",    # ID exists, but no modules
    AVAR          =>   "\x{c6}var Arnfj\x{f6}r\x{f0} Bjarmason (AEvar Arnfjord Bjarmason)",
    AVEREHA       =>   "Andrei Vereha",                  # ID exists, but no modules
    BDEVETAK      =>   "Bosko Devetak",
    BLOM          =>   "Menno Blom",
    BOOK          =>   "Philippe Bruhat (BooK)",
    BRUNORC       =>   "Bruno Czekay",
    BRUNOV        =>   "Bruno Vecchi",
    BTYLER        =>   "Ben Tyler",
    BUCCIA        =>   "Fernando Vezzosi",               # ID exists, but no modules
    BURAK         =>   "Burak G\x{fc}rsoy (Burak Gursoy)",
    CADAVIS       =>   "Chad A Davis",
    CAIO          =>   "Caio Rom\x{e3}o Costa Nascimento (Caio Romao Costa Nascimento)",
    CANECA        =>   "Matheus Victor Brum Soares",     # ID exists, but no modules
    CEADE         =>   "Chris Eade",                     # ID exists, but no modules
    CERONMAN      =>   "Manuel Cer\x{f3}n",              # ID exists, but no modules
    CGARCIA       =>   "Claudio Garcia",
    DAMOG         =>   "David Moreno",
    DAMS          =>   "Damien Krotkine",
    DEEPAKG       =>   "Deepak Gulati",
    DENIK         =>   "Denis Bilenko",
    DGRYSKI       =>   "Damian Gryski",
    EHERMAN       =>   "Eric Herman",
    FARO          =>   "Tiago Faro Pedroso",             # ID exists, but no modules
    FGLOCK        =>   "Fl\x{e1}vio Soibelmann Glock (Flavio Soibelmann Glock)",
    FREEMANSR     =>   "Mihajlo An\x{111}elkovi\x{107}", # ID exists, but no modules
    GGOUDSMIT     =>   "Gilion Goudsmit",
    GONZUS        =>   "Gonzalo Diethelm",
    GOODGUY       =>   "Valery Sukhomlinov",             # ID exists, but no modules
    GRBHAT        =>   "Gurunandan Bhat",
    GUGOD         =>   "\x{5289}\x{5eb7}\x{6c11} (Liu Kang Min)",
    HINRIK        =>   "Hinrik \x{d6}rn Sigur\x{f0}sson (Hinrik Orn Sigurdsson)",
    HPETERS       =>   "Huub Peters",                    # ID exists, but no modules
    HUGMEIR       =>   "Brian Fraser",
    IFTEKHAR      =>   "Iftekharul Haque",
    IKRUGLOV      =>   "Ivan Kruglov",
    IPAPONOV      =>   "Ivan Paponov",                   # ID exists, but no modules
    ITALIANO      =>   "Roman Studenikin",               # ID exists, but no modules
    IZUT          =>   "Igor Sutton",
    JACKDOE       =>   "borislav nikolov",
    JALEVIN       =>   "Joseph A. Levin",                # ID exists, but no modules
    JANUS         =>   "Simon Bertrang",
    JEPRICE       =>   "Jeremy Price",
    JPO           =>   "Jos\x{e9} Pedro Oliveira (Jose Pedro Oliveira)", # ID exists, but no modules
    KOMAROV       =>   "Oleg Komarov",
    KSURI         =>   "\x{410}\x{43b}\x{435}\x{43a}\x{441}\x{435}\x{439} \x{421}\x{443}\x{440}\x{438}\x{43a}\x{43e}\x{432} (Alexey Surikov)",
    MALANDER      =>   "Ryan Bastic",                    # ID exists, but no modules
    MATTK         =>   "Matt Koscica",
    MAZE          =>   "Wijnand Modderman-Lenstra",      # ID exists, but no modules
    MBARBON       =>   "Mattia Barbon",
    MET           =>   "Quim Rovira",
    MICKEY        =>   "Mickey Nasriachi",
    MSANTOS       =>   "Marco Santos",
    MVUETS        =>   "\x{41c}\x{430}\x{43a}\x{441}\x{438}\x{43c} \x{412}\x{443}\x{435}\x{446} (Maxim Vuets)", # ID exists, but no modules
    NEVES         =>   "Marco Neves",
    NFERRAZ       =>   "Nelson Ferraz",
    NILSONSFJ     =>   "Nilson Santos Figueiredo J\x{fa}nior (Nilson Santos Figueiredo Junior)",
    NNUSS         =>   "Nate Nuss",                      # ID exists, but no modules
    PEARCE        =>   "Dean Pearce",
    POTYL         =>   "Emmanuel Rodriguez",
    PPATTHAR      =>   "Pavan Patthar",                  # ID exists, but no modules
    PSILVA        =>   "Pedro Silva",
    RGARCIA       =>   "Rafa\x{eb}l Garcia-Suarez (Rafael Garcia-Suarez)",
    SEVEAS        =>   "Dennis Kaarsemaker",
    SILVAN        =>   "Silvan Kok",                     # ID exists, but no modules
    SLANNING      =>   "Scott Lanning",
    SMUELLER      =>   "Steffen M\x{fc}ller (Steffen Mueller)",
    SPARKY        =>   "Przemys\x{142}aw Iskra (Przemyslaw Iskra)",
    STEVAN        =>   "Stevan Little",
    STEVENL       =>   "Steven Lee",
    STRANGE       =>   "Luciano Miguel Ferreira Rocha",
    SWEETKID      =>   "Upasana Shukla",
    SYP           =>   "\x{421}\x{442}\x{430}\x{43d}\x{438}\x{441}\x{43b}\x{430}\x{432} \x{41f}\x{443}\x{441}\x{435}\x{43f} (Stanislaw Pusep)",
    TECHCODE      =>   "Aleksandar Petrovi\x{107} (Aleksandar Petrovic)",
    TJUGO         =>   "Jose Mtanous",                   # ID exists, but no modules
    TSBRIGGS      =>   "Thomas Stewart Briggs",          # ID exists, but no modules
    TVDW          =>   "Tom van der Woerdt",
    VMIKULIC      =>   "Vedran Mikulic",                 # ID exists, but no modules
    XSAWYERX      =>   "Sawyer X",
    YKO           =>   "\x{42f}\x{440}\x{43e}\x{441}\x{43b}\x{430}\x{432} \x{41a}\x{43e}\x{440}\x{448}\x{430}\x{43a} (Yaroslav Korshak)",
    YVES          =>   "Yves",
);

33684;

__END__

=head1 NAME

Acme::CPANAuthors::Booking - Booking.com CPAN authors

=head1 SYNOPSIS

 use Acme::CPANAuthors;

 my $authors  = Acme::CPANAuthors -> new ("Booking");

 my $number   = $authors -> count;
 my @ids      = $authors -> id;
 my @distros  = $authors -> distributions ("BOOK");
 my $url      = $authors -> avatar_url    ("BOOK");
 my $kwalitee = $authors -> kwalitee      ("BOOK");
 my $name     = $authors -> name          ("BOOK");

See documentation for L<Acme::CPANAuthors> for more details.
 
=head1 DESCRIPTION

This class provides a hash of Booking.com CPAN authors' PAUSE ID and name to
the L<Acme::CPANAuthors> module.

=head1 BUGS

As soon as Booking.com hires a new CPAN author, this module is out of date.

=head1 COMMERCIAL BREAK

Booking.com is hiring. Send your resume to L<mailto:work@booking.com>
if you are interested. See also L<https://www.booking.com/jobs/>

=head1 DEVELOPMENT

The current sources of this module are found on github,
L<http://github.com/book/Acme-CPANAuthors-Booking/>.

=head1 AUTHOR

Originally written by Abigail, L<mailto:cpan@abigail.be>.
Now maintained by Philippe Bruhat (BooK), L<mailto:book@cpan.org>.

=head1 COPYRIGHT

Copyright (C) 2010, 2011, 2012 by Abigail.
Copyright (C) 2012 by Philippe Bruhat (BooK).
Copyright (C) 2010-2014 by Dennis Kaarsemaker.

=head1 LICENSE

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=head1 INSTALLATION

To install this module, run, after unpacking the tar-ball, the
following commands:

   perl Makefile.PL
   make
   make test
   make install

=cut
