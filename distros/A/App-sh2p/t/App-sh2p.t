# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl App-sh2p.t'

#########################
# 0.05
# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 10;

# BEGIN { use_ok('App::sh2p') };

use_ok('App::sh2p::Builtins');
use_ok('App::sh2p::Compound');
use_ok('App::sh2p::Handlers');
use_ok('App::sh2p::Here');
use_ok('App::sh2p::Operators');
use_ok('App::sh2p::Parser');
use_ok('App::sh2p::Statement');  # Added at 0.05
use_ok('App::sh2p::Trap');       # Added at 0.05
use_ok('App::sh2p::Utils');

ok( require( 'bin/sh2p.pl'), 'loaded main OK') or exit;

#########################

# Tests to be supplied
# 

