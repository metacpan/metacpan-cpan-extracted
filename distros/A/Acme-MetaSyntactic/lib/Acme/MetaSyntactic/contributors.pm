=encoding iso-8859-1

=head1 NAME

Acme::MetaSyntactic::contributors - Acme::MetaSyntactic contributors

=head1 DESCRIPTION

The following people contributed to L<Acme::MetaSyntactic>,
either by proposing theme ideas, updating existing themes,
sending bug reports, running the test suite on their machine
and sending me the report or sending complete lists of items
for new or existing themes. Thanks for all the work I didn't
have to do!

They are listed below in chronological order (of when I actually used
their contributions), with the list of themes they contributed to (by
sending theme ideas, code, patches, bug reports, etc.). When no theme is
listed, this means that person contributed in another way (bug reports
or contribution to the behaviour modules).

This list only includes contributions made to Acme-MetaSyntactic (from
version 0.01 up to version 0.99) and to Acme-MetaSyntactic-Themes (from
version 1.000 up to version 1.028).

=cut

package Acme::MetaSyntactic::contributors;
use strict;
use Acme::MetaSyntactic::List;
our @ISA = qw( Acme::MetaSyntactic::List );
our $VERSION = '1.002';

{
    my %seen;
    __PACKAGE__->init(
        {   names => join ' ',
            grep    { !$seen{$_}++ }
                map { s/_+/_/g; $_ }
                map { Acme::MetaSyntactic::RemoteList::tr_nonword($_) }
                map { Acme::MetaSyntactic::RemoteList::tr_accent($_) }
                map { /^=head2 (.*)/ ? $1 : () }
                split /\n/ => <<'=cut'} );

=pod

=head2 Vahe Sarkissian

L<Acme::MetaSyntactic::donmartin>.

=head2 David Landgren

L<Acme::MetaSyntactic::pynchon>.

=head2 Sébastien Aperghis-Tramoni

L<Acme::MetaSyntactic::browser.pm>,
L<Acme::MetaSyntactic::dilbert.pm>,
L<Acme::MetaSyntactic::elements.pm>,
L<Acme::MetaSyntactic::evangelion.pm>,
L<Acme::MetaSyntactic::octothorpe.pm>,
L<Acme::MetaSyntactic::pornstars.pm>,
L<Acme::MetaSyntactic::quantum.pm>,
L<Acme::MetaSyntactic::unicode.pm>.

=head2 Mike Castle

=head2 anonymous

L<Acme::MetaSyntactic::crypto>.

=head2 Scott Lanning

L<Acme::MetaSyntactic::tld>.

=head2 Michel Rodriguez

L<Acme::MetaSyntactic::phonetic>,
L<Acme::MetaSyntactic::scooby_doo>.

=head2 Rafael Garcia-Suarez

L<Acme::MetaSyntactic::browser.pm>,
L<Acme::MetaSyntactic::buffy.pm>,
L<Acme::MetaSyntactic::jerkcity.pm>,
L<Acme::MetaSyntactic::pantagruel.pm>,
L<Acme::MetaSyntactic::pumpkings.pm>,
L<Acme::MetaSyntactic::stars.pm>.

=head2 Aldo Calpini

L<Acme::MetaSyntactic::hhgg.pm>.

=head2 Jérôme Fenal

L<Acme::MetaSyntactic::garbage.pm>,
L<Acme::MetaSyntactic::haddock.pm>,
L<Acme::MetaSyntactic::loremipsum.pm>,
L<Acme::MetaSyntactic::teletubbies.pm>.

=head2 Ricardo Signes

L<Acme::MetaSyntactic::monty_spam.pm>,
L<Acme::MetaSyntactic::python.pm>.

=head2 Hakim Cassimally

L<Acme::MetaSyntactic::pornstars.pm>.

=head2 Max Maischein

=head2 Offer Kaye

L<Acme::MetaSyntactic::amber.pm>.

=head2 Cédric Bouvier

L<Acme::MetaSyntactic::magicroundabout.pm>.

=head2 Jean Forget

L<Acme::MetaSyntactic::bottles.pm>,
L<Acme::MetaSyntactic::counting_to_one.pm>,
L<Acme::MetaSyntactic::discworld.pm>,
L<Acme::MetaSyntactic::good_omens.pm>,
L<Acme::MetaSyntactic::hhgg.pm>,
L<Acme::MetaSyntactic::invasions.pm>,
L<Acme::MetaSyntactic::lotr.pm>,
L<Acme::MetaSyntactic::norse_mythology.pm>,
L<Acme::MetaSyntactic::phonetic.pm>,
L<Acme::MetaSyntactic::roman.pm>,
L<Acme::MetaSyntactic::space_missions.pm>,
L<Acme::MetaSyntactic::swords.pm>.

=head2 Guy Widloecher

L<Acme::MetaSyntactic::crypto.pm>.

=head2 Xavier Caron

L<Acme::MetaSyntactic::counting_rhyme.pm>,
L<Acme::MetaSyntactic::dwarves.pm>.

=head2 Paul-Christophe Varoutas

L<Acme::MetaSyntactic::counting_rhyme.pm>.

=head2 Gábor Szabó

=head2 Mark Fowler

L<Acme::MetaSyntactic::yapc.pm>.

=head2 Miss Barbie

=head2 Martin Vorländer

L<Acme::MetaSyntactic::discworld.pm>.

=head2 Alberto Manuel Brandão Simões

L<Acme::MetaSyntactic::roman.pm>,
L<Acme::MetaSyntactic::tour_de_france.pm>.

=head2 Nicholas Clark

L<Acme::MetaSyntactic::booze>,
L<Acme::MetaSyntactic::pie>.

=head2 Gaal Yahas

L<Acme::MetaSyntactic::antlers.pm>.

=head2 Estelle Souche

L<Acme::MetaSyntactic::alphabet.pm>,
L<Acme::MetaSyntactic::contrade.pm>,
L<Acme::MetaSyntactic::dancers.pm>,
L<Acme::MetaSyntactic::facecards.pm>,
L<Acme::MetaSyntactic::oulipo.pm>.

=head2 Abigail

L<Acme::MetaSyntactic::abba.pm>,
L<Acme::MetaSyntactic::afke.pm>,
L<Acme::MetaSyntactic::alice.pm>,
L<Acme::MetaSyntactic::asterix.pm>,
L<Acme::MetaSyntactic::barbapapa.pm>,
L<Acme::MetaSyntactic::barbarella.pm>,
L<Acme::MetaSyntactic::ben_and_jerry.pm>,
L<Acme::MetaSyntactic::bible.pm>,
L<Acme::MetaSyntactic::bottles.pm>,
L<Acme::MetaSyntactic::calvin.pm>,
L<Acme::MetaSyntactic::camelidae.pm>,
L<Acme::MetaSyntactic::chess.pm>,
L<Acme::MetaSyntactic::colours.pm>,
L<Acme::MetaSyntactic::counting_rhyme.pm>,
L<Acme::MetaSyntactic::dwarves.pm>,
L<Acme::MetaSyntactic::elements.pm>,
L<Acme::MetaSyntactic::fabeltjeskrant.pm>,
L<Acme::MetaSyntactic::fawlty_towers.pm>,
L<Acme::MetaSyntactic::garfield.pm>,
L<Acme::MetaSyntactic::gems.pm>,
L<Acme::MetaSyntactic::good_omens.pm>,
L<Acme::MetaSyntactic::iata.pm>,
L<Acme::MetaSyntactic::icao.pm>,
L<Acme::MetaSyntactic::jabberwocky.pm>,
L<Acme::MetaSyntactic::jamesbond.pm>,
L<Acme::MetaSyntactic::lucky_luke.pm>,
L<Acme::MetaSyntactic::metro.pm>,
L<Acme::MetaSyntactic::muses.pm>,
L<Acme::MetaSyntactic::nis.pm>,
L<Acme::MetaSyntactic::nobel_prize.pm>,
L<Acme::MetaSyntactic::norse_mythology.pm>,
L<Acme::MetaSyntactic::olympics.pm>,
L<Acme::MetaSyntactic::opcodes.pm>,
L<Acme::MetaSyntactic::phonetic.pm>,
L<Acme::MetaSyntactic::planets.pm>,
L<Acme::MetaSyntactic::pokemon.pm>,
L<Acme::MetaSyntactic::pooh.pm>,
L<Acme::MetaSyntactic::pumpkings.pm>,
L<Acme::MetaSyntactic::punctuation.pm>,
L<Acme::MetaSyntactic::regions.pm>,
L<Acme::MetaSyntactic::reindeer.pm>,
L<Acme::MetaSyntactic::renault.pm>,
L<Acme::MetaSyntactic::screw_drives.pm>,
L<Acme::MetaSyntactic::simpsons.pm>,
L<Acme::MetaSyntactic::sins.pm>,
L<Acme::MetaSyntactic::smtp.pm>,
L<Acme::MetaSyntactic::smurfs.pm>,
L<Acme::MetaSyntactic::state_flowers.pm>,
L<Acme::MetaSyntactic::tarot.pm>,
L<Acme::MetaSyntactic::Themes.pod>,
L<Acme::MetaSyntactic::thunderbirds.pm>,
L<Acme::MetaSyntactic::tmnt.pm>,
L<Acme::MetaSyntactic::tokipona.pm>,
L<Acme::MetaSyntactic::tour_de_france.pm>,
L<Acme::MetaSyntactic::trigan.pm>,
L<Acme::MetaSyntactic::userfriendly.pm>,
L<Acme::MetaSyntactic::us_presidents.pm>,
L<Acme::MetaSyntactic::vcs.pm>,
L<Acme::MetaSyntactic::wales_towns.pm>,
L<Acme::MetaSyntactic::weekdays.pm>,
L<Acme::MetaSyntactic::yapc.pm>,
L<Acme::MetaSyntactic::zodiac.pm>.

=head2 Antoine Hulin

L<Acme::MetaSyntactic::dwarves.pm>.

=head2 Michael Scherer

=head2 Jan Pieter Cornet

L<Acme::MetaSyntactic::haddock.pm>.

=head2 Flavio Poletti

L<Acme::MetaSyntactic::donmartin.pm>,
L<Acme::MetaSyntactic::smurfs.pm>.

=head2 Leon Brocard

L<Acme::MetaSyntactic::pooh.pm>.

=head2 Anja Krebber

L<Acme::MetaSyntactic::counting_rhyme.pm>.

=head2 Yanick Champoux

L<Acme::MetaSyntactic::counting_rhyme.pm>.

=head2 Gisbert W. Selke

L<Acme::MetaSyntactic::phonetic.pm>,
L<Acme::MetaSyntactic::weekdays.pm>.

=head2 José Castro

L<Acme::MetaSyntactic::colours.pm>.

=head2 David Golden

L<Acme::MetaSyntactic::pgpfone.pm>.

=head2 Matthew Musgrove

L<Acme::MetaSyntactic::simpsons.pm>.

=head2 David H. Adler

L<Acme::MetaSyntactic::doctor_who.pm>.

=head2 Éric Cholet

L<Acme::MetaSyntactic::vcs.pm>.

=head2 Elliot Shank

L<Acme::MetaSyntactic::metro.pm>.

=head2 Simon Myers

L<Acme::MetaSyntactic::summerwine.pm>.

=head2 Olivier Mengué

L<Acme::MetaSyntactic::phonetic.pm>.

=head2 Éric Cassagnard

L<Acme::MetaSyntactic::care_bears.pm>.

=cut

}

1;

__END__

=pod

Thank you all for making Acme::MetaSyntactic such a successful module!

=head1 CONTRIBUTOR

Philippe Bruhat.

=head1 CHANGES

=over 4

=item *

2017-04-17 - v1.002

Listed everyone's contributions to L<Acme::Syntactic> themes.

=item *

2012-05-14 - v1.001

Added Olivier Mengué as a contributor.
Published in Acme-MetaSyntactic v1.001.

=item *

2012-05-07 - v1.000

Introduced in Acme-MetaSyntactic version 1.000.

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::List>.

=cut

