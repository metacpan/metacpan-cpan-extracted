# $Id: base.t,v 1.1.1.1 2001/06/17 01:37:51 ptimof Exp $
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 4 };
use Audio::MPEG;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

# create a Decode object
ok(sub { my $d = Audio::MPEG::Decode->new });

# create an Ouput object
ok(sub { my $o = Audio::MPEG::Output->new });

# create an Encode object
ok(sub { my $e = Audio::MPEG::Encode->new });
