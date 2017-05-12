use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'AI::FuzzyEngine',
    license             => 'perl',
    dist_author         => q{Juergen Mueck <jmueck@cpan.org>},
    dist_version_from   => 'lib/AI/FuzzyEngine.pm',
    build_requires => {
        'Test::More'      => 0,
        'Test::Most'      => 0,
        'List::Util'      => 0,
        'List::MoreUtils' => 0,
        'Scalar::Util'    => 0,
        'Carp'            => 0,
    },
    requires => {
        'perl' => 5.008009,
    },
    add_to_cleanup      => [ 'AI-FuzzyEngine-*' ],
    create_makefile_pl => 'traditional',
);
#  <img src="Changes" alt="Changes, 119B" class="" title="Changes" height="0" width="0" />
#  <img src="MANIFEST" alt="MANIFEST, 194B" class="" title="MANIFEST" height="0" width="0" />
#  <img src="README" alt="README, 1.6kB" class="" title="README" height="0" width="0" />
                                             
$builder->create_build_script();
