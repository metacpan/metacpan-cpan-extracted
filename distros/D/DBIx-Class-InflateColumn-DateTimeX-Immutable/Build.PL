use Module::Build;
my $build = Module::Build->new(
    module_name   => 'DBIx::Class::InflateColumn::DateTimeX::Immutable',
    license       => 'perl',
    create_readme => 1,

    configure_requires => {
        'Module::Build' => '0.4004',
    },

    requires => {
        'perl'                 => '5.006',
        'DateTimeX::Immutable' => '0.30',
        'DBIx::Class'          => '0.000',
        'Try::Tiny'            => '0.000',
        'namespace::autoclean' => '0.21',
    },

    test_requires => {
        'Test::More'      => '0.87',
        'DBD::SQLite'     => '0',
        'SQL::Translator' => '0.11018',    # Needed to ->deploy()
        'DateTime::Format::SQLite' => '0', # Needed to test on some machines
    },

    meta_merge => {
        resources => {
            bugtracker =>
              'https://github.com/mvgrimes/perl-dbic-inflate-datetimex-immutible/issues',
            repository =>
              'https://github.com/mvgrimes/perl-dbic-inflate-datetimex-immutible'
        }
    },
);

$build->create_build_script;
