use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'BackPAN::Version::Discover',
    license             => 'perl',
    dist_author         => q{Stephen R. Scaffidi <sscaffidi@cpan.org>},
    dist_version_from   => 'lib/BackPAN/Version/Discover.pm',
    requires            => {
        'BackPAN::Index'           => 0.39,
        'Path::Class'              => 0,
        'File::Spec::Functions'    => 0,
        'File::Find::Rule'         => 0,
        'Module::Info'             => 0,
        'List::MoreUtils'          => 0,
        'ExtUtils::Installed'      => 0,
        'Module::Extract::VERSION' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'BackPAN-Version-Discover-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
