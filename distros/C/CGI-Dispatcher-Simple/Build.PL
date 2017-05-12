use Module::Build;

Module::Build->new
    ( module_name     => 'CGI::Dispatcher::Simple',
      license         => 'perl',
      requires => {
          CGI => 0,
          Carp => 0,
          Class::Accessor::Fast => 0,
      },
      dist_version_from => 'lib/CGI/Dispatcher/Simple.pm',
      dist_author => 'Daisuke Murase <typester@cpan.org>',
    )->create_build_script;
