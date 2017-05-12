package Audio::File::Mp3::Tag;

use strict;
use warnings;
use base qw( Audio::File::Tag );
use MP3::Tag;

our $VERSION = '0.05';

sub init {
	my $self = shift;
	$self->{mp3} = MP3::Tag->new( $self->{filename} ) or return;
	$self->{mp3}->get_tags();

	my $info = $self->{mp3}->autoinfo;
	my $track = $info->{track};
	my $pos = index($track, '/');

	$self->title  (	$info->{ title   } );
	$self->artist (	$info->{ artist  } );
	$self->album  (	$info->{ album   } );
	$self->comment(	$info->{ comment } );
	$self->genre  (	$info->{ genre   } );
	$self->year   (	$info->{ year    } );
	$self->track  (	substr($track, 0, $pos)  );
	$self->total  (	substr($track, $pos + 1) );

	return 1;
}

1;
