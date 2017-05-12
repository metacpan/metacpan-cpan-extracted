use Module::Build;

my $build = Module::Build->new(
    module_name        => 'Class::Meta::Express',
    license            => 'perl',
    create_makefile_pl => 'traditional',
    configure_requires => { 'Module::Build' => '0.2701' },
    recommends         => { 'Test::Pod'     => '1.41'   },
    requires           => { 'Class::Meta'   => '0.60'   },
    build_requires     => {
        'Test::More'    => '0.17',
        'Module::Build' => '0.2701',
    },
    meta-express_merge => {
        resources => {
            homepage   => 'http://search.cpan.org/dist/Class-Meta-Express/',
            bugtracker => 'http://github.com/theory/class-meta-express/issues/',
            repository => 'http://github.com/theory/class-meta-express/',
        }
    },
);
$build->create_build_script;
