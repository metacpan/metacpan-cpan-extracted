#!/usr/bin/perl 
# FILE: bind9-build.pl
# USAGE: ./bind9-build.pl  
# ABSTRACT: example script for Container::Buildah which builds the current version of BIND9 for Alpine
# DESCRIPTION:
#    ISC BIND9 container - custom APK build of current BIND9 so we don't have to depend on when Alpine releases
#    an APK of the current version. This is a 2-stage build which makes the BIND9 APKs in the first stage, and
#    uses the results of that in the runtime stage without keeping the compiler & build tools from the first stage.
#    Note: this depend on updating the script to have the current BIND9 version number and sha512sum
# AUTHOR: Ian Kluft
# LICENSE: Apache License version 2

use strict;
use warnings;
use Modern::Perl qw(2018); # require security updates
use utf8;
use autodie;

use Readonly;
use Container::Buildah;

#
# configuration
#

# directory for build stage to make its APKs, not saved for other stages
Readonly::Scalar my $apkbuild_dir => "/opt/bind9-apkbuild";

# directory for build stage to save its APK product files, saved for runtime stage
Readonly::Scalar my $apk_dir => "/opt/bind9-apk";

# number of APKs which should be found (excluding unused dev, doc, openrc)
Readonly::Scalar my $apk_total => 7;

# container parameters
Container::Buildah::init_config(
	basename => "bind9",
	base_image => 'docker://docker.io/alpine:[% alpine_version %]',
	required_config => [qw(alpine_version bind_version bind_src_sha512sum)],
	stages => {
		build => {
			from => "[% base_image %]",
			func_deps => \&do_deps,
			func_exec => \&stage_build,
			produces => [$apk_dir],
			user => "named:named",
			user_home => $apkbuild_dir,
		},
		runtime => {
			from => "[% base_image %]",
			consumes => [qw(build)],
			func_deps => \&do_deps,
			func_exec => \&stage_runtime,
			user => "named:named",
			user_home => "/home/bind9",
			commit => ["[% basename %]:[% bind_version %]", "[% basename %]:latest"],
		}
	},
	bind_src_file => "bind-[% bind_version %].tar.xz",
	bind_apk_src => "https://git.alpinelinux.org/aports/plain/main/bind/?h=master",
);

# dependency installation function for both stages
sub do_deps
{
	my $stage = shift;

	$stage->run(
		# install updates for APKs at this Alpine OS release level
		[qw(/sbin/apk --no-cache update)],

		# install shadow as a dependency for user/user_home configuration
		# TODO add auto-dependency for configs based on Linux distro type (Alpine, Debian, Ubuntu, Fedora, CentOS/RHEL)
		[qw(/sbin/apk add --no-cache shadow)],
	);
}

# container-namespace code for build stage
sub stage_build
{
	my $stage = shift;

	# container environment
	my $arch = qx(uname --machine);
	chomp $arch;

	$stage->run(
		# install dependencies
		[qw(/sbin/apk add --no-cache build-base alpine-sdk wget perl)],

		# create build and product directories
		["mkdir", $apkbuild_dir, $apk_dir],
	);
	$stage->config({workingdir => $apkbuild_dir});
	$stage->run(
		# copy BIND9 APK build files from Alpine Git repo
		[qw(wget --quiet --recursive --level=1 --no-parent --https-only --cut-dirs=4 --no-host-directories
			--execute=robots=off), Container::Buildah->get_config("bind_apk_src")],

		# patch APK build instructions for updated version of BIND9
		[qw(perl -pi -e),
			's/^pkgver=.*/pkgver='.Container::Buildah->get_config("bind_version").'/;'
			.'/bind\.so_bsdcompat\.patch/ and $_="";'
			.'/isc-config\.sh/ and $_="";'
			.'s/[0-9a-f]{128}\s+bind-.*\.tar\.[gx]z$/'.Container::Buildah->get_config("bind_src_sha512sum")
				.'  '.Container::Buildah->get_config("bind_src_file").'/;'
			.'s/(^\s*depends=")/$1libuv-static /;',
			"APKBUILD"],

		# set up APK build environment
		[qw(/usr/sbin/usermod --append --groups abuild named)],
		["/bin/sh", "-c", "chown -R named:named ".$apkbuild_dir." ".$apk_dir],

		# build BIND9 APK
		[qw(su --login -- named /usr/bin/abuild-keygen -a)],
		[qw(su --login -- named /usr/bin/abuild verify)],
		[qw(/usr/bin/abuild -F deps)],
		[qw(su --login -- named /usr/bin/abuild)],

		# save built BIND9 APKs
		["/bin/sh", "-c", "cp -p packages/opt/$arch/* .abuild/named-*.pub ".$apk_dir],
	);
}

# container-namespace code for runtime stage
sub stage_runtime
{
	my $stage = shift;
	my $home = $stage->get_user_home;

	# make list of APKs from build stage to install
	opendir (my $apk_dh, $stage->get_mnt.'/'.$apk_dir)
		or die "runtime: failed to open APK directory";
	my @apks;
	while (readdir $apk_dh) {
		if (/\.apk$/ and not /^bind-(dev|doc|openrc)-/) {
			push @apks, $apk_dir."/".$_;
		}
	}
	closedir $apk_dh;
	if (scalar @apks != $apk_total) {
		die "found ".(scalar @apks)." APKs, expected ".$apk_total;
	}

	$stage->run(
		# update APKs
		[qw(/sbin/apk add wget)],

		# move APK public key(s) to /etc/apk/keys where APK can use it/them
		["/bin/sh", "-c", "mv ".$apk_dir."/*.pub /etc/apk/keys"],

		# install BIND9 APKs from the build stage
		[qw(/sbin/apk add), @apks],

		# set up BIND9 configuration
		[qw(mkdir -m 0750 -p /etc/bind)],
		[qw(chown -R root:named /etc/bind)],
		[qw(mkdir -m 0770 -p /var/cache/bind)],
		[qw(chown -R named:named /var/cache/bind)],
		[qw(wget -q -O /etc/bind/bind.keys https://ftp.isc.org/isc/bind9/keys/9.11/bind.keys.v9_11)],
		[qw(rndc-confgen -a)],

		# clean up
		[qw(/sbin/apk del shadow wget)],
		[qw(/bin/sh -c), "rm -rf /var/cache/apk/*"],
	);

	# copy configuration files to container
	$stage->copy({dest => "/etc/bind/"}, "content/configs" );
	$stage->copy({dest => "/"}, "content/entrypoint.sh" );

	# container environment
	$stage->config({
		env => ["BIND_LOG=-g"],
		volume => [qw(/etc/bind /var/cache/bind)],
		port => ["53", "53/udp"],
		entrypoint => "/entrypoint.sh",
	});
}

#
# main
#
Container::Buildah::main();
