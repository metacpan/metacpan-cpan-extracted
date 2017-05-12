package Audio::File::Mp3;

use strict;
use warnings;
use base qw( Audio::File::Type );
use Audio::File::Mp3::Tag;
use Audio::File::Mp3::AudioProperties;

our $VERSION = '0.05';

sub init {
	return 1;
}

sub _create_tag {
	my $self = shift;
	$self->{tag} = Audio::File::Mp3::Tag->new( $self->name() ) or return;
	return 1;
}

sub _create_audio_properties {
	my $self = shift;
	$self->{audio_properties} = Audio::File::Mp3::AudioProperties->new( $self->name() ) or return;
	return 1;
}

1;
