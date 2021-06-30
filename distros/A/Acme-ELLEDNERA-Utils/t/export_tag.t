#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

use Acme::ELLEDNERA::Utils ":all";

ok( defined &sum, "sum exported through :all" );
ok( defined &shuffle, "shuffle exported through :all" );

done_testing();

# besiyata d'shmaya



