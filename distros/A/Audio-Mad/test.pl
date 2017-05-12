# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 8 };

print "import test..   ";
use Audio::Mad qw(:all);
ok(1); # If we made it this far, we're ok.


#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

my ($temp);

print "read mp3..      ";
open(my $testmp3, "<test.mp3") || die "failed to open test mp3";
$temp = join('', <$testmp3>);
close($testmp3);
ok(1);


print "stream test..   ";
my $stream = new Audio::Mad::Stream;
$stream->buffer($temp);
print "buffered " . length($temp) . " bytes of mp3 data.. ";
ok(1);


# if you are reading this file as an example of what to do:  DO NOT DO
# WHAT I DO HERE.  mpeg data is frame-interdependant,  and creating a 
# new frame each time around the loop looses the data provided by the
# previous frame.  We only do this here for purposes of testing the
# underlying extension and library.  You should create at most one frame
# object per mpeg stream and use it to decode the entire stream.
print "frames test..   ";
my @frames = ();
FRAME: while (1) {
	my $frame = new Audio::Mad::Frame;
	push(@frames, $frame);
	
	if ($frame->decode($stream) == -1) {
		next FRAME if ($stream->err_ok()); #recoverable
		last FRAME if ($stream->error() == MAD_ERROR_BUFLEN); #done
		print "FAILED,  stream error: " . $stream->error();
		ok(0);
	}
}
print "decoded " . ($#frames + 1) . " frames.. ";
ok(1);

print "timer test..    ";
my $timer = new Audio::Mad::Timer;
foreach my $frame (@frames) {
	$timer += $frame->duration();
}
print "timer total: ${timer}.. ";
ok(1);

	
print "synth test..    ";
my $synth = new Audio::Mad::Synth;
my @pcmout;
foreach my $frame (@frames) {
	$synth->synth($frame);
	my ($left, $right, $shit) = $synth->samples();

	$pcmout[0] .= $left;
	$pcmout[1] .= $right if (defined($right));
}
$temp = (length($pcmout[0]) + length($pcmout[1]));
print "synthesized $temp bytes (".($temp/4)." samples) of raw data.. ";
ok(1);

print "resample test.. ";
my $resample = new Audio::Mad::Resample($frames[0]->samplerate, 22050);
my @rpcmout = $resample->resample(@pcmout);
$temp = (length($rpcmout[0]) + length($rpcmout[1]));
print "resampled to $temp bytes (".($temp/4)." samples) of raw data.. ";
ok(1);

print "dither test..   ";
my $dither = new Audio::Mad::Dither(MAD_DITHER_S16_LE);
my $routput = $dither->dither(@rpcmout);
print "dithered into " . length($routput) . " bytes of signed-16-pcm data.. ";
ok(1);
