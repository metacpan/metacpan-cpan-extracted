use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'App::Grepl',
    license           => 'perl',
    dist_author       => 'Curtis Poe <ovid@cpan.org>',
    dist_version_from => 'lib/App/Grepl.pm',
    requires          => {
        'Scalar::Util' => 1.19,
        'File::Next'   => 0.40,
        'PPI'          => 1.118,
    },
    build_requires     => { 'Test::More' => 0, },
    exe_files          => ['bin/grepl'],
    add_to_cleanup     => ['App-Grepl-*'],
#    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
