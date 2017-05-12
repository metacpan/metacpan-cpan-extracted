#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Acme::Shining;

my $sub = \&Acme::Shining::_getline;
print "1..999999\n";
printf("ok %6u %s", $_, &$sub()) for(1..999999);
