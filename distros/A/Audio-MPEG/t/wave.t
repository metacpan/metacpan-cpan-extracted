# $Id: wave.t,v 1.1 2001/06/17 16:12:13 ptimof Exp $
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 2 };
use Audio::MPEG;

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

sub gen_wav {
	open(IN, "<t/testcase.mp3") || return 0;
	open(WAV, ">t/test.wav") || return 0;
	my $d = Audio::MPEG::Decode->new;
	my $w = Audio::MPEG::Output->new({ type => 7, out_sample_rate => 8_000,
		out_channels => 1});
	my ($in, $wlen);
	return 0 if read(IN, $in, 40_000) !=  9591;
	$d->buffer($in);
	print WAV $w->header;
	while ($d->decode_frame) {
		return if $d->err and $d->err != 0x0101;
		$d->synth_frame;
		my $wav = $w->encode($d->pcm);
		$wlen += length($wav);
		print WAV $wav;
	}
	seek(WAV, 0, 0) || return 0;
	print WAV $w->header($wlen);
	return 0 if $wlen != 9196;
	return 1;
}

sub cmp_wav {
	return 0 if system('diff', 't/testcase.wav', 't/test.wav') != 0;
	return 1;
}

unlink("t/test.wav");
ok(gen_wav(), 1);
ok(cmp_wav(), 1);
unlink("t/test.wav");
exit 0;
