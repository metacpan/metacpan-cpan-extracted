#!perl -I./t

use strict;
use warnings;
use DBI();
use DBD_TEST();

use Test::More;

if (not defined $ENV{DBI_DSN}) {
  plan skip_all => 'Cannot test without DB info';
}

eval "require Capture::Tiny;";
if ($@) {
  plan skip_all => 'Capture::Tiny required for this test';
}

plan tests => 1;

my ($stdout, $stderr) = Capture::Tiny::capture(sub {
  system $^X, '-w', 't/52glob_dest.pl';
});

ok((length $stdout == 0 && length $stderr == 0),
  'no warnings in global destruction')
  or do {
    diag 'STDOUT: ', $stdout;
    diag 'STDERR: ', $stderr;
};
