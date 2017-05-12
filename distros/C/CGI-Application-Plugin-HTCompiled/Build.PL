use 5.008001;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CGI::Application::Plugin::HTCompiled',
    license             => 'perl',
    dist_author         => 'Alexander Becker <asb@cpan.org>',
    dist_version_from   => 'lib/CGI/Application/Plugin/HTCompiled.pm',
	configure_requires => { 'Module::Build' => 0.36 },
    requires => {
		'perl'                  	  => '5.008001', # cf. HTML::Template::Compiled
		'ExtUtils::Install'			  => '1.52',
        'Test::More'                  => 0,
        'Test::Exception'             => 0,
        'CGI::Application'            => '4.31',
        'HTML::Template::Compiled'    => 0,
		'UNIVERSAL::isa'			  => 0,
    },
    create_makefile_pl  => 'traditional',
    create_readme       => 1,
    add_to_cleanup      => [ 'CGI-Application-Plugin-HTCompiled-*' ],
);

$builder->create_build_script();
