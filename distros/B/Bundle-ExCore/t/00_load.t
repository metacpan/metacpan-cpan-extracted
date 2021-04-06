# Copyright (c) 2015-2021 Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

use strict;
use Test::More tests => 2;

use_ok('Bundle::ExCore');
ok(Bundle::ExCore->VERSION);
