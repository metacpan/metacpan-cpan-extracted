use strict;
use warnings;
use Module::Build::XSUtil;

my $builder = Module::Build::XSUtil->new(
  c_source => ['src'],
  configure_requires => +{
    'Module::Build' => '0.42',
    'Module::Build::XSUtil' => '0.14',
  },
  generate_ppport_h => 'ppport.h',
  include_dirs => ['.', 'src/liblinear', 'src/liblinear/blas'],
  license => 'mit',
  module_name => 'Algorithm::LibLinear',
  needs_compiler_cpp => 1,
  recursive_test_files => 1,
  requires => +{
    'perl' => '5.16.0',
    'List::MoreUtils' => 0,
    'Smart::Args::TypeTiny' => '0.12',
    'Type::Tiny' => '1.0',
  },
  test_files => ['t/', +($ENV{RELEASE_TESTING} ? 'xt/' : ())],
  test_requires => +{
    'Test::Deep' => 0,
    'Test::Exception' => 0,
    'Test::LeakTrace' => 0,
    'Test::More' => 0,
  },
  xs_files => +{ 'src/liblinear.xs' => 'lib/Algorithm/LibLinear.xs' },
);

$builder->create_build_script;
