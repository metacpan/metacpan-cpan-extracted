use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CGI::Application::Plugin::HTDot',
    license             => 'perl',
    dist_author         => 'Jason A. Crome <cromedome@cpan.org>',
    dist_abstract       => 'Enable "magic dot" notation in CGI::Application-derived applications that use HTML::Template for their templating mechanism.',
    dist_version_from   => 'lib/CGI/Application/Plugin/HTDot.pm',
    requires => {
        'Test::More'                  => 0,
        'Test::Exception'             => 0,
        'CGI::Application'            => '4.0',
        'Module::Build'               => 0,
        'HTML::Template::Plugin::Dot' => 0,
    },
    create_makefile_pl  => 'traditional',
    create_readme       => 1,
    add_to_cleanup      => [ 'CGI-Application-Plugin-HTDot-*' ],
);

$builder->create_build_script();
