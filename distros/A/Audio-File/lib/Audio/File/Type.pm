package Audio::File::Type;

use strict;
use warnings;

our $VERSION = '0.02';

=head1 NAME

Audio::File::Type - represents an audio filetype

=head1 DESCRIPTION

An instance of an object inherited from Audio::File::Type is returned by the
constructor of Audio::File. This object currently provides access to the audio
files information like its audio properties (bitrate, sample rate, number of
channels, ...) and the data stored in the files tag, but also providing access
to the raw audio data and other information should be easy to be implemented.

=head1 METHODS

=head2 new

Constructor. In fact you don't need to use it. Please use Audio::File which will
call the appropriate constructor corresponding to the files type.

=cut

sub new {
	my($class, $filename) = @_;
	$class = ref $class || $class;
	my $self = {
		name		=> $filename,
		readonly 	=> 1
	};
	bless $self, $class;
	return unless $self->is_readable();
	$self->init(@_) or return;
	return $self;
}

=head2 init

This method will be called by the constructor. It's empty by default and should
be overwritten by inheriting subclasses to initialize themselfes.

=cut

sub init {

}

sub _create_tag { }

sub _create_audio_properties { }

=head2 name

Returns the name of the audio file.

=cut

sub name {
	return shift->{name};
}

=head2 is_readable

Checks whether the file is readable or not. At the moment it's only used by the
constructor, but it will be more usefull with later versions of Audio::File.

=cut

sub is_readable {
	return -r shift->{name};
}

=head2 is_writeable

Checks whether the file is writeable or not. At the moment you'll probably don't
need to call this method, but it'll be more usefull as soon as changing the
audio file is implemented.

=cut

sub is_writeable {
	return -w shift->{name};
}

=head2 tag

Returns a reference to the files tag object. See the documentation of
L<Audio::File::Tag> to learn about what the tag object does.

=cut

sub tag {
	my $self = shift;
	unless( $self->{tag} ) {
		$self->_create_tag() or return;
	}

	return $self->{tag};
}

=head2 audio_properties

Returns a reference to the files audio properties object. See the documentation
of L<Audio::File::AudioProperties> to get information about what the audio
properties object does.

=cut

sub audio_properties {
	my $self = shift;
	unless( $self->{audio_properties} ) {
		$self->_create_audio_properties() or return;
	}
	
	return $self->{audio_properties};
}

=head2 save

Saves the audio file. This is not yet implemented but it should remember me to
do it at some time.. :-)

=cut

sub save {

}

=head2 type

Returns the files type.

=cut

sub type {
	(my $type = ref shift) =~ s/.*:://;
	return lc $type;
}

=head1 TODO

=over 4

=item implement changing the file

=back

=head1 SEE ALSO

L<Audio::File>, L<Audio::File::Tag>, L<Audio::File::AudioProperties>

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
