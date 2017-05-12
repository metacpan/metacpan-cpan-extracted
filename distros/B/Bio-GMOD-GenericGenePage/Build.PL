use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new
    ( module_name     => 'Bio::GMOD::GenericGenePage',
      license         => 'perl',
      dist_version_from => 'lib/Bio/GMOD/GenericGenePage.pm',
      dist_abstract   => 'An abstract implementation of a Generic Gene Page XML, with 2 exmples',
      dist_author     => 'Scott Cain and Robert Buels',
    )->create_build_script;
