package Audio::File::Flac::AudioProperties;

use strict;
use warnings;
use base qw( Audio::File::AudioProperties );
use Audio::FLAC::Header

our $VERSION = '0.02';

sub init {
	my $self = shift;
	$self->{flac} = Audio::FLAC::Header->new( $self->{filename} ) or return;
	my $flacinfo = $self->{flac}->info();

	$self->length( $self->{flac}->{trackTotalLengthSeconds} );
	$self->bitrate( $self->{flac}->{bitRate} );
	$self->sample_rate( $flacinfo->{SAMPLERATE} );
	$self->channels( $flacinfo->{NUMCHANNELS} );
	
	return 1;
}

1;
