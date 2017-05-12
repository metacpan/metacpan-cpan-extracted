#!perl
# $Id: Build.PL 3 2005-01-05 06:07:38Z daisuke $
#
# Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

use strict;
use Module::Build;

my $build = Module::Build->new(
    dist_author   => 'Daisuke Maki <dmaki@cpan.org>',
    dist_name     => 'Class-Validating',
    module_name   => 'Class::Validating',
    license       => 'perl',
    build_requires => {
        'Test::More'         => 0,
    },
    requires      => {
        'Params::Validate'         => 0,
        'Class::Data::Inheritable' => 0,
    },
    sign          => 1,
    create_makefile_pl => 'traditional'
);
$build->create_build_script;