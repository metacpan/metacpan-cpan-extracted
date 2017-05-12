use Module::Build;

my $build = Module::Build->new(
    module_name        => 'Apache::FakeTable',
    license            => 'perl',
    create_makefile_pl => 'traditional',
    configure_requires => { 'Module::Build' => '0.2701' },
    build_requires     => {
        'Module::Build' => '0.2701',
        'Test::More'    => '0.17',
    },
    recommends         => { 'Test::Pod'     => '1.41'   },
    meta_merge => {
        resources => {
            homepage   => 'http://search.cpan.org/dist/Apache-FakeTable/',
            bugtracker => 'http://github.com/theory/apache-faketable/issues/',
            repository => 'http://github.com/theory/apache-faketable/',
        }
    },
);
$build->create_build_script;
