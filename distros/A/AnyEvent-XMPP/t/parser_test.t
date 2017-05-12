#!perl
use strict;
use Test::More;
use AnyEvent::XMPP::Parser;

plan tests => 1;

my $p = AnyEvent::XMPP::Parser->new;

my $recv;
$p->set_stanza_cb (sub {
   my ($p, $node) = @_;
   $recv = $node->as_string;
});
$p->init;

my $stanza = "<message><![CDATA[FOOAREE<<>>&gt;]]></message>";

$p->feed ("<stream>");
$p->feed ($stanza);

is ($recv, $stanza, "cdata was parsed and stored correctly");
