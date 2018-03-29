use strict;
use warnings;
use Test::More;
use Alien::gdal;
use Config;

BEGIN {
  plan skip_all => 'test requires Test::CChecker'
    unless eval q{ use Test::CChecker; 1 };
}

plan tests => 1;

compile_with_alien 'Alien::gdal';

compile_output_to_note;

compile_run_ok do { local $/; <DATA> }, "basic compile test";

__DATA__

#include <stdio.h>
#include <gdal.h>

int main()
{
   printf("Hello, World!");
   return 0;
}
