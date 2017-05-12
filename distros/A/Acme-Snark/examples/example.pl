#!/usr/bin/perl

use Acme::Snark;
tie $foo, Acme::Snark;

$foo = 0;
$foo = 0;
$foo = 0;

print "True\n" if $foo;
