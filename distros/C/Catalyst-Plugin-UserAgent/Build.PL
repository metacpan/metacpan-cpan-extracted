use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new( 
    module_name        => 'Catalyst::Plugin::UserAgent',
    create_readme      => 1,
    license            => 'perl',
    create_makefile_pl => 'passthrough',
    requires           => {
        'Catalyst'                 => 0,
        'Class::Data::Inheritable' => 0,
        'LWP::UserAgent'           => 0,
        'Test::MockObject'         => 0,
    },
)->create_build_script;
