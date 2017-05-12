use Module::Build;
Module::Build->new(
  module_name => 'Algorithm::Interval2Prefix',
  dist_version_from => 'Interval2Prefix.pm',
  pm_files => {'Interval2Prefix.pm' => 'lib/Algorithm/Interval2Prefix.pm'},
  requires => {Test::More => 0,
               Test::Pod => 0},
  license => 'perl',
  create_makefile_pl => 'traditional',
)->create_build_script;
