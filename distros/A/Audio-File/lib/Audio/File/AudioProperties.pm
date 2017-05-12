package Audio::File::AudioProperties;

use strict;
use warnings;

our $VERSION = '0.02';

=head1 NAME

Audio::File::AudioProperties - abstract an audio files audio properties.

=head1 DESCRIPTION

Audio::File::AudioProperties is the base class for other file format independant
audio property classes like Audio::File::Flac::AudioProperties or
Audio::File::Ogg::AudioProperties. You should not use this class yourself exept
you're writing an own file format dependant subclass.

=head1 METHODS

=head2 new

Constructor. Creates new Audio::File::AudioProperties object. You shoud not use
this method yourself. It's called by the filetype-dependant subclasses of
Audio::File::Type automatically.

=cut

sub new {
	my($class, $filename) = @_;
	$class = ref $class || $class;
	my $self = { filename => $filename };
	bless $self, $class;
	$self->init(@_) or return;
	return $self;
}

=head2 init

Initializes the object. It's called by the constructor and empty by default.
It's ought to be overwritten by subclasses.

=cut

sub init {

}

=head2 length

Returns the length of the audio file in seconds.

=cut

sub length {
	my $self = shift;
	if( @_ ) {
		$self->{length} = shift;
		return 1;
	}

	return int $self->{length};
}

=head2 bitrate

Returns the bitrate of the file.

=cut

sub bitrate {
	my $self = shift;
	if( @_ ) {
		$self->{bitrate} = shift;
		return 1;
	}

	return int $self->{bitrate};
}

=head2 sample_rate

Returns the sample rate of the audio file.

=cut

sub sample_rate {
	my $self = shift;
	if( @_ ) {
		$self->{sample_rate} = shift;
		return 1;
	}

	return $self->{sample_rate};
}

=head2 channels

Returns the number of channels the audio file has.

=cut

sub channels {
	my $self = shift;
	if( @_ ) {
		$self->{channels} = shift;
		return 1;
	}

	return $self->{channels};
}

=head2 all

Get all audio properties.

=cut

sub all {
	my $self = shift;

	if (@_) {
		my $props = shift;
		$self->$_($props->{$_}) for keys %{$props};
		return 1;
	}

	return {
		length		=> $self->length(),
		bitrate		=> $self->bitrate(),
		sample_rate	=> $self->sample_rate(),
		channels	=> $self->channels()
	};
}

1;

=head1 SEE ALSO

L<Audio::File>, L<Audio::File::Type>, L<Audio::File::Tag>

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
