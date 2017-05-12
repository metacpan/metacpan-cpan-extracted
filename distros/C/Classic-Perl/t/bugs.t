#!perl

no # silly
warnings # about using variables
once=>;

use Classic::Perl;

print "1..1\n";

$a ||= 3;
$a ||= $b;

print "ok 1 - no ||= crash\n";
