use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Class::Meta::Declare',
    license           => 'perl',
    dist_author       => 'Curtis "Ovid" Poe <ovid@cpan.org>',
    dist_version_from => 'lib/Class/Meta/Declare.pm',
    requires          => {
        'Class::BuildMethods' => 0.10,
        'Class::Meta'         => 0.49,
        'Exporter::Tidy'      => 0.06,
        'Readonly'            => 1.03,
        'Test::More'          => 0,
    },
    add_to_cleanup     => ['Class-Meta-Declare-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
