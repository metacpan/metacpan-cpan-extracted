use Module::Build;

my $build = Module::Build->new (
        module_name => 'DBIx::Class::Result::ProxyField',
        license => 'perl',
        dist_author => 'Nicolas Oudard',
        dist_version_from => 'lib/DBIx/Class/Result/ProxyField.pm',
        dist_abstract => 'DBIx Class Result ProxyField',
        requires => {
            'DBIx::Class'=> 0.08127,
            'DBIx::Class::Result::ColumnData'=> 0.07,
            'SQL::Translator' => 0.11007,
            'DateTime' => 0.65,
            'DateTime::Format::SQLite' => 0.11,
            'Test::More' => 0,
        },
        build_requires => {
            'Test::More' => 0,
        },
        test_files => join( ' ', (glob( 't/*.t'), glob('t/*/*.t'))),
        add_to_cleanup => [ '_build', 'Build', 'DBIx-Class-Result-ProxyField-*' ],
    );
$build->create_build_script;
