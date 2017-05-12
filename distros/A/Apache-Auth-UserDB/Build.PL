#
# Module::Build build script for Apache::Auth::UserDB
#
# (C) 2004-2007 Julian Mehnle <julian@mehnle.net>
# $Id: Build.PL 31 2007-09-18 01:39:14Z julian $
#
##############################################################################

use Module::Build;
use version;

my $build = Module::Build->new(
    module_name     => 'Apache::Auth::UserDB',
    dist_author     => 'Julian Mehnle <julian@mehnle.net>',
    license         => 'perl',
    build_requires  => {
        # Build requirements:
        Module::Build       => 0,
        Test::More          => 0
    },
    requires        => {
        # General requirements:
        perl                => 'v5.6',
        version             => 0,
        Digest::MD5         => 0
    },
    create_makefile_pl
                    => 'passthrough',
    sign            => 1
);

$build->create_build_script();
