# $Id: encode.t,v 1.1 2001/06/17 16:24:06 ptimof Exp $
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

sub gen_mp3 {
	open(IN, "<t/testcase.mp3") || return 0;
	open(ENC, ">t/test.mp3") || return 0;
	my $d = Audio::MPEG::Decode->new;
	my $o = Audio::MPEG::Output->new;
	my $e = Audio::MPEG::Encode->new({ bit_rate => 64, mode => 'mono'});
	my ($in, $elen);
	return 0 if read(IN, $in, 40_000) !=  9591;
	$d->buffer($in);
	while ($d->decode_frame) {
		return if $d->err and $d->err != 0x0101;
		$d->synth_frame;
		my $enc = $e->encode_float($o->encode($d->pcm));
		$elen += length($enc);
		print ENC $enc;
	}
	my $enc = $e->encode_flush;
	$elen += length($enc);
	print ENC $enc;
	$e->encode_vbr_flush(*ENC);
	return 0 if $elen != 4806;
	return 1;
}

sub cmp_mp3 {
	return 0 if system('diff', 't/testcase2.mp3', 't/test.mp3') != 0;
	return 1;
}

unlink("t/test.mp3");
ok(gen_mp3(), 1);
ok(cmp_mp3(), 1);
unlink("t/test.mp3");
exit 0;
