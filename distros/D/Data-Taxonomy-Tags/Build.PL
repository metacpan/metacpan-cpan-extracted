use Module::Build;

Module::Build->new(
    module_name         => 'Data::Taxonomy::Tags',
    dist_version        => '0.05',
    dist_author         => 'Thomas Sibley, http://zulutango.org:82/',
    dist_abstract       => 'Easy management of a set of tags for any item',
    license             => 'perl',

    # I don't know the earliest module versions that will
    # work... sorry
    requires            => {
        'overload'          => 0,
        'constant'          => 0,
    },    
    build_requires => {
        'Test::More'        => 0,
    },
    create_makefile_pl  => 'traditional',
)->create_build_script;
