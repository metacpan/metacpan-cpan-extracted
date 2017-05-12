#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 1 }

ok( eval { require DDLock::Client; 1 } );
