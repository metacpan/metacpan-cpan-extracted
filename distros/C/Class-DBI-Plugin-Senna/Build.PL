#!perl
# $Id: Build.PL 2 2005-06-20 03:01:23Z daisuke $
#
# Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

use strict;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Class::DBI::Plugin::Senna',
    requires => {
        'Class::DBI' => 0,
        'Senna'      => '>= 0.05',
    },
    license => 'perl',
    create_makefile_pl => 'traditional'
);
$build->create_build_script;
