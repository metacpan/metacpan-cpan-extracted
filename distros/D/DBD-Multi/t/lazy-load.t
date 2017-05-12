# vim: ft=perl
use Test::More 'no_plan';
use Test::Exception;

# Test that the handles are lazy-loaded. 
use strict;
$^W = 1;

use DBI;
my $c = DBI->connect('DBI:Multi:', undef, undef, {
    dsns => [
        1 => ['dbi:Boom', '',''],
    ],
});

isa_ok $c, 'DBI::db', "invalid connect strict survives DBD::Multi connect()";

dies_ok { $c->prepare("CREATE TABLE multi(id int)") }
 "invalid connect string blows up when handle is actually attempted to be used";

lives_ok { $c->disconnect } 
  "Don't connect just to disconnect";
