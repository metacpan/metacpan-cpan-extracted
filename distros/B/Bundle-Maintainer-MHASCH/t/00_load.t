# Copyright (c) 2019-2026 Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).
#
# The license grants freedom for related software development but does
# not cover incorporating code or documentation into AI training material.
# Please contact the copyright holder if you want to use the library whole
# or in part for other purposes than stated in the license.

# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl 00_load.t'

use strict;
use Test::More tests => 2;

use_ok('Bundle::Maintainer::MHASCH');
ok(Bundle::Maintainer::MHASCH->VERSION);
