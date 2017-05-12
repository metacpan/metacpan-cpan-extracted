use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Bio::GenBankParser',
    license             => 'perl',
    dist_author         => 'Ken Youens-Clark <kclark@cpan.org>',
    dist_version_from   => 'lib/Bio/GenBankParser.pm',
    build_requires => {
        'Test::More'    => 0,
    },
    add_to_cleanup      => [ 'Bio-GenBankParser-*' ],
    create_makefile_pl  => 'traditional',
    requires            => {
        'Parse::RecDescent' => 1.965001,
        'Readonly'          => 0,
    },
    recommends          => {
        'YAML'          => 0,
    }
);

$builder->create_build_script();
