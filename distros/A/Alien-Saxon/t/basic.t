#!perl

use strict;
use warnings;
use Test::More;
use Alien::Saxon;

my $jar = Alien::Saxon->jar;
isnt $jar, '';
ok -f $jar, 'file exists' or diag "'$jar' not found: $!";

done_testing;
