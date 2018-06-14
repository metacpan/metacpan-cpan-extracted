#!perl -w

use lib 't/lib';
use strict;
use warnings;

use CHI::Driver::BerkeleyDB::Tests;

CHI::Driver::BerkeleyDB::Tests->runtests;
