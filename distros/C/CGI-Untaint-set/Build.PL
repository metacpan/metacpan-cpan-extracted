use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CGI::Untaint::set',
    license             => 'perl',
    dist_author         => 'David Baird <cpan@riverside-cms.co.uk>',
    dist_version_from   => 'lib/CGI/Untaint/set.pm',
    requires => {
        'Test::More' => 0,
        'Test::CGI::Untaint' => 0,
        'CGI::Untaint' => 0,
    },
    add_to_cleanup      => [ 'CGI-Untaint-set-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
