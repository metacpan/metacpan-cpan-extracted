#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
eval "use Test::Prereq";
my $msg;
if ($@) {
         $msg = 'Test::Prereq required to test dependencies';
} elsif (not $ENV{RELEASE_TESTING}) {
         $msg = 'Author test.  Set $ENV{RELEASE_TESTING} to a true value to run.';
}
plan skip_all => $msg if $msg;

prereq_ok();
