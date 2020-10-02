#!/usr/bin/perl
# 100_hello.t - test Container::Buildah building and running a binary in a container
use strict;
use warnings;
use autodie;

use Test::More;
use Test::RequiresInternet ('docker.io' => 443);
use POSIX qw(uname);
use Carp qw(croak);
use File::Basename;
use Cwd;
use Readonly;
use IPC::Run;
use YAML::XS;
use File::Path qw(remove_tree);

# detect debug level from environment
# run as "DEBUG=4 perl -Ilib t/011_prog.t" to get debug output to STDERR
my $debug_level = (exists $ENV{DEBUG}) ? int $ENV{DEBUG} : 0;

# input directory and YAML config file
Readonly::Scalar my $input_dir => getcwd()."/t/test-inputs/".basename($0, ".t");
Readonly::Scalar my $yaml_config => "hello.yaml";
Readonly::Scalar my $build_script => "hello_build.pl";
Readonly::Scalar my $log_top => getcwd()."/"."log-hello";
Readonly::Scalar my $log_dir => "$log_top/current";
Readonly::Scalar my $yaml_save => "$log_dir/saved-config.yaml";

#
# main
#

# check if kernel is container-compatible
# currently only Linux 2.8 kernels and above support containers
# adjust as necessary if others (i.e. BSD variants) add container compatibility in the future
my $kernel_compat = 0; # assume false
{
	my ($sysname, $nodename, $release, $version, $machine) = POSIX::uname();
	my ($kmajor, $kminor) = ($release =~ /^([0-9]+)\.([0-9]+)\./x);
	if ($sysname eq "Linux") {
		if ($kmajor >= 3) {
			$kernel_compat = 1;
		} elsif ($kmajor == 2 and $kminor >= 8) {
			$kernel_compat = 1;
		}
	}
}

# check for buildah and podman
if ($kernel_compat) {
	my (%paths, @missing);
	for my $target (qw(buildah podman tar)) {
		for my $path (qw(/usr/bin /sbin /usr/sbin /bin)) {
			if (-x "$path/$target") {
				$paths{$target} = "$path/$target";
				last;
			}
		}
		if (!exists $paths{$target}) {
			push @missing, $target;
		}
	}
	if (@missing) {
		plan skip_all => "missing required program: ".join(" ", @missing);
	} else {
		plan tests => 25;
	}
} else {
	plan skip_all => 'kernel is not container-compatible';
}

# check for test configuration
if (! -d $input_dir) {
	BAIL_OUT("can't find test inputs directory: expected $input_dir");
}
if ( not -e $input_dir."/".$build_script) {
	BAIL_OUT("can't find container build script $input_dir/$build_script");
}

# remove inter-stage tarball because we don't want to run the hello built with an old test's timestamp
my $tarball = 'hello_build.tar.bz2';
if (-e $tarball) {
	unlink $tarball or BAIL_OUT("can't delete tarball $tarball from previous test run");
}

# run Container::Buildah script
my @sent_args = ("--config=$input_dir/$yaml_config", "--inputs=$input_dir",
	"--save=$yaml_save", "--add-history", ($debug_level > 0 ? "--debug=$debug_level" : ()));
my @cmd = ( "$input_dir/$build_script", @sent_args);
if ($debug_level > 0) {
	say STDERR "input_dir: $input_dir";
	say STDERR "log_dir: $log_dir";
	say STDERR "cmd: ".join(" ", @cmd);
}
system @cmd;
if ($? == -1) {
	BAIL_OUT("failed to execute build script: $!");
}
elsif ($? & 127) {
	BAIL_OUT(sprintf "build script died with signal %d, %s coredump\n", ($? & 127),  ($? & 128) ? 'with' : 'without');
}
my $result = $? >> 8;

# check that the build ran to completion
is($result, 0, "Container::Buildah::main() completed");

# run tests which inspect configuation from saved YAML
my $yaml = YAML::XS::LoadFile($yaml_save);
is($yaml->{basename}, "hello", "YAML: basename");
ok(exists($yaml->{alpine_version}), "YAML: alpine_version");
is_deeply($yaml->{argv}, \@sent_args, "YAML: compare sent and saved argument lists");

# verify the correct name and tag container was created
my $image_name = "localhost/hello:".$yaml->{timestamp_str};
my $image_exists = 0;
{
	my ($inspect_outstr, $inspect_errstr);
	my @cmd = ("podman", "inspect", $image_name);
	IPC::Run::run(\@cmd, '<', \undef, '>', \$inspect_outstr, '2>', \$inspect_errstr);
	my $retcode = $? >> 8;
	chomp $inspect_outstr;
	chomp $inspect_errstr;
	isnt($?, -1, "image: podman inspect executed");
	$image_exists = $retcode == 0;
	ok($image_exists, "image: expected image exists");

	# check contents of image
	my $inspect = YAML::XS::Load($inspect_outstr);
	is_deeply($inspect->[0]{Config}{Entrypoint}, [qw(/bin/sh -c /opt/hello-bin/hello)], "check entrypoint");
	is_deeply($inspect->[0]{Config}{Cmd}, [qw(/bin/sh)], "check cmd");
	like($inspect->[0]{History}[0]{created_by}, qr/ADD/, "check history 0");
	like($inspect->[0]{History}[1]{created_by}, qr/CMD/, "check history 1");
	like($inspect->[0]{History}[2]{created_by}, qr/ADD/, "check history 2");
	like($inspect->[0]{History}[3]{created_by}, qr/ENV/, "check history 3");
	like($inspect->[0]{History}[4]{created_by}, qr/ENTRYPOINT/, "check history 4");
}

# run the container - verify correct output and empty error
SKIP: {
	skip "can't run or remove container with image that doesn't exist", 6 if not $image_exists;

	# run the container
	my ($run_outstr, $run_errstr);
	my @cmd = ("podman", "run", $image_name);
	IPC::Run::run(\@cmd, '<', \undef, '>', \$run_outstr, '2>', \$run_errstr);
	my $retcode = $? >> 8;
	chomp $run_outstr;
	chomp $run_errstr;
	isnt($?, -1, "container run: executed");
	is($retcode, 0, "container run: succeeded");
	is($run_outstr, "Hello world! Version: ".$yaml->{timestamp_str}, "container run: output contents");
	is($run_errstr, '', 'container run: no errors');

	SKIP: {
		skip "cleanup disabled from environment", 2 if (exists $ENV{TEST_NO_CLEANUP} and $ENV{TEST_NO_CLEANUP});

		# remove the container to clean up our mess
		my ($rmi_outstr, $rmi_errstr);
		@cmd = ("podman", "rmi", "--force", $image_name);
		IPC::Run::run(\@cmd, '<', \undef, '>', \$rmi_outstr, '2>', \$rmi_errstr);
		$retcode = $? >> 8;
		chomp $rmi_outstr;
		chomp $rmi_errstr;
		isnt($?, -1, "image cleanup: executed");
		is($retcode, 0, "image cleanup: succeeded");
	}
}

# inspect interstage tarball contents
{
	my ($tar_outstr, $tar_errstr);
	my @cmd = ("tar", "-tf", $tarball);
	IPC::Run::run(\@cmd, '<', \undef, '>', \$tar_outstr, '2>', \$tar_errstr);
	my $retcode = $? >> 8;
	chomp $tar_outstr;
	chomp $tar_errstr;
	isnt($?, -1, "tarball: tar executed");
	is($retcode, 0, "tarball: tar succeeded");

	# check contents of tar output
	my @tar_list = split(/[\r\n]+/, $tar_outstr);
	is(scalar @tar_list, 2, "tarball: number of entries");
	is($tar_list[0], 'opt/hello-bin/', 'tarball: bin directory');
	is($tar_list[1], 'opt/hello-bin/hello', 'tarball: hello binary');
	is($tar_errstr, '', 'tarball: no errors');
}

# clean up test artifacts
if (not exists $ENV{TEST_NO_CLEANUP} or not $ENV{TEST_NO_CLEANUP}) {
	unlink $tarball;
	remove_tree($log_top, {safe => 1});
}

1;
