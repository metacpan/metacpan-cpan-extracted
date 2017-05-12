use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new
    ( module_name     => 'Catalyst::Plugin::Authentication::Store::HTTP',
      license         => 'perl',
      requires => {
          Catalyst => '5.30',
          'Catalyst::Plugin::Authentication' => '0.05',
          'LWP::UserAgent' => 0,
      },
    )->create_build_script;
