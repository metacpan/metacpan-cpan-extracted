# Copyright (c) 2019-2021 Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl 00_load.t'

use strict;
use Test::More tests => 2;

use_ok('Bundle::Maintainer::MHASCH');
ok(Bundle::Maintainer::MHASCH->VERSION);
