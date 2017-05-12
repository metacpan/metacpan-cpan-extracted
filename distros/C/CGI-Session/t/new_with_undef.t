#!/usr/bin/perl

use strict;
use warnings;

use CGI;
use CGI::Session;
use Test::More tests => 6;

# ---------------

{
my($session) = CGI::Session -> new(undef);

isa_ok($session, 'CGI::Session', 'new(undef) returns an object which');

my($id) = $session -> id();

isnt($id, undef, "new(undef)'s session object returns an id which is /not/ undef");
}

{
my($q)       = CGI -> new();
my($session) = CGI::Session -> new($q);

isa_ok($session, 'CGI::Session', 'new($q without CGISESSID) returns an object which');

my($id) = $session -> id();

isnt($id, undef, "new(\$q without CGISESSID)'s session object returns an id which is /not/ undef");
}

{
my($q) = CGI -> new();

$q -> param(CGISESSID => 'Purple cats is weird');

my($session) = CGI::Session -> new($q);

isa_ok($session, 'CGI::Session', 'new($q with fake CGISESSID) returns an object which');

my($id) = $session -> id();

isnt($id, undef, "new(\$q with fake CGISESSID)'s session object returns an id which is /not/ undef");
}
