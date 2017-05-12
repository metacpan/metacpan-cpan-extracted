use Module::Build;
Module::Build->new(
  module_name => 'Date::Holidays::DK',
  dist_version_from => 'DK.pm',
  pm_files => {'DK.pm' => 'lib/Date/Holidays/DK.pm'},
  requires => {Date::Simple => 0,
	       Date::Easter => 0,
	       Test::More => 0,
              },
  license => 'perl',
  create_makefile_pl => 'traditional',
)->create_build_script;
