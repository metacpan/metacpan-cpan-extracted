use Module::Build;
my $build = Module::Build->new(
    module_name => 'Data::FormValidator::Constraints::DateTime',
    license     => 'perl',
    requires    => {
        'perl'                          => '5.6.1',
        'Data::FormValidator'           => '3.61',
        'DateTime'                      => '0.23',
        'DateTime::Format::Strptime'    => '1.00',
        'Exporter'                      => 0,
    },
    recommends  => {
        'DateTime::Format::MySQL'       => '0.0301',
        'DateTime::Format::Pg'          => '0.050',
    },
    build_requires  => {
        'DateTime::Format::Builder' => 0,
    },
    create_makefile_pl => 'traditional',
);
$build->create_build_script;
