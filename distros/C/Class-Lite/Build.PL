use 5.008008;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Class::Lite',
    license             => 'artistic_2',
    dist_author         => 'Xiong Changnian <xiong@cpan.org>',
    dist_version_from   => 'lib/Class/Lite.pm',
    configure_requires  => { 
        'Module::Build'             => 0.38, 
    },
    requires            => {
        'perl'                      => 5.008008,
        'version'                   => 0.99,
#~         ''  => 0,
    },
    recommends          => {
        'Devel::Comments'           => '1.1.4',
    },
    build_requires      => {
        'Test::More'                => 0.94,
    },
    add_to_cleanup      => [ 'Class-Lite-*' ],
    meta_merge          => {
        resources           => {
            repository          => 'http://github.com/Xiong/class-lite',
        },
        keywords            => [ qw(
            devel       development 
            
            OO  object-oriented class object method
            base constructor accessor accessors
            
            lite lightweight tiny
        ) ],
    },
);

$builder->create_build_script();
exit(0);
