#!/usr/bin/perl
#
# For use with XChat supporting Perl extension. Just install Acme::Laugh
# and put this into your $HOME/.xchat2 directory.
#
# It will add a /laugh command that supports the following variants:
#
# /laugh                # just generate a random laugh
# /laugh 50             # use 50 chunks of laugh, real length varies
# /laugh somenick       # laugh at somenick
# /laugh somenick 50    # a combination of the two
#
use strict;
use Acme::Laugh qw(laugh);

Xchat::register("laugh", "1.1", "", "");
Xchat::print ("laugh 1.1 loaded.");
Xchat::print ("Usage /laugh [<nick>] [length]");
Xchat::hook_command ("laugh", sub {
	my ($command, $nick, $chunks) = @{$_[0]};
   if ($nick =~ /\A \d+ \z/xms) {
      $chunks = $nick;
      $nick = '';
   }
   elsif ($nick) {
      $nick .= ': ';
   }
   $chunks = 17 unless $chunks > 0;
	Xchat::command("SAY $nick" . laugh($chunks));
});
