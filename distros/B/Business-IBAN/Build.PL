use Module::Build;
my $build = Module::Build->new(
    create_makefile_pl => 'traditional',
    module_name        => 'Business::IBAN',
    license            => 'perl',
    requires => {
        'Math::BigInt' => 0,
    },
    recommends         => {

        #'perl'           => '5.6.1',
        'Locale::Country' => '2.03',
    },
    create_readme => 0,
    sign          => 0,
);
$build->create_build_script;

