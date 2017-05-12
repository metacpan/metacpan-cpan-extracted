# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Data-Range-Compare-Stream.t'

#########################


use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 2;

# not much to do other than load the package
BEGIN { use_ok('Data::Range::Compare::Stream::Constants') };
BEGIN { use_ok('Data::Range::Compare::Stream') };

