use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Acme::KnowledgeWisdom',
    license             => 'perl',
    dist_author         => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from   => 'lib/Acme/KnowledgeWisdom.pm',
    requires => {
        'Moose' => 0,
    },
    build_requires => {
        'Test::More'        => 0,
        'Test::Exception'   => 0,
    },
    add_to_cleanup      => [ 'Acme-KnowledgeWisdom-*' ],
    create_readme       => 1,
    sign                => 1,
    meta_merge => {
        resources => {
            repository => 'git://github.com/jozef/Acme-KnowledgeWisdom.git',
            bugtracker => 'http://github.com/jozef/Acme-KnowledgeWisdom/issues',
        },
        keywords => [ qw/ knowledge wisdom / ],
    },
);
$builder->create_build_script();
