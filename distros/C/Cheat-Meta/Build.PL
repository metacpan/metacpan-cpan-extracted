use 5.008008;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Cheat::Meta',
    license             => 'artistic_2',
    dist_author         => 'Xiong Changnian <xiong@cpan.org>',
    dist_version_from   => 'lib/Cheat/Meta.pm',
    requires            => {
        'perl'                      => 5.008008,
        'version'                   => 0.77,
    },
    build_requires      => {
        'Test::More'                => 0.94,
    },
    add_to_cleanup      => [
        'Cheat-*', 
        'Bundle-Cheat-*', 
    ],
    meta_merge              => {
        resources               => {
            repository              => 'http://github.com/Xiong/cheat-meta',
        },
        keywords            => [ qw(
            help    usage
            docs    documentation
            cheat   sheet   cheatsheet
            summary
        ) ],
    },
);

$builder->add_build_element('perl');

$builder->create_build_script();
