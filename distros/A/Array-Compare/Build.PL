use Module::Build;
my $build = Module::Build->new(
    module_name => 'Array::Compare',
    license => 'perl',
    requires => {
        perl            => '5.6.0',
        Carp            => 0,
        Moo             => 0,
        Types::Standard => 0,
    },
    build_requires => {
        Test::NoWarnings => 0,
    },
    build_recommends => {
        Test::Pod           => 0,
        Test::Pod::Coverage => 0,
    },
    meta_merge => {
        'meta-spec' => { version => 2 },
        resources  => {
            repository => {
                type => 'git',
                url  => 'https://github.com/davorg/array-compare.git',
                web  => 'https://github.com/davorg/array-compare',
            },
        },
    },
    create_makefile_pl => 'traditional',
);

$build->create_build_script;
