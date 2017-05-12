#!perl
use strict;
use Test::More;
use AnyEvent::XMPP::Util qw/split_jid/;

my @data = (
   ['msn.im.sapo.pt'        => undef,   'msn.im.sapo.pt', undef],
   ['elmex@jabber.org/test' => 'elmex', 'jabber.org',     'test'],
   ['jabber.org/test'       => undef,   'jabber.org',     'test'],
   ['elmex@jabber.org'      => 'elmex', 'jabber.org',     undef],
);

plan tests => (scalar @data) * 3;

for (@data) {
   my ($n, $h, $r) = split_jid ($_->[0]);

   is ($n, $_->[1], "jid [$_->[0]]: node empty");
   is ($h, $_->[2], "jid [$_->[0]]: host");
   is ($r, $_->[3], "jid [$_->[0]]: resource empty");
}
