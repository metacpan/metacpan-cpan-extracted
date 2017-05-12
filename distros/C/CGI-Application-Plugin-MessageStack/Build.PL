use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CGI::Application::Plugin::MessageStack',
    license             => 'perl',
    dist_author         => 'Jason Purdy <Jason@Purdy.INFO>',
    dist_version_from   => 'lib/CGI/Application/Plugin/MessageStack.pm',
    requires => {
        'Test::More'                            => 0,
        'CGI::Application'                      => 4.01,
    },
    recommends => {
        'CGI::Application::Plugin::Session'     => 0,
	'CGI::Application::Plugin::TT'		=> 0.09,
    },
    create_readme       => 1,
    create_makefile_pl	=> 'traditional',
    add_to_cleanup      => [ 'CGI-Application-Plugin-MessageStack-*', 't/cgisess_*' ],
);

$builder->create_build_script();
