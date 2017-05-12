use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Acme::CPAN::Patches',
    license           => 'perl',
    dist_author       => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from => 'lib/Acme/CPAN/Patches.pm',
    
    build_requires => {
    },
    requires => {
    },
    script_files => [
    ],
    add_to_cleanup => [ 'Acme-CPAN-Patches-*' ],
);

$builder->create_build_script();
