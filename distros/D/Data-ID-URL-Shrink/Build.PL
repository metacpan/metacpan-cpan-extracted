use Module::Build;
my $build = Module::Build->new
(
  module_name => 'Data::ID::URL::Shrink',
  dist_author => 'Rick Yakubowski <yakubori@cpan.org>',
  license  => 'perl',
  requires => {
    'perl' => '5.16.2',
    'Exporter' => '5.6.7',
    'Module::Build' => '0.4003',
    'POSIX' => '1.30',
    'Test::More' => '0.98',
  },
);
$build->create_build_script;
