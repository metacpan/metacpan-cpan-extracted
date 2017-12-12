#!/usr/bin/env perl

use Test2::V0;
use Test::Alien;
use Alien::ZMQ::latest;

plan tests => 1;

subtest "ZeroMQ version" => sub {
	alien_ok 'Alien::ZMQ::latest';

	if( $^O eq 'darwin' ) {
		my @install_name_tool_commands = ();
		my @libs = qw(
			libzmq.5.dylib
		);

		for my $lib (@libs) {
			my $prop = Alien::ZMQ::latest->runtime_prop;
			my $rpath_install = $prop->{prefix} . "/lib"; # '%{.runtime.prefix}'
			my $rpath_blib = $prop->{distdir} . "/lib"; # '%{.install.stage}';
			my $blib_lib = "$rpath_blib/$lib";

			push @install_name_tool_commands,
				"install_name_tool -add_rpath $rpath_install -add_rpath $rpath_blib $blib_lib";
			push @install_name_tool_commands,
				"install_name_tool -id \@rpath/$lib $blib_lib";
			for my $other_lib (@libs) {
				push @install_name_tool_commands,
					"install_name_tool -change $rpath_install/$other_lib \@rpath/$other_lib $blib_lib"
			}
		}
		for my $command (@install_name_tool_commands) {
			system($command);
		}
	}

	my $xs = do { local $/; <DATA> };
	xs_ok {
		xs => $xs,
		cbuilder_link => {
			extra_linker_flags =>
				# add -dylib_file since during test, the dylib is under blib/
				$^O eq 'darwin'
					? ' -rpath ' . Alien::ZMQ::latest->runtime_prop->{distdir} . "/lib"
					: ' '
		},
	}, with_subtest {
		my($module) = @_;
		is $module->version, Alien::ZMQ::latest->version,
			"Got zmq version @{[ Alien::ZMQ::latest->version ]}";
	};
};

done_testing;
__DATA__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "zmq.h"

char *
version(const char *class)
{
	/* 256 should be long enough */
	char* version_string = malloc(256);

	int major, minor, patch;
	zmq_version(&major, &minor, &patch);

	sprintf(version_string, "%d.%d.%d", major, minor, patch);

	return version_string;
}

MODULE = TA_MODULE PACKAGE = TA_MODULE

const char *version(class);
	const char *class;
