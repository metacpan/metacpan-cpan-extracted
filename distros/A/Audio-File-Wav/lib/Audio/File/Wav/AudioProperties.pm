package Audio::File::Wav::AudioProperties;

use strict;
use warnings;
use base qw( Audio::File::AudioProperties );
use Audio::Wav;

our $VERSION = '0.01';

sub init {
	my $self = shift;
    my $aw = Audio::Wav->new();
	$self->{wav} = $aw->read( $self->{filename} ) or return;
    my $dets = $self->{wav}->details;

	$self->length( $dets->{length} );
    $self->bitrate(
        $dets->{sample_rate} * $dets->{bits_sample} * $dets->{channels} * .001
        );
	$self->sample_rate( $dets->{sample_rate} );
	$self->channels( $dets->{channels} );
	
	return 1;
}

1;
