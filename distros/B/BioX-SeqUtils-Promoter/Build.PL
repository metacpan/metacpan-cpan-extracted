use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'BioX::SeqUtils::Promoter',
    license             => 'perl',
    dist_author         => 'Charles Stephen Embry <cstephene@cpan.org>',
    dist_version_from   => 'lib/BioX/SeqUtils/Promoter.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'BioX-SeqUtils-Promoter-*' ],
);

$builder->create_build_script();
