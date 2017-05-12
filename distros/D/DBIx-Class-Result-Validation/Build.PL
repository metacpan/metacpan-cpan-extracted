use Module::Build;

my $build = Module::Build->new(
    module_name       => 'DBIx::Class::Result::Validation',
    license           => 'perl',
    dist_author       => 'Nicolas Oudard',
    dist_version_from => 'lib/DBIx/Class/Result/Validation.pm',
    dist_abstract     => 'DBIx Class Result Validation',
    requires          => {
        'DBIx::Class'              => 0.08127,
        'SQL::Translator'          => 0.11007,
        'Class::Accessor::Grouped' => 0.09008,
        'Test::More'               => 0,
        'Carp'                     => 0,
        'Try::Tiny'                => 0,
        'Moose'                    => 0,
    },
    build_requires => { 'Test::More' => 0, },
    test_files => join( ' ', ( glob('t/*.t'), glob('t/*/*.t') ) ),
    add_to_cleanup => [ '_build', 'Build', 'DBIx-Class-Result-Validation-*' ],
    meta_merge     => {
        resources => {
            repository =>
              'https://github.com/kolok/DBIx-Class-Result-Validation'
        }
    },
);
$build->create_build_script;
