use Test::More;
eval "use Test::Perl::Critic";
plan skip_all => 'DEVELOPMENT environment not set'
  unless exists $ENV{DEVELOPMENT};
plan skip_all => "Test::Perl::Critic required for testing with Perl Critic"
  if $@;
Test::Perl::Critic->import(
    -profile => 't/perlcriticrc' );
all_critic_ok() ;
