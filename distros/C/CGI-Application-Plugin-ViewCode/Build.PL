use strict;
use warnings;
use Module::Build;
use lib './t/lib';

my $builder = Module::Build->new(
    module_name         => 'CGI::Application::Plugin::ViewCode',
    license             => 'perl',
    dist_author         => 'Michael Peters <mpeters@plusthree.com>',
    dist_version_from   => 'lib/CGI/Application/Plugin/ViewCode.pm',
    requires => {
        'Test::More'                        => 0,
        'CGI::Application'                  => 4.00,
        'Syntax::Highlight::Perl::Improved' => 1.0,
        'Pod::Xhtml'                        => 1.0,
        'Test::LongString'                  => 0,
    },
    create_makefile_pl  => 'small',
    create_readme       => 1,
);

$builder->create_build_script();
