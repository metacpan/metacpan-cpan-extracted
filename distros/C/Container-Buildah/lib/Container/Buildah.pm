# Container::Buildah
# ABSTRACT: wrapper around containers/buildah tool for multi-stage builds of OCI/Docker-compatible Linux containers
# by Ian Kluft

## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
use Modern::Perl qw(2015); # require 5.20.0
## use critic (Modules::RequireExplicitPackage)

package Container::Buildah;
$Container::Buildah::VERSION = '0.2.1';
use autodie;
use Carp qw(croak confess);
use Exporter;
use Readonly;
use Getopt::Long;
use Data::Dumper;
use IO::Handle;
use File::Slurp;
use File::Sync qw(sync);
use Algorithm::Dependency;
use Algorithm::Dependency::Source::HoA;
use YAML::XS;
use Template;
use parent qw(Class::Singleton);

# import from Container::Buildah::Subcommand after BEGIN phase (where 'use' takes place), to avoid conflicts
require Container::Buildah::Subcommand;
Container::Buildah::Subcommand->import(qw(process_params prog));

# methods delegated to Container::Buildah::Subcommand that need to be imported into this class' symbol table
# (methods should not be handled by Exporter - we are doing the same thing but keeping it private to the class)
Readonly::Array my @subcommand_methods => qw(cmd buildah bud containers from images info inspect
	mount pull push_image rename rm rmi tag umount unshare version);

# aliases to de-conflict wrapper methods that have same name as Perl builtins
Readonly::Hash my %subcommand_aliases => (push => "push_image", rename => "rename_image");

#
# initialize environment
#

# globals
my $debug=0;
my %template_config = (
	INTERPOLATE  => 1,
	POST_CHOMP   => 1,
	RECURSION    => 1,
	EVAL_PERL    => 0,
	PRE_CHOMP    => 2,
	POST_CHOMP   => 2,
);
my %init_config;

# initialization on the singleton instance
# see parent Class::Singleton
# private class method - required by parent Class::Singleton
## no critic (Subroutines::ProhibitUnusedPrivateSubroutines, Miscellanea::ProhibitUnrestrictedNoCritic))
sub _new_instance
{
	my ($class, %params) = @_;
	my $self  = bless { }, $class;

	# debugging isn't established yet so just be verbose about startup parameters if debug is specified
	if (exists $params{debug})
	{
		print STDERR "debug: _new_instance: params=".Dumper(\%params);
	}

	# set up config hash - use yaml_config file if provided, then add all entries from config parameter
	# note: YAML is the preferred location to keep configuration that changes frequently such as software versions
	if (not exists $self->{config}) {
		$self->{config} = {};
		$self->{config}{_config_files} = [];
	}
	if (exists $params{yaml_config}) {
		my $in_config = YAML::XS::LoadFile($params{yaml_config});
		push @{$self->{config}{_config_files}}, $params{yaml_config}; # save a record of config files used
		if (ref $in_config eq "HASH") {
			$self->{config} = $in_config;
		} elsif (ref $in_config eq "ARRAY" and ref $in_config->[0] eq "HASH") {
			$self->{config} = $in_config->[0];
		} else {
			confess __PACKAGE__.": can't find associative array for configuration data";
		}
	}
	foreach my $key (keys %init_config) {
		$self->{config}{$key} = $init_config{$key};
	}

	# process container basename for this instance
	if (exists $self->{config}{basename}) {
		# timestamp string for log file names
		# set environment for child processes, or use it if established by parent
		my $timestamp_envname = uc($self->{config}{basename}."_TIMESTAMP_STR");
		if (exists $ENV{$timestamp_envname}) {
			$self->{config}{timestamp_str} = $ENV{$timestamp_envname};
		} else {
			my @timestamp = localtime;
			$timestamp[4]++; # fix month from 0-base
			$timestamp[5] += 1900; # fix year from 1900 base
			$self->{config}{timestamp_str} = sprintf "%04d-%02d-%02d-%02d-%02d-%02d",
				$timestamp[5], $timestamp[4], $timestamp[3],
				$timestamp[2], $timestamp[1],$timestamp[0];
			## no critic (Variables::RequireLocalizedPunctuationVars, Miscellanea::ProhibitUnrestrictedNoCritic)
			$ENV{$timestamp_envname} = $self->{config}{timestamp_str};
		}
	} else {
		croak __PACKAGE__.": required basename initialization parameter not found";
	}

	# delegate subcommand wrapper functions to Container::Buildah::Subcommand
	require Container::Buildah::Subcommand;
	foreach my $methodname (@subcommand_methods) {
		no strict 'refs'; ## no critic (ProhibitNoStrict)
		*{$methodname} = \&{"Container::Buildah::Subcommand::$methodname"};
	}

	# handle subcommand wrapper aliases to avoid functions with names of Perl builtins
	foreach my $aliasname (keys %subcommand_aliases) {
		no strict 'refs'; ## no critic (ProhibitNoStrict)
		*{$aliasname} = \&{"Container::Buildah::Subcommand::".$subcommand_aliases{$aliasname}};
	}

	# Template setup
	$self->{template} = Template->new(\%template_config);

	# redirect STDIN from /dev/null so subprocesses run automated and can't prompt STDIN
	open STDIN, "<", "/dev/null"
		or croak "failed to redirect STDIN";

	# save STDOUT and STDERR so they can be restored after redirects
	open($self->{oldstdout}, '>&STDOUT')
		or croak "Can't dup STDOUT: $!";
	open($self->{oldstderr}, '>&STDERR')
		or croak "Can't dup STDERR: $!";

	return $self;
}
## use critic (Subroutines::ProhibitUnusedPrivateSubroutines, Miscellanea::ProhibitUnrestrictedNoCritic))

#
# configuration/utility functions
#

# initialize configuration
# public class function
sub init_config
{
	%init_config = @_;
	return;
}

# print status messages
# public class function
sub status
{
	# get Container::Buildah ref from method-call parameter or class singleton instance
	my @in_args = @_;
	my $cb = ((ref $in_args[0]) and (ref $in_args[0] eq "Container::Buildah")) ? shift @in_args
		: Container::Buildah->instance();

	# print status message
	if ($debug > 0) {
		say STDOUT "=== status: ".join(" ", @in_args);
		if ((exists $cb->{oldstdout}) and ($cb->{oldstdout}->fileno != fileno(STDERR))) {
			$cb->{oldstdout}->print("=== status: ".join(" ", @in_args)."\n");
		}
	}
	return;
}

# print debug messages
# public class function
sub debug
{
	my ($cb, @in_args) = @_;
	if (ref $cb ne __PACKAGE__) {
		confess "debug must be called as a class method";
	}

	# collect debug parameters
	my %params;
	if (ref $in_args[0] eq "HASH") {
		my $params_ref = shift @in_args;
		%params = %$params_ref;
	}

	# print debugging statement if enabled
	my $level = $params{level} // 1;
	if ($debug >= $level) {
		my $wrapper = $params{wrapper} // 0; # skip stack frame if called from debug wrapper function

		# debug label: get caller name (default to function name from Perl call stack) and any label string
		my @label;
		if (exists $params{name} and defined $params{name}) {
			push @label, $params{name};
		} else {
			my $caller = (caller(1+$wrapper))[3];
			if ($caller eq "(eval)") {
				push @label, (caller(2+$wrapper))[3], "eval";
			} else {
				push @label, $caller;
			}
		}
		if (exists $params{label} and defined $params{label}) {
			push @label, $params{label};
		}

		# print debug message
		my $msg = "--- debug [".(join "/", @label)."]: ".join(" ", map {(defined $_) ? $_ : "(undef)"} @in_args);
		say STDERR $msg;
		if ((exists $cb->{oldstderr}) and ($cb->{oldstderr}->fileno != fileno(STDERR))) {
			$cb->{oldstderr}->print($msg."\n");
		}
	}
	return;
}

# template and variable expansion
# private class function
sub expand
{
	my $value = shift;
	my $cb = Container::Buildah->instance();

	# process array values sequentially
	if (ref $value eq "ARRAY") {
		my @result;
		foreach my $subvalue (@$value) {
			push @result, expand($subvalue);
		}
		$cb->debug({level => 4}, "expand: $value -> [".join(" ", @result)."]");
		return \@result;
	}

	# process scalar value
	my $output;
	$cb->{template}->process(\$value, $cb->{config}, \$output);
	$cb->debug({level => 4}, "expand: $value -> $output");

	# expand templates as long as any remain, up to 10 iterations
	my $count=0;
	while ($output =~ / \[% .* %\] /x and $count++ < 10) {
		$value = $output;
		$output = ""; # clear because template concatenates to it
		$cb->{template}->process(\$value, $cb->{config}, \$output);
		$cb->debug({level => 4}, "expand ($count): $value -> $output");
	}
	return $output;
}

# get configuration value
# public class method
sub get_config
{
	my ($class_or_obj, @path) = @_;
	my $cb = (ref $class_or_obj) ? $class_or_obj : $class_or_obj->instance();

	# special case for empty path: return config tree root
	if (not @path) {
		$cb->debug({level => 3}, "get_config: retrieved root node");
		return $cb->{config};
	}

	# navigate down config tree
	my $key = pop @path; # last entry of path is target node
	my $orig_path = join("/", @path)."->".$key; # for error reporting
	my $node = $cb->{config};
	while (@path) {
		my $subnode = shift @path;
		if (exists $node->{$subnode} and ref $node->{$subnode} eq "HASH") {
			$node = $node->{$subnode};
		} else {
			confess "get_config: ($subnode) not found in search for $orig_path";
		}
	}

	# return configuration
	if (exists $node->{$key}) {
		if (ref $node->{$key} and ref $node->{$key} ne "ARRAY") {
			$cb->debug({level => 3}, "get_config: $key -> $node->{$key}");
			return $node->{$key};
		}

		# if the value is scalar or array, perform variable expansion
		my $result = expand($node->{$key});
		if (ref $node->{$key} eq "ARRAY") {
			$cb->debug({level => 3}, "get_config: $key -> [".join(" ", @{$node->{$key}})."]");
		} else {
			$cb->debug({level => 3}, "get_config: $key -> $result");
		}
		return $result;
	}
	$cb->debug({level => 3}, "get_config: not found ($orig_path)");
	return;
}

# allow caller to enforce its required configuration
# public class method
sub required_config
{
	my ($class_or_obj, @in_args) = @_;
	my $cb = (ref $class_or_obj) ? $class_or_obj : $class_or_obj->instance();

	# check for missing config parameters required by program
	my @missing;
	foreach my $key (@in_args) {
		if (not exists $cb->{config}{$key}) {
			push @missing, $key;
		}
	}

	# fail if any required parameters are missing
	if (@missing) {
		croak __PACKAGE__.": required configuration parameters missing: ".join(" ", @missing);
	}
}

# get debug mode value
# public class function
sub get_debug
{
	return $debug;
}

# set debug mode/level
# public class function
sub set_debug
{
	$debug = int shift; # save integer debug level
	return;
}

# get OCI-recognized CPU architecture string for this system
# includes tweak to add v7 to armv7
# private class method
sub get_arch
{
	my $cb = shift;
	my $arch = $cb->info({format => q({{.host.arch}})});
	if ($arch eq 'arm') {
		my $cpuinfo = File::Slurp::read_file('/proc/cpuinfo', err_mode => "croak");
		if (/ ^ CPU \s architecture \s* : \s* (.*) $ /x) {
			if ($1 eq "7") {
				$arch='armv7';
			}
		}
	}
	$cb->debug({level => 1}, "get_arch => $arch");
	return $arch;
}

# check array to verify all entries are defined, otherwise throw an exception
# private class function
sub disallow_undef
{
	my $array_ref = shift;
	my $got_type = ref $array_ref;
	if ($got_type ne "ARRAY") {
		confess "disallow_undef: improper usage - requires ARRAY ref, got ".($got_type ? $got_type : "undef");
	}
	for (my $i=0; $i < scalar @$array_ref; $i++) {
		if (not defined $array_ref->[$i]) {
			confess "disallow_undef: found undefined value in parameter list item $i: ".join(" ", map {(defined $_) ? $_ : "(undef)"} @$array_ref);
		}
	}
	return;
}

#
# exception handling
#

# handle exceptions from eval blocks
# private class function
sub exception_handler
{
	no autodie;
	my $xc = shift;
	if ($xc) {
		if (ref $xc eq "autodie::exception") {
			say STDERR "exception(".$xc->function."): ".$xc->eval_error." at ".$xc->file." line ".$xc->line;
		} elsif (ref $xc) {
			say STDERR "exception(".(ref $xc)."): ".$xc
		} else {
			say STDERR "exception: ".$xc;
		}
		my $cb = Container::Buildah->instance();
		open(STDOUT, '>&', $cb->{oldstdout});
		open(STDERR, '>&', $cb->{oldstderr});

		# report status if possible and exit
		my $basename = $cb->{config}{basename} // "unnamed container";
		croak $basename." failed";
	}
}

#
# build stage management functions
#

# compute container build order from dependencies
# private class method
sub build_order_deps
{
	my $cb = shift;
	my %deps; # dependencies in a hash of arrays, to be fed to Algorithm::Dependency::Source::HoA
	my $stages = $cb->get_config("stages");
	if (ref $stages ne "HASH") {
		croak "stages confguration must be a hash, got ".((ref $stages) ? ref $stages : "scalar");
	}

	# collect dependency data from each stage's configuration
	my @stages = keys %$stages;
	foreach my $stage (@stages) {
		my @stage_deps;

		# use consumes or depends parameters in each stage for dependency data
		# if consumes parameter exists, it declares stages which provide a tarball to this stage
		# if depends parameter exists, it declares stages which have any other dependency
		foreach my $param (qw(consumes depends)) {
			if (exists $stages->{$stage}{$param}) {
				if (ref $stages->{$stage}{$param} ne "ARRAY") {
					croak "stage $stage '$param' entry must be an array, got "
						.((ref $stages->{$stage}{$param}) ? ref $stages->{$stage}{$param} : "scalar");
				}
				push @stage_deps, @{$stages->{$stage}{$param}};
			}
		}

		# save the dependency list, even if empty
		$deps{$stage} = \@stage_deps;
	}

	# compute build order from dependencies using Algorithm::Dependency, using hash-of-arrays input format
	my $Source = Algorithm::Dependency::Source::HoA->new( \%deps );
	my $algdep = Algorithm::Dependency->new(source => $Source);
	my $order = $algdep->schedule_all;
	$cb->debug({level => 1}, "build order (computed): ".join(" ", @$order));
	$cb->{order} = {};
	for (my $i=0; $i < scalar @$order; $i++) {
		$cb->{order}{$order->[$i]} = $i;
	}
	$cb->debug({level => 1}, "build order (data): ".join(" ", map {$_."=>".$cb->{order}{$_}} keys %{$cb->{order}}));
	return;
}

# run a container-build stage
# private class method
sub stage
{
	my ($cb, $name, %opt) = @_;

	# get flag: are we internal to the user namespace for container setup
	my $is_internal = $opt{internal} // 0;

	# instantiate the Container::Buildah::Stage object for this stage's container
	require Container::Buildah::Stage;
	my $stage = Container::Buildah::Stage->new(name => $name);

	# create timestamped log directory if it doesn't exist
	my $logdir_top = "log-".Container::Buildah->get_config("basename");
	my $logdir_time = "$logdir_top/".Container::Buildah->get_config("timestamp_str");
	foreach my $dir ($logdir_top, $logdir_time) {
		if (not  -d $dir) {
			mkdir $dir, 02770;
		}
	}
	if (-l "$logdir_top/current") {
		unlink "$logdir_top/current";
	}
	symlink Container::Buildah->get_config("timestamp_str"), $logdir_top."/current";

	# redirect STDOUT and STDERR to log file pipe for container stage
	## no critic (InputOutput::RequireBriefOpen, Miscellanea::ProhibitUnrestrictedNoCritic)
	my $stagelog;
	open($stagelog, '>>', $logdir_time."/".$name.($is_internal ? "-internal" : ""));
	$stagelog->autoflush(1);
	open(STDOUT, '>&', $stagelog);
	open(STDERR, '>&', $stagelog);

	# generate container and run this stage's function in it
	$stage->status("begin (".($is_internal ? "internal" : "external").")");
	eval {
		if ($is_internal) {
			#
			# run the internal stage function since we're within the mounted container namespace
			#

			# retrieve the internal stage functions
			my $func_deps = $stage->get_func_deps;
			my $func_exec = $stage->get_func_exec;

			# enforce required func_exec configuration (func_deps is optional)
			if (not defined $func_exec) {
				croak "stage $name internal: func_exec not configured";
			}
			if (ref $func_exec ne "CODE") {
				confess "stage $name internal: func_exec is not a code reference - got "
					.(ref $func_exec);
			}

			# run deps & exec functions for the stage, process consumed or produced tarballs
			if ((defined $func_deps) and (ref $func_deps eq "CODE")) {
				$stage->status("func_deps");
				$func_deps->($stage);
			} else {
				$stage->status("func_deps - skipped, not configured");
			}
			$stage->status("consume");
			$stage->consume; # import tarball(s) from other stage(s), if configured
			$stage->status("func_exec");
			$func_exec->($stage);
			$stage->status("produce");
			$stage->produce; # export tarball for another stage to use, if configured
		} else {
			# run the external stage wrapper which will mount the container namespace and call the internal stage in it
			$stage->status("launch_namespace");
			$stage->launch_namespace;
		}
		1;
	} or exception_handler $@;
	$stage->status("end (".($is_internal ? "internal" : "external").")");

	# close output pipe
	close $stagelog;
	open(STDOUT, '>&', $cb->{oldstdout});
	open(STDERR, '>&', $cb->{oldstderr});
	return;
}

#
# process mainline
#

# process each defined stage of the container production pipeline
# public class function
sub main
{
	# save a copy of the command line for re-launching the script in a container namespace
	my @argv_copy = @ARGV;

	# process command line
	my %cmd_opts;
	my @added_opts = (exists $init_config{added_opts} and ref $init_config{added_opts} eq "ARRAY")
		? @{$init_config{added_opts}} : ();
	GetOptions(\%cmd_opts, "debug:i", "config:s", "internal:s", @added_opts);
	if (exists $cmd_opts{debug}) {
		set_debug($cmd_opts{debug});
	}

	# instantiate Container::Buildah object
	my @do_yaml;
	if (not exists $init_config{testing_skip_yaml}) {
		my $yaml_config = $cmd_opts{config};
		if (not defined $yaml_config) {
			foreach my $suffix (qw(yml yaml)) {
				if (-f $init_config{basename}.".".$suffix) {
					$yaml_config = $init_config{basename}.".".$suffix;
					last;
				}
			}
			if (not defined $yaml_config) {
				croak "YAML configuration required to set software versions";
			}
		}
		@do_yaml = (yaml_config => $yaml_config);
	}
	my $cb = Container::Buildah->instance(@do_yaml);

	# process config
	$cb->{config}{argv} = \@argv_copy;
	$cb->{config}{opts} = \%cmd_opts;
	$cb->{config}{arch} = $cb->get_arch();
	if (exists $init_config{required_config}
		and ref $init_config{required_config} eq "ARRAY")
	{
		$cb->required_config(@{$init_config{required_config}});
	}

	if (exists $cmd_opts{internal}) {
		# run an internal stage inside a container user namespace if --internal=stage was specified
		$cb->stage($cmd_opts{internal}, internal => 1);
	} else {
		# compute container build order from dependencies
		$cb->build_order_deps;

		# external (outside the user namespaces) loop to run each stage
		foreach my $stage (sort {$cb->{order}{$a} <=> $cb->{order}{$b}}
			keys %{$cb->{config}{stages}})
		{
			$cb->stage($stage);
		}

		# if we get here, we're done
		$cb->status(Container::Buildah->get_config("basename")." complete");
	}
	return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Container::Buildah - wrapper around containers/buildah tool for multi-stage builds of OCI/Docker-compatible Linux containers

=head1 VERSION

version 0.2.1

=head1 SYNOPSIS

    use <Container::Buildah>;

	# configure container build stages
	Container::Buildah::init_config(
		basename => "swpkg",
		base_image => 'docker://docker.io/alpine:[% alpine_version %]',
		stages => {
			build => {
				from => "[% base_image %]",
				func_exec => \&stage_build,
				produces => [qw(/opt/swpkg-apk)],
			},
			runtime => {
				from => "[% base_image %]",
				consumes => [qw(build)],
				func_exec => \&stage_runtime,
				commit => ["[% basename %]:[% swpkg_version %]", "[% basename %]:latest"],
			}
		},
		swpkg_version => "9.16.4",
	);

	# functions to run each stage inside their container namespaces
	sub stage_build {
		my $stage = shift;
		# code to run inside the namespace of the build container
		# set up build container and copy newly-built Alpine APK packages into /opt/swpkg-apk ...
		# See Container::Buildah:Stage for the object passed to each stage function
	}
	sub stage_runtime {
		my $stage = shift;
		# code to run inside the namespace of the runtime container
		# set up runtime container including installing Alpine APK packages from /opt/swpkg-apk ...
		# See Container::Buildah:Stage for the object passed to each stage function
	}

	# Container::Buildah::main serves as script mainline including processing command-line arguments
	Container::Buildah::main(); # run all the container stages

=head1 DESCRIPTION

B<Container::Buildah> allows Perl scripts to build OCI/Docker-compatible container images using the Open Source
I<buildah> command. Containers may be pipelined so the product of a build stage is consumed by one or more others.

The B<Container::Buildah> module grew out of a wrapper script to run code inside the user namespace of a
container under construction. That remains the core of its purpose. It simplifies rootless builds of containers.

B<Container::Buildah> may be used to write a script to configure container build stages.
The configuration of each build stage contains a reference to a callback function which will run inside the
user namespace of the container in order to build it.
The function is analagous to a Dockerfile, except that it's programmable with access to computation and the system.

The I<buildah> command has subcommands equivalent to Dockerfile directives.
For each stage of a container build, B<Container::Buildah> creates a B<Container::Buildah::Stage> object
and passes it to the callback function for that stage.
There are wrapper methods in B<Container::Buildah::Stage> for
subcommands of buildah which take a container name as a parameter.

The B<Container::Buildah> module has one singleton instance per program.
It contains configuration data for a container build process.
The data is similar to what would be in a Dockerfile, except this module makes it scriptable.

=head1 METHODS

=head2 debug

Prints a list of strings to STDERR, if debugging is at the specified level.
If the first argument is a HASH reference, it is used for key/value parameters.
The recognized parameters are
=over
=item "name" for the name of the caller function, defaults to the name from the Perl call stack
=item "level" for the minimum debugging level to print the message
=item "label" for an additional label string to enclose in brackets, such as a container name
=back

=head2 get_config

=head2 required_config

=head2 get_debug

Return integer value of debug level

=head2 set_debug

Take an integer value parameter to set the debug level. A level of 0 means debugging is turned off. The default is 0.

=head2 prog

=head2 buildah

=head2 tag

=head2 main

=head1 FUNCTIONS

=head2 init_config

=head2 status

prints a list of strings to STDOUT

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/Container-Buildah/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/Container-Buildah/pulls>

=head1 AUTHOR

Ian Kluft <https://github.com/ikluft>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Ian Kluft.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
