use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CGI::Application::Plugin::Config::General',
    license             => 'perl',
    dist_author         => 'Michael Graham <mgraham@cpan.org>',
    dist_version_from   => 'lib/CGI/Application/Plugin/Config/General.pm',
    requires => {
        'Test::More'             => 0,
        'CGI::Application'       => 0,
        'Config::General::Match' => 0,
        'Scalar::Util'           => 0,
    },
    meta_add            => {
         no_index       => {
             directory => [ qw/
                 misc
                 t
             /]
         }
    },
    add_to_cleanup      => [ 'CGI-Application-Plugin-Config-General-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
