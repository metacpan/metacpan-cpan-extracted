use strict;
use lib '.';
use inc::Module::Install;

name                'Conf-Libconfig';
license             'bsd';
author              'Cnangel <cnangel@gmail.com>';
repository			'http://github.com/cnangel/Conf-Libconfig';
all_from            'lib/Conf/Libconfig.pm';
requires            'XSLoader' => 0.05;
configure_requires  'ExtUtils::PkgConfig';

test_requires       'Test::Deep' => 0.10;
test_requires       'Test::More' => 0.60;
test_requires       'Test::Warn' => 0.10;
test_requires       'Test::Exception' => 0.25;
test_requires       'ExtUtils::PkgConfig' => 0;

#build_subdirs		'libconfig';

eval("use ExtUtils::PkgConfig;");
my @inc_paths;
my @lib_paths;
eval {
	@inc_paths = map { s/-I//; $_ } split(' ', ExtUtils::PkgConfig->cflags_only_I('libconfig'));
	@lib_paths = map { s/-L//; $_ } split(' ', ExtUtils::PkgConfig->libs_only_L('libconfig'));
};
cc_inc_paths        @inc_paths;
cc_lib_paths        @lib_paths;
cc_lib_links        'config';
checklibs           lib => [qw(config)], 
					libpath => \@lib_paths,
					header => [qw(libconfig.h)],
					incpath => \@inc_paths; 
can_cc              or die 'This module requires C compiler.';
no_index            directory => qw(t inc);
auto_install();
WriteAll();
