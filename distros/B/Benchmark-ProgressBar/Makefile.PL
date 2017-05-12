use strict;
use inc::Module::Install;

name('Benchmark-ProgressBar');
all_from('lib/Benchmark/ProgressBar.pm');
requires('Benchmark');
requires('Term::ProgressBar');
build_requires('Test::More');

auto_include;
WriteAll;