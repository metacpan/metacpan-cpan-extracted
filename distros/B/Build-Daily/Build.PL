use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Build-Daily',
    license             => 'perl',
    dist_author         => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from   => 'lib/Build/Daily.pm',
    requires => {
        'File::Spec'       => 0,
        'Module::Build'    => 0.2808,
        'ExtUtils::MakeMaker' => 0,
        'DateTime'         => 0,
    },
    build_requires => {
        'Test::More'      => 0,
    },
    script_files => [
    ],
    add_to_cleanup      => [ 'Build-Daily-*' ],
    create_readme       => 1,
    sign                => 1,
);

$builder->create_build_script();
