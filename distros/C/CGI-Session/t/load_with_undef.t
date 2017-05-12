#!/usr/bin/perl

use strict;
use warnings;

use CGI;
use CGI::Session;
use Test::More tests => 6;

# ---------------

{
my($session) = CGI::Session -> load(undef);

isa_ok($session, 'CGI::Session', 'load(undef) returns an object which');

my($id) = $session -> id();

is($id, undef, "load(undef)'s session object returns an id which /is/ undef");
}

{
my($q)       = CGI -> new();
my($session) = CGI::Session -> load($q);

isa_ok($session, 'CGI::Session', 'load($q without CGISESSID) returns an object which');

my($id) = $session -> id();

is($id, undef, "load(\$q without CGISESSID)'s session object returns an id which /is/ undef");
}

{
my($q) = CGI -> new();

$q -> param(CGISESSID => 'Purple cats is weird');

my($session) = CGI::Session -> load($q);

isa_ok($session, 'CGI::Session', 'load($q with fake CGISESSID) returns an object which');

my($id) = $session -> id();

is($id, undef, "load(\$q with fake CGISESSID)'s session object returns an id which /is/ undef");
}
