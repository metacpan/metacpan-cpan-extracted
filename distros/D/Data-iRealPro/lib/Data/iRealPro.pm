#! perl

package Data::iRealPro;

use warnings;
use strict;

=head1 NAME

Data::iRealPro - Convert iRealBook/iRealPro data

=cut

our $VERSION = "1.13";

=head1 SYNOPSIS

  irealcvt iRealPro_exported.html --output formatted.pdf
  irealcvt iRealPro_exported.html --output formatted.png
  irealcvt iRealPro_exported.html --output raw.json
  irealcvt iRealPro_exported.html --output editable.txt
  irealcvt iRealPro_exported.html --output importable.html
  irealcvt iRealPro_exported.html --list

=head1 DESCRIPTION

iRealPro (previously named iReal-B) is a songwriting tool / electronic
backup band for iPhone/iPad, Mac OSX and Android that lets you
experiment with advanced chord progressions and arrangements quickly
and easily. You can use iRealPro for songwriting experiments, as
accompaniment when learning new songs or for making backing tracks for
your guitar / saxophone / theremin solos.

B<iRealPro> can import songs in one of two textual format formats.
The 'irealbook' format is easily readable and straightforward. The
official 'irealb' format is proprietary and uses some form of
scrambling to hide the contents. iRealPro can export songs in the form
of a HTML document that contains the data in big URLs, and some
printable formats.

MusicXML input is possible if the module L<XML::LibXML> is available.

Data::iRealPro provides a set of modules that can be used to read and
analyse iRealPro songs in URL format and convert them into something
else, like PDF or PNG. A ready-to-use program irealcvt is provided to
perform conversions on the command line.

iRealPro web site: L<http://www.irealpro.com>.

=head1 A NOTE ABOUT WRITTEN KEY AND PLAYING KEY

In iRealPro you can write a song in a specific key, and play it in a
different key. The formatter backends PDF and PNG will show the song
in the key it was played, just like iRealPro when it is playing your song.

The JSON and Text reflect the raw data of the song and will show the
song in the key it was written, just like iRealPro when you are
editing the song.

=head1 REQUIREMENTS

PDF document generation requires L<PDF::API2>. This is considered core
functionality.

Image generation requires L<Imager>. This is optional.

The web backend C<irealpro.cgi> requires L<Template::Tiny>.

=head1 AUTHOR

Johan Vromans, C<< <jv at cpan.org> >>

=head1 SUPPORT

The development of this module is hosted on GitHub, repository
L<https://github.com/sciurius/perl-Data-iRealPro>.

Please report any bugs or feature requests to the GitHub issue tracker,
L<https://github.com/sciurius/perl-Data-iRealPro/issues>.

You can find documentation for this module with the perldoc command.

    perldoc Data::iRealPro

=head1 ACKNOWLEDGEMENTS

Massimo Biolcati of Technimo LLC, for writing iRealPro.

The iRealPro community, for contributing many, many songs.

=head1 COPYRIGHT & LICENSE

Copyright 2013,2018 Johan Vromans, all rights reserved.

Clone me at L<GitHub|https://github.com/sciurius/perl-Data-iRealPro>

=cut

1;
