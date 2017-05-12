use Module::Build;

my $build = Module::Build->new (
        module_name => 'DBIx::Class::Result::ExternalAttribute',
        license => 'perl',
        dist_author => 'Nicolas Oudard',
        dist_version_from => 'lib/DBIx/Class/Result/ExternalAttribute.pm',
        dist_abstract => 'DBIx Class Result ExternalAttribute',
        requires => {
            'Carp' => 1.17,
            'Test::More' => 0,
            'DBIx::Class::Result::ColumnData' => 0.09,
            'SQL::Translator' => 0.11007,
        },
        build_requires => {
            'Test::More' => 0,
        },
        test_files => join( ' ', (glob( 't/*.t'), glob('t/*/*.t'))),
        add_to_cleanup => [ '_build', 'Build', 'DBIx-Class-Result-ExternalAttribute-*' ],
    );
$build->create_build_script;
