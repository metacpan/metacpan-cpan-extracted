#!perl
use strict;
use Test::More tests => 1;
use AnyEvent::XMPP::Util qw/filter_xml_chars/;

is (filter_xml_chars ("BB\a\bAA"), "BBAA", "filters out bad chars");
