package Audio::File::Ogg::AudioProperties;

use strict;
use warnings;
use base qw( Audio::File::AudioProperties );
use Ogg::Vorbis::Header::PurePerl;

our $VERSION = '0.01';

sub init {
	my $self = shift;
	$self->{ogg} = Ogg::Vorbis::Header::PurePerl->new( $self->{filename} ) or return;
	my $ogginfo = $self->{ogg}->info();

	$self->length( $ogginfo->{length} );
	$self->bitrate( $ogginfo->{bitrate_nominal} );
	$self->sample_rate( $ogginfo->{rate} );
	$self->channels( $ogginfo->{channels} );

	return 1;
}

1;
