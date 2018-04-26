use strict;
use Test::More;
use CPAN::Test::Dummy::Perl5::UseUnsafeINC::One;

plan skip_all => "Skip outside CPAN"
  unless exists $ENV{PERL_MM_USE_DEFAULT};

eval { require t::Foo };

is $@, '';

done_testing;
