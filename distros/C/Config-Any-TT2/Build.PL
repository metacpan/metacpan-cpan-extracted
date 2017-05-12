use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Config::Any::TT2',
    license           => 'perl',
    dist_author       => q{Karl Gaissmaier <gaissmai@cpan.org>},
    dist_version_from => 'lib/Config/Any/TT2.pm',
    create_readme     => 1,
    build_requires    => { 'Test::More' => 0, },
    requires          => {
        'Config::Any' => 0,
        'Config::TT2' => 0,
    },
    meta_merge => {
        resources =>
          { repository => 'git://github.com/gaissmai/Config-Any-TT2.git', }
    },
    add_to_cleanup     => ['Config-Any-TT2-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
