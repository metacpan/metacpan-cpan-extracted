package Acme::MetaSyntactic::tarot;
use strict;
use Acme::MetaSyntactic::List;
our @ISA = qw( Acme::MetaSyntactic::List );
our $VERSION = '1.000';
__PACKAGE__->init();
1;

=head1 NAME

Acme::MetaSyntactic::tarot - Tarot cards

=head1 DESCRIPTION

Tarot decks consist of 78 different cards - a 22 card I<Major Arcana>,
and 4 14-card suits forming the I<Minor Arcana>. The suits in the
minor arcana as I<Wands>, I<Cups>, I<Swords> and I<Pentacles>. Ranks
start with I<Ace>, then go from 2 to 10 inclusive, then I<Page>,
I<Knight>, I<Queen> and I<King>. In the Major Arcana, we find:
I<Fool>, I<Magician>, I<High Priestess>, I<Empress>, I<Emperor>,
I<Hierophant>, I<Lovers>, I<Chariot>, I<Strength>, I<Hermit>,
I<Wheel of Fortune>, I<Justice>, I<Hanged Man>, I<Death>, I<Temperance>,
I<Devil>, I<Tower>, I<Star>, I<Moon>, I<Sun>, I<Judgement>, and finally,
I<World>.

Source: L<http://www.learntarot.com/>

=head1 CONTRIBUTOR

Abigail

=head1 CHANGES

=over 4

=item *

2012-06-11 - v1.000

Introduced in Acme-MetaSyntactic-Themes version 1.005.

=item,*

2005-11-01

Submitted by Abigail.

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::List>.

=cut

__DATA__
# names
Fool Magician High_Priestess Empress Emperor Hierophant Lovers
Chariot Strength Hermit Wheel_of_Fortune Justice Hanged_Man Death
Temperance Devil Tower Star Moon Sun Judgement World
Wand Cup Sword Pentacle Page Knight Queen King Ace
