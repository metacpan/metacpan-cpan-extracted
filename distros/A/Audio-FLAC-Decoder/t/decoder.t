#!/usr/bin/perl -w

use Test;

BEGIN { plan tests => 15 };

use Audio::FLAC::Decoder;
use Fcntl qw(:seek);

ok(1);

ok(my $flac = Audio::FLAC::Decoder->open("t/test.flac"));
my $buffer;
ok($flac->sysread($buffer));
ok($flac->bits_per_sample == 16);
ok($flac->channels == 2);
ok($flac->sample_rate == 44100);

#ok($flac->raw_total);
#ok($flac->pcm_total);
#ok($flac->time_total);

ok($flac->raw_tell(), 14403);

#ok($flac->time_tell);

ok($flac->raw_seek(0, SEEK_SET), 0);
ok($flac->raw_seek(32768, SEEK_SET), 0);
ok($flac->raw_tell(), 32768);

# seek 5 seconds in.
# Windows seems to be off by 1 byte. Why?
if ($^O !~ /win32/i) {
	ok($flac->time_seek(5), 437488);

	# XXX - should check time_tell
	ok($flac->raw_tell(), 437488);
}

# test opening from a glob
ok(open FH, "t/test.flac" or die $!);
ok($flac = Audio::FLAC::Decoder->open(\*FH));
ok(close(FH));
