#!perl
use strict;
use warnings;
use Test::More tests => 2;
use Test::NoWarnings;

eval "use Data::Reach as => ''";
my $err = $@;
like $err, qr/no export name/;






