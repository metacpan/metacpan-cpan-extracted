#!/usr/bin/perl
# ABSTRACT: hello_build.pl - test Container::Buildah building and running a binary in a container
# by Ian Kluft

## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
use Modern::Perl qw(2015); # require 5.20.0
## use critic (Modules::RequireExplicitPackage)

use autodie;
use Carp qw(croak);
use Container::Buildah;
use Readonly;
use YAML::XS;

# set paths as constants
Readonly::Scalar my $build_dir => "/opt/hello-build"; # directory for build stage to make its binaries
Readonly::Scalar my $bin_dir => "/opt/hello-bin"; # directory for build stage to save its product files
Readonly::Scalar my $hello_src => "hello.c"; # C source
Readonly::Scalar my $hello_bin => "hello"; # YAML config file

# container parameters
Container::Buildah::init_config(
	basename => "hello",
	base_image => 'docker://docker.io/alpine:[% alpine_version %]',
	required_config => [qw(alpine_version)],
	stages => {
		build => {
			from => "[% base_image %]",
			func_exec => \&stage_build,
			produces => [$bin_dir],
		},
		runtime => {
			from => "[% base_image %]",
			consumes => [qw(build)],
			func_exec => \&stage_runtime,
            commit => ["[% basename %]:latest"],
		},
	},
);

# container-namespace code for build stage
sub stage_build
{
	my $stage = shift;
	$stage->debug({level => 1}, "start");
	my $cb = Container::Buildah->instance();

	$stage->run(
		# install dependencies
		[qw(/sbin/apk add --no-cache binutils gcc musl-dev)],

		# create build and product directories
		["mkdir", $build_dir, $bin_dir],
	);
	$stage->config({workingdir => $build_dir});
	$stage->copy({dest => $build_dir}, $hello_src);
	$stage->run(
		["gcc", "--std=c17", $hello_src, "-o", "$bin_dir/$hello_bin"],
	);
}

# container-namespace code for runtime stage
sub stage_runtime
{
	my $stage = shift;
	$stage->debug({level => 1}, "start");
	my $cb = Container::Buildah->instance();
	
	# container environment
	$stage->config({
		entrypoint => $bin_dir.'/'.$hello_bin,
	});

}

#
# main
#

# run Container::Buildah mainline
Container::Buildah::main();
