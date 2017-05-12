use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Apache::Auth::Subrequest',
    license             => 'perl',
    dist_author         => 'Scott Penrose <scottp@dd.com.au>',
    dist_version_from   => 'lib/Apache/Auth/Subrequest.pm',
    create_makefile_pl  => 'small',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Apache-Auth-Subrequest-*' ],
);

$builder->create_build_script();
