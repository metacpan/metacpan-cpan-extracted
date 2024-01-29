#!/usr/bin/perl

use Test::More;

use strict;
use warnings;

require Test::CPAN::Changes;
plan skip_all => "Test::CPAN::Changes required for testing" if $@;
Test::CPAN::Changes->import;
changes_file_ok();
done_testing();
