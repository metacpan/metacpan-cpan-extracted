# -*- indent-tabs-mode: nil -*-

use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CPAN::Mini::Inject::Remote',
    license             => 'perl',
    dist_author         => q{Christopher Mckay <potatohead@potatolan.com>},
    dist_version_from   => 'lib/CPAN/Mini/Inject/Remote.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Getopt::Long' => 0,
        'Pod::Usage' => 0,
        'Params::Validate' => 0,
        'File::Spec' => 0,
        'YAML::Any' => 0,
        'LWP::UserAgent' => 0,
        'HTTP::Request' => 0,
        'HTTP::Request::Common' => 0,
        'Archive::Tar' => 0,
        'CPAN::Meta' => 0,
    },
    add_to_cleanup      => [ 'CPAN-Mini-Inject-Remote-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
