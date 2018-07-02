use Module::Build;

my $build = Module::Build->new(

  module_name => 'App::MarkFiles',

  license  => 'gpl',

  configure_requires => {
    'Module::Build' => 0,
  },

  requires => {
    'Getopt::Long'  => 0,
    'POSIX'         => 0,
    'Cwd'           => 0,
    'DBI'           => 0,
    'DBD::SQLite'   => 0,
    'Sys::Hostname' => 0,
    'perl'          => '5.10.0',
  },

  recommends => {
  },

);

$build->create_build_script;
