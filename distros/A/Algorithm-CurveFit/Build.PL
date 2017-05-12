use Module::Build;

my $b = Module::Build->new
  (
   module_name => 'Algorithm::CurveFit',
   dist_author => 'Steffen Mueller <smueller@cpan.org>',
   license => 'perl',
   requires => {
                'Data::Dumper' => '0',
                'Math::Symbolic' => '0.602',
                'Math::MatrixReal' => '0',
                'perl' => 5.006,
               },
   recommends => {
                  'Test::Pod' => '1.0',
                  'Test::Pod::Coverage' => '1.0',
                 },
   build_requires => {
                      'Test::More' => 0,
                     },
   create_makefile_pl => 'traditional',
#   conflicts => {},
#   script_files => [],
  );

$b->create_build_script;

