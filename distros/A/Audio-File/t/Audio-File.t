#!/usr/bin/perl

use Test::More tests => 49;

BEGIN { use_ok('Audio::File'); }

my $tags = {
	Flac	=> {
		title	=> 'Title',
		artist	=> 'Artist',
		album	=> 'Album',
		comment	=> 'Comment',
		genre	=> 'Rock',
		year	=> 2005,
		track	=> 2,
		total	=> 3
	}
};
$tags->{Mp3} = $tags->{Ogg} = $tags->{Flac};

my $audio_properties = {
	Flac	=> {
		length		=> 4,
		bitrate		=> 94910,
		sample_rate	=> 8000,
		channels	=> 1
	},
	Ogg		=> {
		length		=> 4,
		bitrate		=> 28000,
		sample_rate	=> 8000,
		channels	=> 1
	},
	Mp3		=> {
		length		=> 4,
		bitrate		=> 8,
		sample_rate	=> 8000,
		channels	=> 1
	}
};

for my $type (keys %{$tags}) {
	my $file = Audio::File->new('t/test.'.lc($type));
	is( ref $file, "Audio::File::${type}", 'Audio::File::new()' );
	is( $file->type(), lc $type, 'Audio::File::Type::type()' );

	is( ref $file->tag(), "Audio::File::${type}::Tag", "Audio::File::${type}::tag()" );
	is( ref $file->audio_properties(), "Audio::File::${type}::AudioProperties", "Audio::File::${type}::audio_properties()" );

	for my $test (keys %{$tags->{$type}}) {
		is( $file->tag()->$test(), $tags->{$type}->{$test}, "Audio::File::${type}::Tag::${test}()" );
	}

	for my $test (keys %{$audio_properties->{$type}}) {
		is( $file->audio_properties()->$test(), $audio_properties->{$type}->{$test}, "Audio::File::${type}::AudioProperties::${test}()" );
	}
}
