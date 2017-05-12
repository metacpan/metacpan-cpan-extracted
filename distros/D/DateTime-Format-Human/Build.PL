use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new(
    module_name         => 'DateTime::Format::Human',
    dist_version_from   => 'lib/DateTime/Format/Human.pm',
    author              => 'Joshua Hoblitt <jhoblitt@cpan.org>',
    license             => 'perl',
    requires            => {
        'DateTime'          => '0.22',
        'Params::Validate'  => '0.74',
    },
)->create_build_script;
