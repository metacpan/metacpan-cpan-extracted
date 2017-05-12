use strict;
use warnings;
use Test::More;
use Alien::Hunspell;
use ExtUtils::CBuilder;
use Text::ParseWords qw( shellwords );
use Test::CChecker 0.07;
#use ExtUtils::CppGuess;

#BEGIN {
#  plan skip_all => 'test requires Test::CChecker 0.07 and ExtUtils::CppGuess'
#    unless eval q{ use Test::CChecker 0.07; use ExtUtils::CppGuess; 1 }
#}

plan skip_all => 'Test requires compiler' unless ExtUtils::CBuilder->new->have_compiler;

plan tests => 2;

compile_output_to_note;

compile_with_alien 'Alien::Hunspell';

#my %cppguess = ExtUtils::CppGuess->new->module_build_options;
#cc->push_extra_compiler_flags(shellwords $cppguess{extra_compiler_flags});
#cc->push_extra_linker_flags(shellwords $cppguess{extra_linker_flags});

my $source = do { local $/; <DATA> };

compile_ok $source, 'basic compile test';

TODO: {
  local $TODO = 'C++ is hard to test';
  compile_run_ok $source, "basic compile/link/run test";
}

__DATA__
#include <hunspell.h>

int
main(int argc, char *argv[])
{
  Hunhandle *h;
  
  h = Hunspell_create("","");
  Hunspell_destroy(h);
  
  return 0;
}
