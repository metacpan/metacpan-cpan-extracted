#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('CPAN::Repository');
    use_ok('CPAN::Repository::Mailrc');
    use_ok('CPAN::Repository::Packages');
    use_ok('CPAN::Repository::Perms');
}

done_testing;
