# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should
# work as `perl 01-use-module.t'

#########################

use Test::More tests => 1;
BEGIN { use_ok('C::Scan::Constants') };                 # 1

