use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new
    ( module_name     => 'Catalyst::Plugin::Authentication::CDBI::Basic',
      license         => 'perl',
      requires        => {
           Catalyst                                => '5.33',
          'Catalyst::Plugin::Authentication::CDBI' => 0,
          'MIME::Base64'                           => 0,
           perl                                    => '5.6.0',
      },
    )->create_build_script;
