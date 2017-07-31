use Test2::V0 -no_srand => 1;
use Alien::Base::ModuleBuild;

my $builder = Alien::Base::ModuleBuild->new(
  module_name  => 'My::Test::Module',
  dist_version => '1.234.567',
);

ok( $builder->alien_validate_repo( {platform => undef} ), "undef validates to true");

subtest 'windows test' => sub {
  skip_all "Windows test" unless $builder->is_windowsish();
  ok( $builder->alien_validate_repo( {platform => 'Windows'} ), "platform Windows on Windows");
  ok( ! $builder->alien_validate_repo( {platform => 'Unix'} ), "platform Unix on Windows is false");
};

subtest 'unix test' => sub {
  skip_all "Unix test" unless $builder->is_unixish();
  ok( $builder->alien_validate_repo( {platform => 'Unix'} ), "platform Unix on Unix");
  ok( ! $builder->alien_validate_repo( {platform => 'Windows'} ), "platform Windows on Unix is false");
};

subtest 'need c compiler' => sub {
  skip_all "Needs c compiler" unless $builder->have_c_compiler();
  ok( $builder->alien_validate_repo( {platform => 'src'} ), "platform src");
};

done_testing;

