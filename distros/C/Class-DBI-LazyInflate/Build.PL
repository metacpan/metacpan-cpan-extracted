#!perl
# $Id: Build.PL 3 2005-02-22 01:38:39Z daisuke $
#
# Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

use strict;
use Module::Build;

my $st = Module::Build->check_installed_status('DBD::SQLite');
my $HAVE_SQLITE = $st->{ok} || 0;
if ($HAVE_SQLITE) {
    print " + You have DBD::SQLite installed. Enabling SQLite tests.\n";
} else {
    print " + You don't have DBD::SQLite installed. Disabling SQLite tests.\n";
}

my $class = Module::Build->subclass(
    code => qq|
        sub ACTION_test {
            \$ENV{HAVE_SQLITE} = $HAVE_SQLITE;
            shift->SUPER::ACTION_test(\@_);
        }
    |
);
my $build = $class->new(
    module_name => 'Class::DBI::LazyInflate',
    requires => {
        'Class::DBI' => 0,
        'Data::Lazy' => 0
    },
    license => 'perl',
    create_makefile_pl => 'traditional',
    create_readme => 1,
);

$build->create_build_script;