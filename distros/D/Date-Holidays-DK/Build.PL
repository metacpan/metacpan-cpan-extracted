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
  meta_merge => {
    resources => {
            homepage   => 'https://metacpan.org/pod/Date::Holidays::DK',
            bugtracker => 'https://github.com/tagg/Date-Holidays-DK/issues',
            repository => 'https://github.com/tagg/Date-Holidays-DK',
    }
  },
)->create_build_script;
