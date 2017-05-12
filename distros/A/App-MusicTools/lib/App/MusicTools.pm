# -*- Perl -*-
#
# Of more interest may be the scripts listed as EXE_FILES in Makefile.PL.

package App::MusicTools;
use 5.014000;
our $VERSION = '1.29';
1;

__END__

=head1 NAME

App-MusicTools - command line utilities for music composition and analysis

=head1 SYNOPSIS

  $ atonal-util --ly findin --pitchset=5-25 c e g
  Ti(0)   c,e,g,a,ais
  T(4)    c,e,g,fis,a

  $ canonical --contrary --retrograde modal c f g e c
  c g, f, a, c

  $ canonical modal --input=dorian --output=locrian d e f g a b c
  d dis f g gis ais c

  $ harmonic-fit f e ees d g aes ges b c a bes des
  ...

  $ export MIDI_EDITOR=timidity
  $ ly-fu --instrument=banjo c des ees c des bes c aes

  $ scalemogrifier --mode=mixolydian --transpose=fis
  fis gis ais b cis dis e fis'

  $ varionator '(I I6) (II IV II6 IV6) (V V7 III) I'
  ...

  $ vov --outputtmpl='<%{chord}> \t% %{vov}' I IV/IV V7/IV IV V7 I
  <c e g> 	% I
  <b dis f> 	% IV/IV
  <c e g b> 	% V7/IV
  <f a c> 	% IV
  <g b d f> 	% V7
  <c e g> 	% I

And more!

=head1 DESCRIPTION

This distribution contains various command line utilities related to
music composition and analysis, brief examples of which are shown in the
L</"SYNOPSIS">, above. Run C<perldoc> on the command name for additional
documentation on how to use each tool, as several of the programs have
many, many more options than shown here.

The C<zsh-compdef> directory of this distribution includes ZSH
completion scripts for the command line utilities. Install these files
to a ZSH C<$fpath> directory, and follow the ZSH documentation on setting
up tab completion.

=head1 BUGS

Probably lots. Send patches, as there are probably lots between my bad
Perl and badder understanding of music theory.

=head1 SEE ALSO

=over 4

=item *

L<http://www.lilypond.org/> and most notably the Learning and Notation
manuals, as the tools make use of the default lilypond note letter
conventions (e.g. fis for F sharp, ees for E flat, etc.)

=item *

C<ly-fu> expects that a MIDI player and PDF viewer are available on the system.
Environment variables will likely need to be set or the source code tweaked as
necessary.

=item *

"The Structure of Atonal Music" by Allen Forte (ISBN 978-0-300-02120-2).
Though, note that there are two forms of pitch set construction; the one
created by Rahn is more common in computing circles.

=item *

B<Theory of Harmony> by Arnold Schoenberg (ISBN 978-0-520-26608-7).

=item *

L<http://en.wikipedia.org/wiki/Forte_number>

=item *

L<Music::AtonalUtil>, L<Music::Chord::Positions>,
L<Music::LilyPondUtil>, L<Music::Tension> and others.

=back

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2016 by Jeremy Mates

This module is free software; you can redistribute it and/or modify it
under the Artistic License (2.0).

=cut
