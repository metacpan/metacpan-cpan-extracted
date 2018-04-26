use strict;
use Test::More;

plan skip_all => "skip outside CPAN client"
  unless exists $ENV{PERL_MM_USE_DEFAULT};

is $ENV{PERL_USE_UNSAFE_INC}, '0';

done_testing;
