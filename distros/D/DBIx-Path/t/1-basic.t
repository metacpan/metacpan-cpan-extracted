#!perl

use strict;
use warnings;

use Test::More tests => 8;

use lib 't';
require 'testdb.pl';

use_ok('DBIx::Path');
can_ok('DBIx::Path', $_) for qw(new get set add del list resolve);
