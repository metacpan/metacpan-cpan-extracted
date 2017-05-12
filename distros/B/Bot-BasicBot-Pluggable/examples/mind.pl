#!/usr/bin/perl

# A standard Bot::BasicBot::Pluggable interface. You can /query the bot to
# load in more modules, I suggest Auth is a good start, so other people
# can't load modules, and CHANGE THE ADMIN PASSWORD.

# See perldoc Bot::BasicBot::Pluggable::Auth for details of this.

use warnings;
use strict;
use Bot::BasicBot::Pluggable;

my $bot = Bot::BasicBot::Pluggable->new( channels => [ ],
                                         server => "london.rhizomatic.net",
                                         nick => "jerabot",
                                         );
                                         
print "Loading Loader\n";
print $bot->load("Loader");

print "\n";

$bot->run();

