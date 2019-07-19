use strict;
use warnings;
use Test::More;

BEGIN {
  if(eval { require Test2::Tools::PerlCritic; 1 })
  {
    Test2::Tools::PerlCritic->import;
  }
  else
  {
    plan skip_all => 'Test requires Test2::Tools::PerlCritic';
  }
}

my $critic = Perl::Critic->new(
  -profile => 'perlcriticrc',
);

perl_critic_ok ['lib','t'], $critic;

done_testing;
