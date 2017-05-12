package Audio::File::Tag;

use strict;
use warnings;

our $VERSION = '0.03';

=head1 NAME

Audio::File::Tag - abstracts the tag of an audio file

=head1 DESCRIPTION

Audio::File::Tag is the base class for other file format independant tag classes
like Audio::File::Flac::Tag or Audio::File::Ogg::Tag. You shouldn't use this
class yourself exept you're writing an own file format dependant subclass.

=head1 METHODS

=head2 new

Constructor. Creates a new Audio::File::Tag object. You shouldn't use this
method yourself. It is called by the filetype-dependant subclasses of
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

=head2 title

Using title() you can get or set the tags title field. If called without any
argument it'll return the current content of the title field. If you call
title() with an scalar argument it will set the title field to what the argument
contains. The methods artist(), album(), comment(), genre(), year(), track() and total()
are called in the same way.

=cut

sub title {
	my $self = shift;
	if( @_ ) {
		$self->{title} = shift;
		return 1;
	}

	return $self->{title};
}

=head2 artist

Set/get the artist field in the files tag.

=cut

sub artist {
	my $self = shift;
	if( @_ ) {
		$self->{artist} = shift;
		return 1;
	}

	return $self->{artist};
}

=head2 album

Set/get the album field in the files tag.

=cut

sub album {
	my $self = shift;
	if( @_ ) {
		$self->{album} = shift;
		return 1;
	}

	return $self->{album};
}

=head2 comment

Set/get the comment field in the files tag.

=cut

sub comment {
	my $self = shift;
	if( @_ ) {
		$self->{comment} = shift;
		return 1;
	}

	return $self->{comment};
}

=head2 genre

Set/get the genre field in the files tag.

=cut

sub genre {
	my $self = shift;
	if( @_ ) {
		$self->{genre} = shift;
		return 1;
	}

	return $self->{genre};
}

=head2 year

Set/get the year field in the files tag.

=cut

sub year {
	my $self = shift;
	if( @_ ) {
		$self->{year} = shift;
		return 1;
	}

	return $self->{year};

}

=head2 track

Set/get the track field in the files tag.

=cut

sub track {
	my $self = shift;
	if( @_ ) {
		$self->{track} = shift;
		return 1;
	}
	
	return $self->{track} + 0;

}

=head2 total

Set/get the total number of tracks.

=cut

sub total {
	my $self = shift;
	if ( @_ ) {
		$self->{total} = shift;
		return 1;
	}

	return $self->{total} + 0;
}

=head2 all

Set/get all tags. To set the tags pass a hash reference with the names of the
tags as keys and the tag values as hash values. Returns a hash reference if no
argument is specified.

=cut

sub all {
	my $self = shift;

	if (@_) {
		my $tags = shift;
		$self->$_($tags->{$_}) for keys %{$tags};
		return 1;
	}

	return {
		title	=> $self->title(),
		artist	=> $self->artist(),
		album	=> $self->album(),
		comment	=> $self->comment(),
		genre	=> $self->genre(),
		year	=> $self->year(),
		track	=> $self->track(),
		total	=> $self->total()
	};
}

=head2 is_empty

Returns whether all tag fields are empty or not.

=cut

sub is_empty {
	my $self = shift;
	return ($self->title() &&
			$self->artist() &&
			$self->album() &&
			$self->comment() &&
			$self->genre() &&
			$self->year() &&
			$self->track() &&
			$self->total());
}

=head2 save

Saves the changed tag information. Not yet implemented.

=cut

sub save {

}

1;

=head1 TODO

=over 4

=item Implement writing tags

=back

=head1 AUTHOR

Florian Ragwitz <flora@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) Florian Ragwitz

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
