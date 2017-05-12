use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Array::Splice',
    license             => 'perl',
    dist_author         => 'Brian McCauley <nobull@cpan.org>',
    dist_version_from   => 'lib/Array/Splice.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Array-Splice-*' ],
);

$builder->create_build_script();
