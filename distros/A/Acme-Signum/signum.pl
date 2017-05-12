#!/usr/bin/perl -w

use strict;
use Acme::Signum;

$SIG[3]=sub{print "this works\n"};
kill(3,$$);
print ":)\n";
$SIG[3]='DEFAULT';
kill(3,$$);
print ":(\n";

