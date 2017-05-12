#!perl

use strict;
use warnings;

use Data::Dump qw( dump );
use Test::More tests => 2;

require_ok('DBD::mysql');
require_ok('DBIx::MySQL::Replication::Slave');
