use Module::Build;

=head1 NAME

Build.PL - Build script generator for Class::DBI::ViewLoader

=head1 SYNOPSIS

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

=cut

Module::Build->new(
	    module_name => "Class::DBI::ViewLoader",
	    requires => {
		'DBI' => "1.43",
		'Class::DBI' => 0,
		'Module::Pluggable' => 0,
                'version'    => 0,
	    },
            recommends => {
                'Test::Pod' => 0,
                'Test::Pod::Coverage' => 0,
            },
	    build_requires => {
		'Test::More' => 0,
                'DBD::Mock'  => '0.22',
	    },
	    license => 'perl',
	    create_readme => 1,
	    create_makefile_pl => 'passthrough',
	)->create_build_script;
