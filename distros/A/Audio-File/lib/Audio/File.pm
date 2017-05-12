package Audio::File;

use strict;
use warnings;

our $VERSION = '0.11';

=head1 NAME

Audio::File - Audio file abstraction library

=head1 SYNOPSIS

  use Audio::File;
  my $file = Audio::File->new( "foo.bar" );

  print "The ". $file->type() ."-file ". $file->name
  		." is ". int $file->length() ." seconds long.\n";

  print "It's interpreted by ". $file->tag->artist()
  		." and called ". $file->tag->title() ".\n";

=head1 DESCRIPTION

Audio::File abstracts a single audio file, independant of its format. Using this
module you can access a files meta-info like title, album, etc. as well as the
files audio-properties like its length and bitrate.

Currently only the formats flac, ogg vorbis and mp3 are supported, but support
for other formats may be easily added.

=head1 METHODS

=head2 new

  $file = Audio::File->new( "foobar.flac" );

Constructor. It takes the filename of the your audio file as its only argument
and returns an instance of Audio::File::${Type} if the corresponding file type
is supported. The file type will be determined using the file extension.
Currently flac, ogg and mp3 are supported but new formats may be added easily by
creating a Audio::File::${Type} that inherits from Audio::File::Type, which is
the base class for all file type classes.

The methods and behaviour of the returned are documented in
L<Audio::File::Type>.

=cut

sub new {
	my $class = shift;
	$class = ref $class || $class;
	my $self = {};
	bless $self, $class;
	return $self->_create(@_);
}

sub _create {
	my($self, $filename) = @_;
	
	return unless length($filename) > 4;

	(my $type = $filename) =~ s/.*\.//;
	$type = ucfirst lc $type;
	return unless $type;

	my $loaded = 0;
	eval "require Audio::File::$type; \$loaded = 1;";
	return "Audio::File::$type"->new( $filename ) if $loaded;
}

1;

=head1 TODO

=over 4

=item * Add possibility to change file and its tags.

=item * better (easier) interface?

=item * user shouldn't be forced to use Audio::File if he only want's the files
tag or audio properties.

=item * Add possibility to access raw audio data (Audio::File::Data)

That could be done via Audio::Data or equivalent.

=back

=head1 SEE ALSO

L<Audio::File::Type>, L<Audio::File::Tag>, L<Audio::File::AudioProperties>

=head1 AUTHOR

Florian Ragwitz <flora@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 Florian Ragwitz

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Library General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=cut
