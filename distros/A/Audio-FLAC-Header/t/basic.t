#!/usr/bin/perl -w

use strict;
use Test::More tests => 43;
use File::Spec::Functions qw(:ALL);

BEGIN { use_ok('Audio::FLAC::Header') };

#########################

{
        # Always test pure perl
        my @constructors = ('_new_PP');

        # Only test XS if built
        SKIP: {
                eval { Audio::FLAC::Header->_new_XS(catdir('data', 'test.flac')) };
                skip "Not built with XS", 21 if $@;

                push @constructors, '_new_XS';
        }


        # Be sure to test both code paths.
        for my $constructor (@constructors) {

		my $flac = Audio::FLAC::Header->$constructor(catdir('data', 'test.flac'));

		ok($flac, "constructor: $constructor");

		my $info = $flac->info();

		ok($info, "info block");

		ok($flac->info('SAMPLERATE') == 44100, "sample rate");
		ok($flac->info('MD5CHECKSUM') eq '592fb7897a3589c6acf957fd3f8dc854', "md5");
		ok($flac->info('TOTALSAMPLES') == 153200460, "total samples");
		ok($flac->info('BITSPERSAMPLE') == 16, "bits per sample $constructor");
		ok($flac->info('NUMCHANNELS') == 2, "channels $constructor");
		ok($flac->info('MINIMUMBLOCKSIZE') == 4608, "minimum block size $constructor");
		ok($flac->info('MAXIMUMBLOCKSIZE') == 4608, "maximum block size $constructor");
		ok($flac->info('MINIMUMFRAMESIZE') == 14, "minimum frame size $constructor");
		ok($flac->info('MAXIMUMFRAMESIZE') == 18002, "maximum frame size $constructor");

		my $tags = $flac->tags();

		ok($tags, "tags read");

		is($flac->tags('AUTHOR'), 'Praga Khan', "AUTHOR ok");

		# XXX - should have accessors
		ok($flac->{'trackLengthFrames'} =~ /70.00\d+/);
		ok($flac->{'trackLengthMinutes'} == 57);
		ok($flac->{'bitRate'} =~ /1.236\d+/);
		ok($flac->{'trackTotalLengthSeconds'} =~ /3473.93\d+/);

		my $cue = $flac->cuesheet();

		ok $cue;

		ok(scalar @{$cue} == 37);

		ok($cue->[35] =~ /REM FLAC__lead-in 88200/);
		ok($cue->[36] =~ /REM FLAC__lead-out 170 153200460/);
	}
}

__END__
