use Module::Build;
my $build = Module::Build->new(
    module_name   => 'DateTimeX::Immutable',
    license       => 'perl',
    create_readme => 1,

    configure_requires => {
        'Module::Build' => '0.4004',
    },

    requires => {
        'perl'                     => '5.006',
        'DateTime'                 => '1.00',
        'Role::Tiny'               => '1.000',
        'Class::Method::Modifiers' => '2.00',
        'Carp'                     => '1.0000',
        'Sub::Install'             => '0.900',
        'namespace::autoclean'     => '0.21',
    },

    test_requires => {
        'Test::More'      => '0.87',
        'Test::Exception' => '0.35',
        'Test::MockTime'  => '0.15',
    },

    meta_merge => {
        resources => {
            bugtracker =>
              'https://github.com/mvgrimes/perl-datetimex-immutable/issues',
            repository => 'https://github.com/mvgrimes/perl-datetimex-immutable'
        }
    },
);

$build->create_build_script;
