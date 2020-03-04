use Module::Build;
my $build = Module::Build->new(
    module_name   => 'CPANPLUS::Shell::Default::Plugins::Prereqs',
    license       => 'perl',
    create_readme => 1,
    requires      => {
        'perl'       => '5.006',
        'CPANPLUS'   => '0.77',
        'File::Spec' => 0,
    },
    configure_requires => {
        'Module::Build' => '0.36',
    },
    test_requires => {
        'Test::More'            => 0,
        'CPANPLUS::Dist::Build' => 0,
        'IO::CaptureOutput'     => '1.1102',
        'Perl6::Junction'       => 0,
    },
);

$build->create_build_script;

