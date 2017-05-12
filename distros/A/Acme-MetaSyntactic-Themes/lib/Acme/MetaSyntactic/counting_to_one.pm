# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Acme::MetaSyntactic::counting_to_one -- A selection of various movie titles
#
#     Copyright (C) 2012 Jean Forget
#
#     This program is free software; you can redistribute it and/or modify
#     it under the same terms as Perl: either the Artistic License,
#     or the GNU General Public License as published by
#     the Free Software Foundation; either version 1, or (at your option)
#     any later version.
#
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License and
#     the Artistic License along with this program; if not, write to the Free
#     Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
#     02111-1307, USA for the GNU General Public License.
#
#     For the Artistic License, you may refer to http://dev.perl.org/licenses/artistic.html
#
package Acme::MetaSyntactic::counting_to_one;
use strict;
use Acme::MetaSyntactic::List;
our @ISA = qw( Acme::MetaSyntactic::List );
our $VERSION = '1.000';
__PACKAGE__->init();
1;

=encoding utf8

=head1 NAME

Acme::MetaSyntactic::counting_to_one - The "movies where you count up to one" theme

=head1 DESCRIPTION

This list gives the names of some movies
where you only need to count up to one or,
in some cases, up to zero. More precisely:

If you count the number of gunshots in I<M*A*S*H>
(a Korean-war film), you obtain a count of one.

The same thing with I<The Man Who Never Was> (a WWII movie)
gives a result of zero.

If you count the number of surviving characters at the end
of I<The Trench>, you obtain a count of one.

If you count the number of female characters
in I<Dr Strangelove>, you obtain a count of one.

On the other hand, if you count the number of male characters
in I<Huit Femmes> (I<Eight Women>), you obtain a count of one.

If you count the number of times you see John Belushi's
eyes in I<The Blues Brothers>, you obtain a count of one. If you prefer Dan Acroyd's
or Cab Calloway's eyes, you obtain a count of zero.

If you count the number of times the word "Mafia" is pronounced
in I<The Godfather>, you obtain a count of zero.

If you count the number of alphabetic characters in Truffaut's
I<Fahrenheit 451>, not taking into account the books
being burned, you obtain a count of zero.

If you count the number of scenes which include a horse in
I<Monty Python's Holy Grail>, you obtain a count of one.

At the end of the same movie, if you count the number of names appearing in the final
credits, you obtain a count of zero.

If you count the number of words said during
Mel Brooks' I<Silent Movie>, you obtain a count of one.

If you count the number of sexy scenes in I<Robin Hood>
(the Errol Flynn and Olivia de Havilland version), you obtain a count of one.

If you count the number of times Grace Kelly appears naked in
I<The Bridges at Toko-Ri>, you obtain a count of one.

If you count the number of times Humphrey Bogart says "Play it again
Sam" in I<Casablanca>, despite what the movie buff lore says, you
obtain a count of zero.

If you count the number of sequences in I<Rope>,
you obtain a count of one.

If you watch I<Le Fils de Caroline Chérie> to have a look
at Caroline, you will see her only once.

In most war movies,
the delay between the instant you see an explosion and the
instant you hear it is zero seconds.

To these movies, we can add several other movies based
on Tennessee William's plays, which follow the
classical French theater's I<règle des trois unités>:
one day, one place, one plot.

And of course, we can add any Buster Keaton film,
in which you might count the number of times Buster Keaton smiles,
as well as any Marx Brothers film, in which you can count the
number of times Harpo speaks.

=head2 Explanations

=over 4

=item M*A*S*H

The gunshot occurs during the football match, to mark the
end of the first period of the game.

=item The Man Who Never Was

This movie is rather a spy movie that takes place during
World War II. It presents the deception operation prior to
the landing in Sicily, which consisted in releasing the
corpse of a so-called "Major Martin", with forged secret
documents, so this corpse would land in neutral Spain.
The British hoped that the German agents in Spain would
have access to the forged documents, believe them genuine
and report their findings to Berlin. The movie describes
the preparation of the operation and the mission of a
German agent in England to check the background of "Major
Martin". So, this film contains no gunshot, only one
axis character and one corpse.

=item The Trench

This film describes the Somme Attack on 1st July, 1916, which may have
been the most murderous day since the birth of mankind until the
bombing of Hamburg in 1943. Therefore you might think that there would
be no survivor among the main characters (that is, excluding the poge
colonel and the cinema team). Yet, there is one survivor, the soldier
who had his jaw smashed by a sniper shot and who was casevac'ed on the
eve of the Somme attack.

=item Dr Strangelove

The female character is Miss "Foreign Affairs", General Turgidson's
secretary, who appears also in the centerfold of the Playboy issue
Major Kong is reading.
See L<http://tvtropes.org/pmwiki/pmwiki.php/Main/TheSmurfettePrinciple>

=item The Blues Brothers

The scene where we can see Jake's eyes is the scene in the sewer tunnel where
Jake is at last face-to-face with his former wife-to-be, played by
Carrie Fisher.

=item Fahrenheit 451

Ray Bradbury's book is about a future where books are banished,
lest they'd be tought-provoking. François Truffaut's film is
about a future where every single alphabetic character is banished,
not only the thought-provoking ones inside the books, but also
the utilitary characters such as "exit", "walk"/"don't walk",
"in", "out". When a character's personal file is briefly shown,
we can only see numbers. This goes to such length that the credits
are not written on the screen, but spoken by a narrator.
The contributor likes Ray Bradbury's book.

=item Monty Python's Holy Grail

The scene with a horse is the scene in which a professor
is murdered. As for the final credits, there are none.

=item Silent Movie

The only word spoken during this film is Mime Marceau's answer
to Mel Brooks: "No!"

=item Robin Hood

In this film, a "normal" scene is a scene where Maid Marian
wears clothes and headgear covering everything except part of her face,
from the forehead to the chin. A "sexy" scene is a scene
in which Maid Marian appears with her whole bare head:
face, ears, long flowing hear. Yet, from the neck down,
she is still fully clothed.

=item The Bridges at Toko-Ri

This film includes a scene where Brubaker (William Holden), his wife
(Grace Kelly) and their two girls take a Japanese bath. But don't
hold your breath, the angles of view and the ripples in the water
prevent you from seeing more than the Hays Code would permit.

=item Rope

This is a movie with five reels, yet with seemingly
only one camera shot. Actually, from time to time,
the camera zooms towards a dark object, such as
James Stewart's suit or the lid of a wooden trunk.
Then, when the camera zooms out, you notice a slightly
different rendering of the colors. But it is customary
to pretend not noticing that and to wonder how Hitchcock
did this feat. The contributor does not agree. This movie
is one of the few Hitchcock movies he dislikes.

=item Le Fils de Caroline Chérie

Actually, Caroline appears only something like 0.05 times,
rounded up to one. The entire movie is about her son,
living in Spain during the Napoleonic War and
looking for his mother. His quest is fulfilled at
the very end of the movie and he sees at last
her mother exiting from a stagecoach. But you
barely see her foot and ankle and the film
ends on this picture. By the way, nothing
ensures that this foot and this ankle are
Martine Carol's (the actress playing Caroline
in both other Caroline Chérie movies).

=back

=head1 CONTRIBUTOR

Jean Forget.

=head1 CHANGES

=over 4

=item *

2012-11-19 - v1.000

Published as the last theme submitted before
the release of Acme-MetaSyntactic version 0.99,
in Acme-MetaSyntactic-Themes version 1.028.

=item *

2012-10-21

Jean selected I<counting_to_one> as the theme name.

=item *

2012-09-25

Updated version submitted by Jean Forget.

=item *

2006-07-11

Submitted by Jean Forget as the I<movies> theme.

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::List>.

=cut

__DATA__
# names
MASH
The_Man_Who_Never_Was
The_Trench
Dr_Strangelove
Huit_Femmes
The_Blues_Brothers
The_Godfather
Fahrenheit_451
Monty_Python_Holy_Grail
Silent_Movie
Robin_Hood
The_Bridges_at_Toko_Ri
Casablanca
Rope
Le_Fils_de_Caroline_Cherie
A_Streetcar_Named_Desire
The_Night_of_the_Iguana
Cat_on_a_hot_tin_Roof
Three_Ages
The_Navigator
College
Steamboat_Bill_Jr
The_Cameraman
Monkey_Business
Horse_Feathers
Duck_Soup
A_Night_at_the_Opera
Go_West
The_Big_Store
A_Night_in_Casablanca
Love_Happy
