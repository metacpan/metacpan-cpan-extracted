#!perl

use strict;
use warnings;

use Test::More tests => 5;

use File::Spec;

use_ok( 'App::Module::Template', '_get_module_fqfn' );

ok( my $dirs = ['lib', 'Part1', 'Part2'], 'set $dirs' );

ok( my $file = 'Module.pm', 'set $file' );

ok( my $part = File::Spec->catfile('lib', 'Part1', 'Part2', 'Module.pm' ), 'set part' );

is(
  _get_module_fqfn($dirs, $file), $part, 'get_module_fqfn'
);
