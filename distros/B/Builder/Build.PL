use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Builder',
    license             => 'perl',
    dist_author         => 'Barry Walsh <draegtun@cpan.org>',
    dist_version_from   => 'lib/Builder.pm',
    
    build_requires => {
        'Test::More' => 0,
        'Carp'       => 0,
    },
    
    add_to_cleanup      => [ 'Builder-*' ],
    
    meta_merge => {
        resources => {
            repository => 'http://github.com/draegtun/builder',
        },
    },
);

$builder->create_build_script();
