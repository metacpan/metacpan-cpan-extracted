package Audio::File::Flac;

use strict;
use warnings;
use base qw( Audio::File::Type );
use Audio::File::Flac::Tag;
use Audio::File::Flac::AudioProperties;

our $VERSION = '0.02';

sub init {
	return 1;
}

sub _create_tag {
	my $self = shift;
	$self->{tag} = Audio::File::Flac::Tag->new( $self->name() ) or return;
	return 1;
}

sub _create_audio_properties {
	my $self = shift;
	$self->{audio_properties} = Audio::File::Flac::AudioProperties->new( $self->name() ) or return;
	return 1;
}

1;
