use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Apache::AuthenMSAD',
    license             => 'perl',
    dist_author         => 'Andrew McGregor <andy@txm.mobi>',
    dist_version_from   => 'lib/Apache/AuthenMSAD.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Apache-AuthenMSAD-*' ],
);

$builder->create_build_script();
