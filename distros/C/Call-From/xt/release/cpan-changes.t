#!perl

use strict;
use warnings;

use Test::More 0.96;
use Test::CPAN::Changes;
changes_file_ok('Changes');
done_testing();
