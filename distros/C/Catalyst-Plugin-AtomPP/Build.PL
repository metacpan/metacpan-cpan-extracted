use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new
    ( module_name       => 'Catalyst::Plugin::AtomPP',
      dist_version_from => 'lib/Catalyst/Plugin/AtomPP.pm',
      license           => 'perl',
      requires          => {
          Catalyst => '5.30',
          'XML::Atom' => 0,
      },
      dist_author       => 'Daisuke Murase <typester@cpan.org>',
    )->create_build_script;
