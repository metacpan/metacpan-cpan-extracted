#!/usr/bin/env perl
use warnings;
use strict;
use Test::More;

plan skip_all => 'This test should use POE::Component::Server::IRC';

use lib qw(lib t/lib);

require IO::Socket;
my $s = IO::Socket::INET->new(
  PeerAddr => "irc.perl.org:80",
  Timeout  => 10,
);

if ($s) {
  close($s);
  plan tests => 4;
} else {
  plan skip_all => "no net connection available";
  exit;
}



use TestBot;

my $bot = TestBot->new(
  nick => "basicbot_$$",
  server => "irc.perl.org",
  channels => ["#bot_basicbot_test"],
);

$bot->run;

