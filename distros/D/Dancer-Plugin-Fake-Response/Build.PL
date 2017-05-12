use Module::Build;

my $build = Module::Build->new (
        module_name => 'Dancer::Plugin::Fake::Response',
        license => 'perl',
        dist_author => 'Nicolas Oudard',
        dist_version_from => 'lib/Dancer/Plugin/Fake/Response.pm',
        dist_abstract => 'Dancer Plugin Fake Response',
        requires => {
            'Test::More'           => 0,
            'Dancer'               => 1.3020,
            'Dancer::Plugin::REST' => 0.04,
        },
        build_requires => {
            'Test::More' => 0,
        },
        test_files => join( ' ', (glob( 't/*.t'), glob('t/*/*.t'))),
        add_to_cleanup => [ '_build', 'Build', 'Dancer-Plugin-Fake-Response-*' ],
    );
$build->create_build_script;
