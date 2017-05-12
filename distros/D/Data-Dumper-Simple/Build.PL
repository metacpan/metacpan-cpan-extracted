use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Data::Dumper::Simple',
    license           => 'perl',
    dist_author       => 'Curtis "Ovid" Poe <ovid@cpan.org>',
    dist_version_from => 'lib/Data/Dumper/Simple.pm',
    requires          => {
        'Test::More'     => 0,
        'Filter::Simple' => '0.77',
    },
    add_to_cleanup     => ['Data-Dumper-Simple-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();

