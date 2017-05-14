use strict;
use warnings;
use Module::Build;
require 5.006001;

my $build = Module::Build->new(
    create_readme       => 1,
    create_makefile_pl  => 'traditional',
    license             => 'perl',
    module_name         => 'Acme::Curse',
    dist_author         => 'Moritz Lenz',
    dist_abstract       => 'Remove the blessing that lay on references',
    dist_version        => '0.0.1',
    requires => {
        'perl'              => '5.6.1',
# I don't really know which Coro version is needed, but 1.0 seems like a
# reasonable guess. Might change in future.
        'Scalar::Util'      => 0,
    },
    recommends          => {},
    sign                => 0,
);
$build->create_build_script;

# vim: sw=4 ts=4 expandtab
