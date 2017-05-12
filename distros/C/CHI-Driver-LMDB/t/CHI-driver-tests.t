use strict;
use warnings;

use Test::More;

# ABSTRACT: test LMDB

use CHI::Driver::LMDB::t::CHIDriverTests;
CHI::Driver::LMDB::t::CHIDriverTests->runtests;
