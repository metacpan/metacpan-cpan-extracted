use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Class::Trait',
    license           => 'perl',
    dist_author       => 'Curtis "Ovid" Poe <ovid@cpan.org>',
    dist_version_from => 'lib/Class/Trait.pm',
    requires          => {
        'Test::Differences'     => 0.47,
        'Test::Simple'          => 0.62,
        'File::Spec'            => 0,
        'Class::Accessor::Fast' => 0,
    },
    add_to_cleanup     => ['Class-Trait-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
