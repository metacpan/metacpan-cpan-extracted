#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Data::Dumper;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use DBIx::MultiDB;

system("sh $Bin/init_db.sh");

plan tests => 1;

pass();
