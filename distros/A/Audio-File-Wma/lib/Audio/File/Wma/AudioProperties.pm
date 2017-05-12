package Audio::File::Wma::AudioProperties;

use strict;
use warnings;
use base qw( Audio::File::AudioProperties );
use Audio::WMA;

our $VERSION = '0.02';

sub init {
	my $self = shift;
	$self->{wma} = Audio::WMA->new( $self->{filename} ) or return;
    my $info = $self->{wma}->info;

	$self->length( $info->{playtime_seconds} );
    $self->bitrate( $info->{bitrate} );
	$self->sample_rate( $info->{sample_rate} );
	$self->channels( $info->{channels} );
	
	return 1;
}

1;
