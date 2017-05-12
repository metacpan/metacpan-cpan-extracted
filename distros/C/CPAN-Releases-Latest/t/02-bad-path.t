#!perl

use strict;
use warnings;

use Test::More 0.88 tests => 1;
use CPAN::Releases::Latest;

my $latest;

eval { $latest = CPAN::Releases::Latest->new(path => 't/file-not-there.txt') };
ok(defined($@) && $@ =~ m!the file you specified with 'path' doesn't exist!,
   "If you specify a path, and the file's not there, it should croak");

