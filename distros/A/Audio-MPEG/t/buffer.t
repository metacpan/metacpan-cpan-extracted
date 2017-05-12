# $Id: buffer.t,v 1.1.1.1 2001/06/17 01:37:51 ptimof Exp $
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 3 };
use Audio::MPEG;

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

# add something to the buffer
ok(sub { my $d = Audio::MPEG::Decode->new; $d->buffer(""); }, 0);
ok(sub { my $d = Audio::MPEG::Decode->new; $d->buffer("12345"); }, 5);
ok(sub { my $d = Audio::MPEG::Decode->new; $d->buffer("12345"); $d->buffer("67890"); }, 10);
