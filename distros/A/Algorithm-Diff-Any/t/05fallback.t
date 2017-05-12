#!/usr/bin/perl -T

# t/05fallback.t
#  Tests use of the Pure Perl interface
#
# $Id: 05fallback.t 10347 2009-12-03 01:57:00Z FREQUENCY@cpan.org $

use strict;
use warnings;

use Test::More;

# Cannot 'use' because we might skip tests
require Test::NoWarnings;

eval {
  require Test::Without::Module;
};
if ($@) {
  plan skip_all => 'Test::Without::Module required to test fallback ability';
}

plan tests => 5;

# Delay loading of test hooks
Test::NoWarnings->import();

# Hide the XS version
Test::Without::Module->import('Algorithm::Diff::XS');

# Try to load Algorithm::Diff::Any
eval {
  require Algorithm::Diff::Any;
  Algorithm::Diff::Any->import();
};
ok(!$@, 'Algorithm::Diff::Any interface compiled and loaded');

my $diff = Algorithm::Diff::Any->new(
  [ qw(a b c d e f) ],
  [ qw(a b c d f g) ]
);
isa_ok($diff, 'Algorithm::Diff::Any');

ok(defined $Algorithm::Diff::Any::DRIVER, 'The DRIVER is defined');
is($Algorithm::Diff::Any::DRIVER, 'PP', 'Pure Perl version is loaded');
