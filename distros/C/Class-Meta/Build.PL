use Module::Build;

my $build = Module::Build->new(
    module_name        => 'Class::Meta',
    license            => 'perl',
    create_makefile_pl => 'traditional',
    configure_requires => { 'Module::Build' => '0.2701' },
    recommends         => { 'Test::Pod'     => '1.41'   },
    build_requires     => {
        'Test::More'    => '0.17',
        'Module::Build' => '0.2701',
    },
    requires           => {
        'Data::Types' => '0.05',
        'Class::ISA'  => '0.31',
    },
    meta_merge => {
        resources => {
            homepage   => 'http://search.cpan.org/dist/Class-Meta/',
            bugtracker => 'http://github.com/theory/class-meta/issues/',
            repository => 'http://github.com/theory/class-meta/',
        }
    },
);
$build->create_build_script;
