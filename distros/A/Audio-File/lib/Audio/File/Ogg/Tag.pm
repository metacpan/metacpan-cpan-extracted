package Audio::File::Ogg::Tag;

use strict;
use warnings;
use base qw( Audio::File::Tag );
use Ogg::Vorbis::Header::PurePerl;

our $VERSION = '0.02';

sub init {
	my $self = shift;
	$self->{ogg} = Ogg::Vorbis::Header::PurePerl->new( $self->{filename} ) or return;

	$self->title(	$self->{ogg}->comment('title')			);
	$self->artist(	$self->{ogg}->comment('artist')			);
	$self->album(	$self->{ogg}->comment('album')			);
	$self->comment(	$self->{ogg}->comment('comment')		);
	$self->genre(	$self->{ogg}->comment('genre')			);
	$self->year(	$self->{ogg}->comment('date')			);
	$self->track(	$self->{ogg}->comment('tracknumber')	);
	$self->total(	$self->{ogg}->comment('tracktotal')		);

	return 1;
}

1;
