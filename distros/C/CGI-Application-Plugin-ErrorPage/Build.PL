use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new
    ( module_name     => 'CGI::Application::Plugin::ErrorPage',
      license         => 'perl',
      requires        => {
          'Test::More'       => 0,
          'CGI::Application' => 0,
          'Params::Validate' => 0, 
      },
    )->create_build_script;
