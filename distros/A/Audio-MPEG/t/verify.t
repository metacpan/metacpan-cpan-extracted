# $Id: verify.t,v 1.2 2001/06/17 16:11:39 ptimof Exp $
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

ok(sub {
	my $d = Audio::MPEG::Decode->new;
	$d->verify_mp3file("t/testcase.mp3");
}, 1);

ok(sub {
	my $d = Audio::MPEG::Decode->new;
	$d->verify_mp3file("t/testcase.mp3", 1);
}, 1);

