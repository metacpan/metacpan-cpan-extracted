use Module::Build;

my $build = Module::Build->new(
    module_name => 'Date::Holidays::CA',
    license     => 'perl',
    dist_author => 'Rick Scott <rick@cpan.org>',
    dist_version => '0.03',

    requires => {
        'perl'                    => '5.6.0',
        'Carp'                    => 0,
        'DateTime'                => 0,
        'DateTime::Event::Easter' => 0,
    },

    build_requires => {
        'Test::Exception'         => 0,
        'Test::More'              => 0,
    },
);

$build->create_build_script;
