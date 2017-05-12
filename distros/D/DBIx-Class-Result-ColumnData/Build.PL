use Module::Build;

my $build = Module::Build->new (
        module_name => 'DBIx::Class::Result::ColumnData',
        license => 'perl',
        dist_author => 'Nicolas Oudard',
        dist_version_from => 'lib/DBIx/Class/Result/ColumnData.pm',
        dist_abstract => 'DBIx Class Result ColumnData',
        requires => {
            'DBIx::Class'=> 0.08127,
            'SQL::Translator' => 0.11007,
            'DateTime' => 0.65,
            'Carp' => 1.17,
            'DBIx::Class::IntrospectableM2M' => 0.001001,
            'DBIx::Class::Result::Validation' => 0.05,
            'DateTime::Format::SQLite' => 0.11,
            'Test::More' => 0,
        },
        build_requires => {
            'Test::More' => 0,
        },
        test_files => join( ' ', (glob( 't/*.t'), glob('t/*/*.t'))),
        add_to_cleanup => [ '_build', 'Build', 'DBIx-Class-Result-ColumnData-*' ],
    );
$build->create_build_script;
