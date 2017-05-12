#!/usr/bin/perl

use Test::More tests => 9;

BEGIN { use_ok('Audio::File'); }

my $tags = {
    # The test.wav does contain metadata ('tags') for 'Music',
    #   'BWAV' and 'Soundminer', but these are not standard.
    # Audio::Wav will throw warnings when processing this file
    #   because it does not understand the non-standard metadata blocks.
};

my $audio_properties = {
	Wav		=> {
		length		=> 4,
		bitrate		=> 128,
		sample_rate	=> 8000,
		channels	=> 1,
	}
};

my $file = Audio::File->new('t/test.wav');
is( ref $file, "Audio::File::Wav", 'Audio::File::new()' );
is( $file->type(), 'wav', 'Audio::File::Type::type()' );

is( ref $file->tag(), "Audio::File::Wav::Tag", "Audio::File::Wav::tag()" );
is( ref $file->audio_properties(), "Audio::File::Wav::AudioProperties", "Audio::File::Wav::audio_properties()" );

# No tags

for my $test (keys %{$audio_properties->{Wav}}) {
    is( $file->audio_properties()->$test(), $audio_properties->{'Wav'}->{$test}, "Audio::File::Wav::AudioProperties::${test}()" );
}
