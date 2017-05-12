# Build.PL for Date::Holidays::Super

# $Id: Build.PL,v 1.15 2006/12/07 09:23:35 jbn Exp $

use strict;
use Module::Build;

my $build = Module::Build->new(
	dist_author       => 'Jonas B. Nielsen, <jonasbn@cpan.org>',
	dist_name         => 'Date-Holidays-Super',
	dist_version_from => 'lib/Date/Holidays/Super.pm',
    distribution_type => 'module',
	license           => 'perl',
    recursive_test_files => 1,
	requires => {
		'Test::Harness'  => 0, #core
		'Test::More'     => 0, #core
	},
    no_index => {
        directory => [ 't' ],
    },
	create_makefile_pl => 'traditional',
);
$build->create_build_script();

1;