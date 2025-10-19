#!perl -w

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Needs 'Test::Strict';

Test::Strict->import();
all_perl_files_ok();
warnings_ok('lib/Database/Abstraction.pm');
