#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 2;

## Most user will never run a test as most testing need login data 
## So we run a few tests just to be sure that nothings really terrible
## has happend

BEGIN {
	use_ok('Net::ManageSieve::Siesh');
	use_ok('App::Siesh');
}
