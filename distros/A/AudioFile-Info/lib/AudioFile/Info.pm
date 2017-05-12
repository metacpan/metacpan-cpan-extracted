=head1 NAME

AudioFile::Info - Perl extension to get info from audio files.

=head1 SYNOPSIS

  use AudioFile::Info;

  my $song = AudioFile::Info->new($some_mp3_or_ogg_vorbis_file);

  print 'Title:  ', $song->title, "\n",
        'Artist: ', $song->artist, "\n".
        'Album:  ', $song->album, "\n",
        'Track:  ', $song->track, "\n";
        'Year:   ', $song->year, "\n",
        'Genre:  ', $song->genre, "\n";

  $song->title('something else'); # Changes the title

=head1 ABSTRACT

AudioFile::Info is a simple way to get track information out of an audio
file. It gives a unified interface for extracting information from both
MP3 and Ogg Vorbis files.

Some AudioFile::Info plugins also have the ability to write data back
to the file.

=head1 DESCRIPTION

=head2 What is AudioFile::Info

I rip all of my audio files into Ogg Vorbis files. But some of my older
rips are in MP3 format. If I'm writing a program to access information
from my audio files it's annoying when I have to handle MP3 and Ogg
Vorbis files completely separately.

AudioFile::Info is my solution to that problem. It works on both MP3
and Ogg Vorbis files and gives an identical interface for dealing with
both of them.

=head2 Using AudioFile::Info

To use AudioFile::Info in your programs you simply load the module
as normal.

  use AudioFile::Info;

You then create an object using the C<new> method and passing it the
pathname of an audio file.

  my $song = AudioFile::Info->new($some_mp3_or_ogg_vorbis_file);

The module works out whether the file is in MP3 or Ogg Vorbis format and
creates an object which can extract the information from the correct
type of file. You can then use this object to access the various pieces
of information about the file.

  print 'Title:  ', $song->title, "\n",
        'Artist: ', $song->artist, "\n".
        'Album:  ', $song->album, "\n",
        'Track:  ', $song->track, "\n";
        'Year:   ', $song->year, "\n",
        'Genre:  ', $song->genre, "\n";

Currently you can access the title, artist, album, track number, year
and genre of the file.

With certain plugins (see below for a description of plugins) you can
now write data back to the file. This is as simple as passing a new string
to the accessor function.

  $song->title('something new');

=head2 AudioFile::Info Plugins

AudioFile::Info is simply a wrapper around various other modules which
read and write MP3 and Ogg Vorbis files. It makes use of these modules
by using plugin modules which act as an interface between
AudioFile::Info and the other modules. AudioFile::Info is pretty much
useless without at least one these plugins installed.

Each time you install a plugin, AudioFile::Info notes how it compares
with other installed plugins. It then works out how which of your
installed plugins is best for handling the various types of audio
files. When you use the module to read a file it will use the 
"best" plugin for the file type.

You can override this behaviour and tell it to use a particular
plugin by using an extended version of the C<new> method.

C<new> takes an optional argument which is a reference to a hash
that contains details of which plugin to use for each file type.
You use it like this.

  my $song = AudioFile::Info->new($file,
                                  { mp3 => 'AudioFile::Info::MP3::Info' });

In this case, if C<$file> is the name of an MP3 file then 
AudioFile::Info will use C<AudioFile::Info::MP3::Info> to handle it
rather than the default MP3 plugin. If C<$file> contains the name
of an Ogg Vorbis file then the default Ogg Vorbis plugin will still
be used. You can change the Ogg Vorbis plugin by using the C<ogg>
key in the optional hash.

Currently plugins are available for the following modules.

=over 4

=item *

MP3::ID3Lib

=item *

MP3::Info

=item *

MP3::Tag

=item *

Ogg::Vorbis::Header

=item *

Ogg::Vorbis::Header::PurePerl

=back

Plugins for other modules may appear in the future. Let me know if you
want a plugin that doesn't already exist.

=cut

package AudioFile::Info;

use 5.006;
use strict;
use warnings;
use Carp;

use YAML 'LoadFile';

our $VERSION = '1.10.3';

=head1 METHODS

=head2 AudioFile::Info->new(FILE, [\%OPTIONS])

Constructor method which returns a new Audio::File::Info object. Well,
actually it returns an instance of one of the AudioFile::Info plugin
objects, but for the average user the difference is largely academic.

Takes one mandatory argument, which is a full local path to an audio
file, and an optional reference to a hash containing options.

Currently the only options the method understands are 'mp3' or 'ogg'.
The corresponding values for these keys is the name of a plugin module
to use to process files of that type. This will override the default
plugin which AudioFile::Info will choose for itself from the installed
plugins.

=cut

sub new {
  my $class = shift;
  my $file = shift or die "No music file given.";

  my $param = shift || {};

  my $path = $INC{'AudioFile/Info.pm'};

  $path =~ s/Info.pm$/plugins.yaml/;

  my ($ext) = $file =~ /\.(\w+)$/;
  die "Can't work out the type of the file $file\n"
    unless defined $ext;

  $ext = lc $ext;

  my $pkg = $param->{$ext};

  unless (defined $pkg) {
    my $config = LoadFile($path);

    die "No default $ext file handler\n"
        unless exists $config->{default}{$ext};

    $pkg = $config->{default}{$ext}{name};
  }

  eval "require $pkg";
  $pkg->import;

  return $pkg->new($file);
}


1;
__END__

=head2 EXPORT

None.

=head1 SEE ALSO

The various plugin modules.

=head1 TO DO

=over 4

=item *

Make more data available.

=item *

Changing and writing data.

=back

=head1 AUTHOR

Dave Cross, E<lt>dave@mag-sol.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2007 by Magnum Solutions Ltd. All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
