use v5.16;
use utf8;
package Art::World;

# use Art::Agent;
#has Art::Agent::Artist @.artists;

our $VERSION = '0.16';

use Zydeco;

class Playground {};

1;

=encoding UTF-8

=head1 NAME

Art::World - Agents interactions modeling  🎨

=head1 SYNOPSIS

  use Art::World;

=head1 OBJECTIVES


Art::World is an attempt to model and simulate a system describing the interactions and influences between the various I<agents> of the art world.

If a correct API is reached, we'll try to build a "game of art" frontend.

=head1 DESCRIPTION

=begin html

<p>
  <img alt="Some illustrations sticked on a wall" src="https://gitlab.com/smonff/art-world/-/raw/master/spec/schema_v2.png"
    width="600px">
</p>

=end html

=over

=item 01 Idea is the first step of process

=item 02 Idea is inserted in the file (through process)

=item 03 Idea comes from discourse (given about project)

=item 04 Idea comes when there is no time left

=item 05 Ideas constitue the project

=back

=over

=item 06 Process allows ideas to evolve

=item 07 Process allows to fill the file (with ideas + discourse)

=item 08 Process allows to generate some discourse

=item 09 Process allows to save time

=item 10 Process allows to set up the project

=back

=over

=item 11 File is made of ideas

=item 12 File is filled and emptied with the process

=item 13 File is made of discourse

=item 14 File archives ideas, making possible to forget them

=item 15 File generates a project

=back

=over

=item 16 Discourse steers ideas

=item 17 Discourse analyzes process

=item 18 Discourse talks about the file

=item 19 Discourse allows to link various stages of the projet

=item 20 Discourse is a constituent of the project

=back

=over

=item 21 From time to time, ideas appear

=item 22 Time is needed to apply the process

=item 23 Time is suspended into file, process is off there

=item 24 Discourse's time (reading time)

=item 25 Various times contained in project give it's shape

=back

=over

=item 26 Project is updated by new ideas

=item 27 Project is constantly updated by the process

=item 28 Project is set up when file is updated

=item 29 Project and discourse are inseparable

=item 30 Project is what takes the longuest time to set up

=back

=head1 HISTORY

This is a long term continuation of an art project started circa 2006.

In 2005, I got a metal box and colored carton cards and called this I<Le
Fichier>. It was basically a database of artworks ideas. I was trashing all
ideas I could have of serious or weird potential artworks. It was inspired
either by Roland Barthes, who was actually working with those kind of cards,
Georges Perec, who was exploring I<potentialities>, and Édouard Levé I<Oeuvres>,
a huge catalog of potential artworks (he later commited suicide after describing
his own I<Suicide> in a book).

2006 I initiated a FileMaker database of artworks to put the old style carton
cards in computer form. I had no idea what I was doing at this time, being an
art school student, at this time, programming was not massively taught as a fine art (unfortunately).

In 2008 I benefited of an artist residency in an agricultural college with a
creation grant of 10 000€. I wanted to keep working on my I<Art World and Creative
Processes schemas> projects initiated during art school. It didn't go very well
because the Plastic Art I<State Inspector> didn't like what I was
doing with her money and strongly advised to change orientation. In my opinion, it
was a perfect thing that the instutition itself would exhibit it's own workings. In the end, there was an exhibition, but she didn't
come to the opening.

Anyway, I ended up interviewing many I<Agents> of the college, and went
especially well with some natural sciences teacher. He recommended a manual were
I found some schemas that I made some I<detournement>: I used the geology
science as a metaphor of art world. I used geology terms and language to
describe social interactions that were not described in the art sociology field.

=begin html

<p>
  <img alt="Pencil schema with mountains" src="https://gitlab.com/smonff/art-world/-/raw/master/spec/schema_v4.png"
    width="600px">
</p>

=end html

The residency ended up with L<the redaction of a rather precise documentation|https://files.balik.network/art/schema_v4_presentation.pdf> (maybe my first specification).

Then I almost got beaten by a fellow artist who was participating in a collective
exhibition mostly for the money and not for the fun. I guess he felt a bit provoked by my situationist theory.

In 2008, I finally decided to start a training to learn programming and design a proper database and system for I<managing a virtual Art
World>. I became a web developer, but I totally forgot the ulterior motive.

Sometimes I thought about it:

=over

=item 2013 Perl try

I bootstrapped a Perl module with 5 abstract empty classes and then let it sleep on Github

=item 2017 Raku try

I restarted my project while getting into Raku
(it was still Perl6 at this time), but learning Raku was too much effort and I
abandonned again.

Ten years later I am still on it. This project is L<following me in my
dreams|https://smonff.gitlab.io/art-school-story/>. I'll give it another try.

=back

=head1 AUTHOR

=over

=item Sébastien Feugère <sebastien@feugere.net>

=item Seb. Hu-Rillettes <shr@balik.network>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2020 Seb. Hu-Rillettes

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=cut
