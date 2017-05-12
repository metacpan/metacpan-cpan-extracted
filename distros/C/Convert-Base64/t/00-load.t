#!perl

use strict;
use warnings;

use Test::More tests => 1;

require_ok('Convert::Base64');

local $Convert::Base64::VERSION = $Convert::Base64::VERSION || 'from repo';
note("Convert::Base64 $Convert::Base64::VERSION, Perl $], $^X");
