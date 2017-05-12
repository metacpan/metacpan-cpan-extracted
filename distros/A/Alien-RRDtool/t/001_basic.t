#!perl -w
use strict;
use Test::More;

use Alien::RRDtool;

note( Alien::RRDtool->prefix );

ok -d Alien::RRDtool->prefix;

ok -d Alien::RRDtool->include;
ok -d Alien::RRDtool->lib;
ok -d Alien::RRDtool->share;

done_testing;
