#!/usr/bin/perl

use Test::More tests => 17;

BEGIN { use_ok('Audio::File'); }

my $tags = {
    # I didn't have a WMA editor handy, but the file has some
    #   blank information (as opposed to undef) that we can test.
    Wma => {
        'track' => 0,
        'total' => 0,
        'genre' => undef,
        'artist' => '',
        'album' => undef,
        'comment' => '',
        'title' => '',
        'year' => undef,
    }
};

my $audio_properties = {
	Wma		=> {
		length		=> 65,
		bitrate		=> 129084,
		sample_rate	=> 44100,
		channels	=> 2,
	}
};

my $file = Audio::File->new('t/test.wma');
is( ref $file, "Audio::File::Wma", 'Audio::File::new()' );
is( $file->type(), 'wma', 'Audio::File::Type::type()' );

is( ref $file->tag(), "Audio::File::Wma::Tag", "Audio::File::Wma::tag()" );
is( ref $file->audio_properties(), "Audio::File::Wma::AudioProperties", "Audio::File::Wma::audio_properties()" );

for my $test (keys %{$tags->{Wma}}) {
    is( $file->tag()->$test(), $tags->{Wma}->{$test}, "Audio::File::Wma::Tag::${test}()" );
}

for my $test (keys %{$audio_properties->{Wma}}) {
    is( $file->audio_properties()->$test(), $audio_properties->{'Wma'}->{$test}, "Audio::File::Wma::AudioProperties::${test}()" );
}
