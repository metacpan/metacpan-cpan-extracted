package Audio::File::Mp3::AudioProperties;

use strict;
use warnings;
use base qw( Audio::File::AudioProperties );
use MP3::Info;

our $VERSION = '0.03';

sub init {
	my $self = shift;
	my $info = get_mp3info( $self->{filename} ) or return;

	$self->length( $info->{SECS} );
	$self->bitrate( $info->{BITRATE} );
	$self->sample_rate( $info->{FREQUENCY} * 1000 );
	$self->channels( $info->{STEREO} ? 2 : 1 );

	return 1;
}

1;
