use Module::Build;

my $builder = Module::Build->new(
    module_name => 'CPAN::Mini::Webserver::PSGI',
  'build_requires' => {
    'Compress::Zlib' => '2.033',
    'File::Path' => '2.08',
    'File::Slurp' => '9999.16',
    'HTTP::Request::Common' => '6.00',
    'Module::Build' => '0.3601',
    'Plack::Test' => '0',
    'Test::Builder' => '0.98',
    'URI' => '1.58'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'requires' => {
    'CGI' => '3.53',
    'CGI::Emulate::PSGI' => '0.11',
    'CPAN::Mini::Webserver' => '0.51'
  },
    recursive_test_files => 0,
);
$builder->create_build_script;
