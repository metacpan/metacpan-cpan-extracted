#!perl -T
# Written by Wesley Hinds
use 5.006;
use strict;
use warnings;

use Test::More tests => 1;

# This is a regression test for github #4. It can work with or without internet since
# the JSON failure happens either way.

use Bitcoin::RPC::Client;

# We will use 234.198.51.100 as it is designated for test purposes.
# https://tools.ietf.org/html/rfc6676

eval {
   my $btc = Bitcoin::RPC::Client->new(
      user     => "username",
      password => "p4ssword",
      host     => "234.198.51.100",
   );
   $btc->getblockchaininfo;
}; 

unlike($@, qr/malformed JSON/, "Handled 'malformed JSON' response correctly.");
