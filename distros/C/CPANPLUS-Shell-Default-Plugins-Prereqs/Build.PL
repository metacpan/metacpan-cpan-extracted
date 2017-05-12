use Module::Build;
my $build = Module::Build->new(
    module_name   => 'CPANPLUS::Shell::Default::Plugins::Prereqs',
    license       => 'perl',
    create_readme => 1,
    requires      => {
        'CPANPLUS'   => '0.77',
        'File::Spec' => 0,
    },
    build_requires => {
        'Test::More'            => 0,
        'Module::Build'         => '0.36',
        'CPANPLUS::Dist::Build' => 0,
        'IO::CaptureOutput'     => '1.1102',
    },
);

$build->create_build_script;

