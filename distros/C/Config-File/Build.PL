use Module::Build;
my $build = Module::Build->new(
    module_name => 'Config::File',
    dist_abstract => 'Parse a simple configuration file',
    dist_author => 'Gunnar Wolf <gwolf@gwolf.org>',
    license => 'gpl',
    requires => {},
    recommends => {},
    build_requires => {Test::Pod => 0,
		       Test::Pod::Coverage => 0,
		       Module::Build => 0},

    create_makefile_pl => 'passthrough'
    );
$build->create_build_script;
