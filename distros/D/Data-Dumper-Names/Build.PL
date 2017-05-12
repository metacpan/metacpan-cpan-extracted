use strict;
use warnings;
use Module::Build;
use 5.006_001;

my $builder = Module::Build->new(
    module_name        => 'Data::Dumper::Names',
    license            => 'perl',
    dist_author        => 'Curtis <ovid@cpan.org>',
    dist_version_from  => 'lib/Data/Dumper/Names.pm',
    add_to_cleanup     => ['Data-Dumper-Names-*'],
    create_makefile_pl => 'traditional',
    requires           => {
        'PadWalker'    => 0.13,
        'Scalar::Util' => 0,
        'Test::More'   => 0,
    },
);

$builder->create_build_script();
