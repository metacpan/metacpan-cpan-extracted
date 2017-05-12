#use 5.10.1;    # don't demand a version until we see how far back it works
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Acme::Teddy',
    license             => 'artistic_2',
    dist_author         => 'Xiong Changnian <xiong@cpan.org>',
    dist_version_from   => 'lib/Acme/Teddy.pm',
    requires => {
    },
    add_to_cleanup      => [ 'Acme-Teddy-*' ],
    meta_merge              => {
        resources               => {
            repository              => 'http://github.com/Xiong/acme-teddy',
        },
        keywords            => [ qw(
            test        testing 
            dummy       target        
        ) ],
    },
);

$builder->create_build_script();
