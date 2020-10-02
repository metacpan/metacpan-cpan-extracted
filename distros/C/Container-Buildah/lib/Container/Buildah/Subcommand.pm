# Container::Buildah::Subcommand
# ABSTRACT: wrapper class for Container::Buildah to run subcommands of buildah
# by Ian Kluft

## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
use Modern::Perl qw(2015); # require 5.20.0
## use critic (Modules::RequireExplicitPackage)

package Container::Buildah::Subcommand;
$Container::Buildah::Subcommand::VERSION = '0.3.1';
use autodie;
use Carp qw(croak confess);
use POSIX qw(uname);
use IPC::Run;
use Data::Dumper;
use YAML::XS;
require Container::Buildah;

# exports
use Exporter qw(import);
our @EXPORT_OK   = qw(process_params prog);

#
# parameter processing functions used by process_params()
#

# params_extract - set aside parameters which caller wants extracted for further processing that we can't generalize
# private class function
sub params_extract
{
	my ($defs, $params, $extract_ref) = @_;

	if (exists $defs->{extract}) {
		if (ref $defs->{extract} ne "ARRAY") {
			confess "process_params parameter 'extract' must be an array, got ".(ref $defs->{extract});
		}
		foreach my $argname (@{$defs->{extract}}) {
			if (exists $params->{$argname}) {
				$extract_ref->{$argname} = $params->{$argname};
				delete $params->{$argname};
			}
		}
	}
	return;
}

# param_arg_init - initialize argument list
# private class function
sub param_arg_init
{
	my ($defs, $arg_ref) = @_;

	if (exists $defs->{arg_init}) {
		if (not ref $defs->{arg_init}) {
			push @$arg_ref, $defs->{arg_init};
		} elsif (ref $defs->{arg_init} eq "ARRAY") {
			push @$arg_ref, @{$defs->{arg_init}};
		} else {
			confess "process_params parameter 'arg_init' must be scalar or array, got ".(ref $defs->{arg_init});
		}
	}
	return;
}

# param_exclusive - check for exclusive parameters - if any are present, it must be the only parameter
# private class function
sub param_exclusive
{
	my ($name, $defs, $params, $extract_ref) = @_;

	if (exists $defs->{exclusive}) {
		if (ref $defs->{exclusive} ne "ARRAY") {
			confess "process_params parameter 'exclusive' must be an array, got ".(ref $defs->{exclusive});
		}
		foreach my $argname (@{$defs->{exclusive}}) {
			if (exists $params->{$argname}) {
				# if other flags exist with an exclusive flag, that's an error
				if (scalar keys %$params > 1) {
					croak "$name parameter '".$argname."' is exclusive - cannot be passed with other parameters";
				}

				# exclusive flag saved in extracted fields so caller can detect it
				$extract_ref->{$argname} = $params->{$argname};
			}
		}
	}
	return;
}

# param_arg_flag - process arguments which are boolean flags, excluding those requiring true/false as a string
# private class function
sub param_arg_flag
{
	my ($name, $defs, $params, $arg_ref) = @_;

	if (exists $defs->{arg_flag}) {
		if (ref $defs->{arg_flag} ne "ARRAY") {
			confess "process_params parameter 'arg_flag' must be an array, got ".(ref $defs->{arg_flag});
		}
		foreach my $argname (@{$defs->{arg_flag}}) {
			if (exists $params->{$argname}) {
				if (ref $params->{$argname}) {
					confess "$name parameter '".$argname."' must be scalar, got ".(ref $params->{$argname});
				}
				push @$arg_ref, "--$argname";
				delete $params->{$argname};
			}
		}
	}
	return;
}

# param_arg_flag_str - process arguments which are boolean flags, requiring true/false as a string
# private class function
sub param_arg_flag_str
{
	my ($name, $defs, $params, $arg_ref) = @_;

	if (exists $defs->{arg_flag_str}) {
		if (ref $defs->{arg_flag_str} ne "ARRAY") {
			confess "process_params parameter 'arg_flag_str' must be an array, got ".(ref $defs->{arg_flag_str});
		}
		foreach my $argname (@{$defs->{arg_flag_str}}) {
			if (exists $params->{$argname}) {
				if (ref $params->{$argname}) {
					confess "$name parameter '".$argname."' must be scalar, got ".(ref $params->{$argname});
				}
				if ($params->{$argname} ne "true" and $params->{$argname} ne "false") {
					croak "$name parameter '".$argname."' must be 'true' or 'false', got '".$params->{$argname}."'";
				}
				push @$arg_ref, "--$argname", $params->{$argname};
				delete $params->{$argname};
			}
		}
	}
	return;
}

# param_arg_str - process arguments which take a single string
# private class function
sub param_arg_str
{
	my ($name, $defs, $params, $arg_ref) = @_;

	if (exists $defs->{arg_str}) {
		if (ref $defs->{arg_str} ne "ARRAY") {
			confess "process_params parameter 'arg_str' must be an array, got ".(ref $defs->{arg_str});
		}
		foreach my $argname (@{$defs->{arg_str}}) {
			if (exists $params->{$argname}) {
				if (ref $params->{$argname}) {
					confess "$name parameter '".$argname."' must be scalar, got ".(ref $params->{$argname});
				}
				push @$arg_ref, "--$argname", $params->{$argname};
				delete $params->{$argname};
			}
		}
	}
	return;
}

# param_arg_array - process arguments which take an array (converted to multiple occurrences on command line)
# private class function
sub param_arg_array
{
	my ($name, $defs, $params, $arg_ref) = @_;

	if (exists $defs->{arg_array}) {
		if (ref $defs->{arg_array} ne "ARRAY") {
			confess "process_params parameter 'arg_array' must be an array, got ".(ref $defs->{arg_array});
		}
		foreach my $argname (@{$defs->{arg_array}}) {
			if (exists $params->{$argname}) {
				if (not ref $params->{$argname}) {
					push @$arg_ref, "--$argname", $params->{$argname};
				} elsif (ref $params->{$argname} eq "ARRAY") {
					foreach my $entry (@{$params->{$argname}}) {
						push @$arg_ref, "--$argname", $entry;
					}
				} else {
					confess "$name parameter '".$argname."' must be scalar or array, got ".(ref $params->{$argname});
				}
				delete $params->{$argname};
			}
		}
	}
	return;
}

# param_arg_list - process arguments which are formatted as a list on the command-line
# This is only used by buildah-config's entrypoint parameter. This wrapper allows the parameter to be given as
# an array structure which will be provided to buildah formatted as a string parameter.
# private class function
sub param_arg_list
{
	my ($name, $defs, $params, $arg_ref) = @_;

	if (exists $defs->{arg_list}) {
		if (ref $defs->{arg_list} ne "ARRAY") {
			confess "process_params parameter 'arg_list' must be an array, got ".(ref $defs->{arg_list});
		}
		foreach my $argname (@{$defs->{arg_list}}) {
			if (exists $params->{$argname}) {
				if (not ref $params->{$argname}) {
					push @$arg_ref, "--$argname", $params->{$argname};
				} elsif (ref $params->{$argname} eq "ARRAY") {
					push @$arg_ref, "--$argname", '[ "'.join('", "', @{$params->{$argname}}).'" ]';
				} else {
					confess "$name parameter '$argname' must be scalar or array, got ".(ref $params->{$argname});
				}
				delete $params->{$argname};
			}
		}
	}
	return;
}

# parameter processing for buildah subcommand wrapper functions
# private class function - used only by Container::Buildah and Container::Buildah::Stage
#
# usage: ($extract, @args) = process_params({name => str, deflist => [ ... ], ... }, \%params);
#   deflist can be any of: extract exclusive arg_init arg_flag arg_flag_str arg_str arg_array arg_list
#
# All the buildah subcommand wrapper functions use similar logic to process parameters, which is centralized here.
# This builds an argument list to be used by a buildah subcommand.
# Parameters are the same names as command-line arguments of buildah subcommands.
sub process_params
{
	my $defs = shift; # defintions of parameters to process
	my $params = shift; # received parameters

	# results to build and return
	my @args; # argument list result to pass back
	my %extracted; # parameters extracted by name

	# get wrapper function name to use in error reporting
	# use caller function name if not provided
	my $name = $defs->{name} // (caller(1))[3];

	# set aside parameters which caller wants extracted for further processing that we can't generalize here
	params_extract($defs, $params, \%extracted);

	# initialize argument list
	param_arg_init($defs, \@args);

	# check for exclusive parameters - if any are present, it must be the only parameter
	param_exclusive($name, $defs, $params, \%extracted);

	# process arguments which are boolean flags, excluding those requiring true/false as a string
	param_arg_flag($name, $defs, $params, \@args);

	# process arguments which are boolean flags, requiring true/false as a string
	param_arg_flag_str($name, $defs, $params, \@args);

	# process arguments which take a single string
	param_arg_str($name, $defs, $params, \@args);

	# process arguments which take an array (converted to multiple occurrences on command line)
	param_arg_array($name, $defs, $params, \@args);

	# process arguments which are formatted as a list on the command-line
	# (this is only used by buildah-config's entrypoint parameter)
	param_arg_list($name, $defs, $params, \@args);

	# error out if any unexpected parameters remain
	if (%$params) {
		confess "$name received undefined parameters: ".(join(" ", keys %$params));
	}

	# return processed argument list
	return (\%extracted, @args);
}

#
# system access utility functions
#

# generate name of environment variable for where to find a command
# this is broken out as a separate function for tests to use it
# private class function
sub envprog
{
	my $progname = shift;
	my $envprog = (uc $progname)."_PROG";
	$envprog =~ s/[\W-]+/_/xg; # collapse any sequences of non-alphanumeric/non-underscore to a single underscore
	return $envprog;
}

# look up program in standard Linux/POSIX path, not using PATH environment variable for security
# private class function
sub prog
{
	my $progname = shift;
	my $cb = Container::Buildah->instance();

	if (!exists $cb->{prog}) {
		$cb->{prog} = {};
	}
	my $prog = $cb->{prog};

	# call with undef to initialize cache (needed for testing because normal use will auto-create it)
	if (!defined $progname) {
		return;
	}

	# return value from cache if found
	if (exists $prog->{$progname}) {
		return $prog->{$progname};
	}

	# if we didn't have the location of the program, look for it and cache the result
	my $envprog = envprog($progname);
	if (exists $ENV{$envprog} and -x $ENV{$envprog}) {
		$prog->{$progname} = $ENV{$envprog};
		return $prog->{$progname};
	}

	# search paths in order emphasizing recent Linux Filesystem that prefers /usr/bin, then Unix PATH order
	my $found;
	for my $path ("/usr/bin", "/sbin", "/usr/sbin", "/bin") {
		if (-x "$path/$progname") {
			$prog->{$progname} = "$path/$progname";
			$found = $prog->{$progname};
			last;
		}
	}

	# return path, or error if we didn't find a known secure location for the program
	if (not defined $found) {
		croak "unknown secure location for $progname - install it or set $envprog to point to it";
	}
	return $found
}

#
# external command functions
#

# run a command and report errors
# private class method
sub cmd
{
	my ($class_or_obj, $opts, @in_args) = @_;
	my $cb = (ref $class_or_obj) ? $class_or_obj : $class_or_obj->instance();
	my $name = (exists $opts->{name}) ? $opts->{name} : "cmd";

	# exception-handling wrapper
	my $outstr;
	eval {
		# disallow undef in in_args
		Container::Buildah::disallow_undef(\@in_args);

		# use IPC::Run to capture or suppress output as requested
		$cb->debug({level => 4}, "cmd $name ".join(" ", @in_args));
		my $outdest = \*STDOUT;
		my $errdest = \*STDERR;
		if ($opts->{capture_output} // 0) {
			$outdest = \$outstr;
		} elsif ($opts->{suppress_output} // 0) {
			$outdest = "/dev/null";
		}
		if ($opts->{suppress_error} // 0) {
			$errdest = "/dev/null";
		}
		IPC::Run::run(\@in_args, '<', \undef, '>', $outdest, '2>', $errdest);

		# process result codes
		if ($? == -1) {
			confess "failed to execute command (".join(" ", @in_args)."): $!";
		}
		if ($? & 127) {
			confess sprintf "command (".join(" ", @in_args)." child died with signal %d, %s coredump\n",
				($? & 127),  ($? & 128) ? 'with' : 'without';
		}
		my $retcode = $? >> 8;
		if (exists $opts->{save_retcode} and ref $opts->{save_retcode} eq "SCALAR") {
			${$opts->{save_retcode}} = $retcode; # save return code via a scalar ref for testing
		}
		if ($retcode != 0) {
			# invoke callback for nonzero result, and pass it the result code
			# this may be used to prevent exceptions for commands that return specific unharmful nonzero results
			if (exists $opts->{nonzero} and ref $opts->{nonzero} eq "CODE") {
				&{$opts->{nonzero}}($retcode);
			} else {
				confess "non-zero status ($retcode) from cmd ".join(" ", @in_args);
			}
		} elsif (exists $opts->{zero} and ref $opts->{zero} eq "CODE") {
			# invoke callback for zero result
			&{$opts->{zero}}();
		}
		1;
	} or do {
		if ($@) {
			confess "$name: ".$@;
		}
	};
	return $outstr;
}

# check that the OS kernel is capable of running containers
# returns true/false, caches result in config data
# used by buildah() method and unit tests
# public class method
sub container_compat_check
{
	my ($class_or_obj, @in_args) = @_;
	my $cb = (ref $class_or_obj) ? $class_or_obj : $class_or_obj->instance();

	# check if kernel has already been tested
	my $config_key = "container_compat";
	my $test_result = $cb->get_config($config_key);
	if (defined $test_result) {
		$cb->debug({level => 4}, "container_compat_check: cached result $test_result");
		return $test_result;
	}

	# call POSIX::uname() to get kernel name and release
	$test_result = 0; # reset value and assume false
	my ($sysname, $nodename, $release, $version, $machine) = POSIX::uname();
	my ($kmajor, $kminor) = ($release =~ /^([0-9]+)\.([0-9]+)\./x);

	# currently only Linux 2.8 kernels and above support containers
	# adjust as necessary if others (i.e. BSD variants) add container compatibility in the future
	if ($sysname eq "Linux") {
		if ($kmajor >= 3) {
			$test_result = 1;
		} elsif ($kmajor == 2 and $kminor >= 8) {
			$test_result = 1;
		}
	}

	# cache the result in the config data and return it
	my $config = $cb->get_config();
	$config->{$config_key} = $test_result;
	$cb->debug({level => 4}, "container_compat_check: test result $test_result");
	return $test_result
}

# run buildah command with parameters
# public class method
sub buildah
{
	my ($class_or_obj, @in_args) = @_;
	my $cb = (ref $class_or_obj) ? $class_or_obj : $class_or_obj->instance();

	# verify kernel compatibility
	$cb->container_compat_check() or croak "buildah(): kernel is not container-compatible";

	# collect options to pass along to cmd() method
	my $opts = {};
	if (ref $in_args[0] eq "HASH") {
		$opts = shift @in_args;
	}
	$opts->{name} = "buildah";

	Container::Buildah::disallow_undef(\@in_args);
	$cb->debug({level => 3}, "buildah: args = ".join(" ", @in_args));
	return $cb->cmd($opts, prog("buildah"), @in_args);
}

#
# buildah subcommand wrapper methods
# for subcommands which do not have a container name parameter (those are in Container::Buildah::Stage)
#

# front end to "buildah bud" (build under dockerfile) subcommand
# usage: $cb->bud({name => value, ...}, context)
# public class method
sub bud
{
	my ($class_or_obj, @in_args) = @_;
	my $cb = (ref $class_or_obj) ? $class_or_obj : $class_or_obj->instance();
	my $params = {};
	if (ref $in_args[0] eq "HASH") {
		$params = shift @in_args;
	}

	# process parameters
	my ($extract, @args) = process_params({name => 'bud',
		extract => [qw(suppress_output suppress_error nonzero zero)],
		arg_flag => [qw(compress disable-content-trust http-proxy log-rusage no-cache pull pull-always pull-never
			quiet rm squash tls-verify)],
		arg_flag_str => [qw(disable-compression force-rm layers)],
		arg_str => [qw(arch authfile blob-cache cache-from cert-dir cgroup-parent cni-config-dir cni-plugin-path
			cpu-period cpu-quota cpu-shares cpuset-cpus cpuset-mems creds decryption-key file format http-proxy
			iidfile ipc isolation jobs logfile loglevel memory memory-swap network os override-arch override-os
			platform runtime shm-size sign-by signature-policy tag target timestamp userns userns-uid-map
			userns-gid-map userns-uid-map-user userns-gid-map-group uts)],
		arg_array => [qw(add-host annotation build-arg cap-add cap-drop device dns dns-option dns-search
			label runtime-flag security-opt ulimit volume)],
		}, $params);

	# run buildah-tag
	$cb->buildah($extract, "bud", @args, @in_args);
	return;
}

# front end to "buildah containers" subcommand
# usage: $str = $cb->containers({name => value, ...})
# public class method
sub containers
{
	my ($class_or_obj, @in_args) = @_;
	my $cb = (ref $class_or_obj) ? $class_or_obj : $class_or_obj->instance();
	my $params = {};
	if (ref $in_args[0] eq "HASH") {
		$params = shift @in_args;
	}

	# process parameters
	my ($extract, @args) = process_params({name => 'containers',
		extract => [qw(suppress_error nonzero zero)],
		arg_flag => [qw(all json noheading notruncate quiet)],
		arg_str => [qw(filter format)],
		}, $params);

	# run command and return output
	return $cb->buildah({capture_output => 1, %$extract}, "containers", @args);
}

# front-end to "buildah from" subcommand
# usage: $cb->from( [{[key => value], ...},] image )
# public instance method
sub from
{
	my ($class_or_obj, @in_args) = @_;
	my $cb = (ref $class_or_obj) ? $class_or_obj : $class_or_obj->instance();
	my $params = {};
	if (ref $in_args[0] eq "HASH") {
		$params = shift @in_args;
	}

	# process parameters
	my ($extract, @args) = process_params({name => 'from',
		extract => [qw(suppress_output suppress_error nonzero zero)],
		arg_flag => [qw(pull-always pull-never tls-verify quiet)],
		arg_flag_str => [qw(http-proxy pull)],
		arg_str => [qw(authfile blob-cache cert-dir cgroup-parent cidfile cni-config-dir cni-plugin-path cpu-period
			cpu-quota cpu-shares cpuset-cpus cpuset-mems creds device format ipc isolation memory memory-swap name
			network override-arch override-os pid shm-size ulimit userns userns-uid-map userns-gid-map
			userns-uid-map-user userns-gid-map-group uts)],
		arg_array => [qw(add-host cap-add cap-drop decryption-key device dns dns-option dns-search security-opt
			ulimit volume)],
	}, $params);

	# get image parameter
	my $image = shift @in_args;
	if (not defined $image) {
		croak "image parameter missing in call to 'from' method";
	}

	# run command
	$cb->buildah($extract, "from", @args, $image);
	return;
}

# front end to "buildah images" subcommand
# usage: $str = $cb->images({name => value, ...})
# public class method
sub images
{
	my ($class_or_obj, @in_args) = @_;
	my $cb = (ref $class_or_obj) ? $class_or_obj : $class_or_obj->instance();
	my $params = {};
	if (ref $in_args[0] eq "HASH") {
		$params = shift @in_args;
	}

	# process parameters
	my ($extract, @args) = process_params({name => 'images',
		extract => [qw(suppress_error nonzero zero)],
		arg_flag => [qw(all digests json history noheading no-trunc notruncate quiet)],
		arg_str => [qw(filter format)],
		}, $params);

	# run command and return output
	return $cb->buildah({capture_output => 1, %$extract}, "images", @args);
}

# front end to "buildah info" subcommand
# usage: $str = $cb->info([{debug => 1, format => format}])
# this uses YAML::XS with the assumption that buildah-info's JSON output is a proper subset of YAML
# public class method
sub info
{
	my ($class_or_obj, @in_args) = @_;
	my $cb = (ref $class_or_obj) ? $class_or_obj : $class_or_obj->instance();
	my $params = {};
	if (ref $in_args[0] eq "HASH") {
		$params = shift @in_args;
	}

	# process parameters
	my ($extract, @args) = process_params({name => 'info',
		extract => [qw(suppress_error nonzero zero)],
		arg_flag => [qw(debug)],
		arg_str => [qw(format)],
		}, $params);

	# run command and return output
	my $yaml = $cb->buildah({capture_output => 1, %$extract}, "info", @args);
	my $info = YAML::XS::Load($yaml);
	return $info;
}

# front end to "buildah inspect" subcommand
# usage: $str = $cb->inspect([{option => value, ...}], object_id)
# this uses YAML::XS with the assumption that buildah-inspect's JSON output is a proper subset of YAML
# public class method
sub inspect
{
	my ($class_or_obj, @in_args) = @_;
	my $cb = (ref $class_or_obj) ? $class_or_obj : $class_or_obj->instance();
	my $params = {};
	if (ref $in_args[0] eq "HASH") {
		$params = shift @in_args;
	}

	# process parameters
	my $object_id = $in_args[0];
	if (not defined $object_id) {
		croak "object id parameter missing in call to 'inspect' method";
	}
	my ($extract, @args) = process_params({name => 'inspect',
		extract => [qw(suppress_error nonzero zero)],
		arg_str => [qw(format type)],
		}, $params);

	# run command and return output
	my $yaml = $cb->buildah({capture_output => 1, %$extract}, "inspect", @args,  $object_id);
	my $inspect = YAML::XS::Load($yaml);
	return $inspect;
}

# front end to "buildah manifest_add" subcommand
# usage: $str = $cb->manifest_add([{option => value, ...}], list-or-index, image)
# public class method
sub manifest_add
{
	my ($class_or_obj, @in_args) = @_;
	my $cb = (ref $class_or_obj) ? $class_or_obj : $class_or_obj->instance();
	my $params = {};
	if (ref $in_args[0] eq "HASH") {
		$params = shift @in_args;
	}

	# process parameters
	my $list_or_index = $in_args[0];
	if (not defined $list_or_index) {
		croak "list/index parameter missing in call to 'manifest_add' method";
	}
	my $image = $in_args[1];
	if (not defined $image) {
		croak "object id parameter missing in call to 'manifest_add' method";
	}
	my ($extract, @args) = process_params({name => 'manifest_add',
		extract => [qw(suppress_error nonzero zero)],
		arg_flag => [qw(all tls-verify)],
		arg_str => [qw(arch authfile cert-dir creds os os-version override-arch override-os variant)],
		arg_array => [qw(annotation features os-features)],
		}, $params);

	# run command and return output
	my $manifest_add = $cb->buildah({capture_output => 1, %$extract}, "manifest_add", @args, $list_or_index, $image);
	return $manifest_add;
}

# front end to "buildah manifest_annotate" subcommand
# usage: $str = $cb->manifest_annotate([{option => value, ...}], list-or-index, digest)
# public class method
sub manifest_annotate
{
	my ($class_or_obj, @in_args) = @_;
	my $cb = (ref $class_or_obj) ? $class_or_obj : $class_or_obj->instance();
	my $params = {};
	if (ref $in_args[0] eq "HASH") {
		$params = shift @in_args;
	}

	# process parameters
	my $list_or_index = $in_args[0];
	if (not defined $list_or_index) {
		croak "list/index parameter missing in call to 'manifest_annotate' method";
	}
	my $digest = $in_args[1];
	if (not defined $digest) {
		croak "image manifest digest parameter missing in call to 'manifest_annotate' method";
	}
	my ($extract, @args) = process_params({name => 'manifest_annotate',
		extract => [qw(suppress_error nonzero zero)],
		arg_str => [qw(arch os os-version variant)],
		arg_array => [qw(annotation features os-features)],
		}, $params);

	# run command and return output
	my $manifest_annotate = $cb->buildah({capture_output => 1, %$extract}, "manifest_annotate", @args, $list_or_index,
		$digest);
	return $manifest_annotate;
}

# front end to "buildah manifest_create" subcommand
# usage: $str = $cb->manifest_create([{option => value, ...}], list-or-index, image)
# public class method
sub manifest_create
{
	my ($class_or_obj, @in_args) = @_;
	my $cb = (ref $class_or_obj) ? $class_or_obj : $class_or_obj->instance();
	my $params = {};
	if (ref $in_args[0] eq "HASH") {
		$params = shift @in_args;
	}

	# process parameters
	my $list_or_index = $in_args[0];
	if (not defined $list_or_index) {
		croak "list/index parameter missing in call to 'manifest_create' method";
	}
	my $image = $in_args[1];
	my ($extract, @args) = process_params({name => 'manifest_create',
		extract => [qw(suppress_error nonzero zero)],
		arg_flag => [qw(all)],
		arg_str => [qw(override-arch override-os)],
		arg_array => [qw()],
		}, $params);

	# run command and return output
	my $manifest_create = $cb->buildah({capture_output => 1, %$extract}, "manifest_create", @args, $list_or_index,
		($image // ()));
	return $manifest_create;
}

# front end to "buildah manifest_inspect" subcommand
# usage: $str = $cb->manifest_inspect([{option => value, ...}], list-or-index)
# public class method
sub manifest_inspect
{
	my ($class_or_obj, @in_args) = @_;
	my $cb = (ref $class_or_obj) ? $class_or_obj : $class_or_obj->instance();
	my $params = {};
	if (ref $in_args[0] eq "HASH") {
		$params = shift @in_args;
	}

	# process parameters
	my $list_or_index = $in_args[0];
	if (not defined $list_or_index) {
		croak "list/index parameter missing in call to 'manifest_inspect' method";
	}
	my ($extract, @args) = process_params({name => 'manifest_inspect',
		extract => [qw(suppress_error nonzero zero)],
		}, $params);

	# run command and return output
	my $manifest_inspect = $cb->buildah({capture_output => 1, %$extract}, "manifest_inspect", $list_or_index);
	return $manifest_inspect;
}

# front end to "buildah manifest_push" subcommand
# usage: $str = $cb->manifest_push([{option => value, ...}], list-or-index, registry)
# public class method
sub manifest_push
{
	my ($class_or_obj, @in_args) = @_;
	my $cb = (ref $class_or_obj) ? $class_or_obj : $class_or_obj->instance();
	my $params = {};
	if (ref $in_args[0] eq "HASH") {
		$params = shift @in_args;
	}

	# process parameters
	my $list_or_index = $in_args[0];
	if (not defined $list_or_index) {
		croak "list/index parameter missing in call to 'manifest_push' method";
	}
	my $registry = $in_args[1];
	my ($extract, @args) = process_params({name => 'manifest_push',
		extract => [qw(suppress_error nonzero zero)],
		arg_flag => [qw(all purge quiet remove-signatures tls-verify)],
		arg_str => [qw(authfile cert-dir creds digestfile format sign-by signature-policy)],
		arg_array => [qw()],
		}, $params);

	# run command and return output
	my $manifest_push = $cb->buildah({capture_output => 1, %$extract}, "manifest_push", @args, $list_or_index,
		$registry);
	return $manifest_push;
}

# front end to "buildah manifest_remove" subcommand
# usage: $str = $cb->manifest_remove([{option => value, ...}], list-or-index, image-manifest-digest)
# public class method
sub manifest_remove
{
	my ($class_or_obj, @in_args) = @_;
	my $cb = (ref $class_or_obj) ? $class_or_obj : $class_or_obj->instance();
	my $params = {};
	if (ref $in_args[0] eq "HASH") {
		$params = shift @in_args;
	}

	# process parameters
	my $list_or_index = $in_args[0];
	if (not defined $list_or_index) {
		croak "list/index parameter missing in call to 'manifest_remove' method";
	}
	my $image_manifest_digest = $in_args[0];
	if (not defined $image_manifest_digest) {
		croak "image manifest digest parameter missing in call to 'manifest_remove' method";
	}
	my ($extract, @args) = process_params({name => 'manifest_remove',
		extract => [qw(suppress_error nonzero zero)],
		}, $params);

	# run command and return output
	my $manifest_remove = $cb->buildah({capture_output => 1, %$extract}, "manifest_remove", $list_or_index,
		$image_manifest_digest);
	return $manifest_remove;
}

# front-end to "buildah mount" subcommand
# usage: $mounts = $cb->mount({[notruncate => 1]}, container, ...)
# public class method
sub mount
{
	my ($class_or_obj, @in_args) = @_;
	my $cb = (ref $class_or_obj) ? $class_or_obj : $class_or_obj->instance();
	my $params = {};
	if (ref $in_args[0] eq "HASH") {
		$params = shift @in_args;
	}

	# process parameters
	my ($extract, @args) = process_params({name => 'mount',
		extract => [qw(suppress_error nonzero zero)],
		arg_flag => [qw(notruncate)]
		}, $params);

	# run buildah-tag
	my $output = $cb->buildah({capture_output => 1, %$extract}, "mount", @args, @in_args);
	my %mounts = split(/\s+/sx, $output);
	return \%mounts;
}

# front end to "buildah pull" subcommand
# usage: $str = $cb->pull([{option => value, ...}], image)
# public class method
sub pull
{
	my ($class_or_obj, @in_args) = @_;
	my $cb = (ref $class_or_obj) ? $class_or_obj : $class_or_obj->instance();
	my $params = {};
	if (ref $in_args[0] eq "HASH") {
		$params = shift @in_args;
	}

	# process parameters
	my $image = $in_args[0];
	if (not defined $image) {
		croak "object id parameter missing in call to 'pull' method";
	}
	my ($extract, @args) = process_params({name => 'pull',
		extract => [qw(suppress_error nonzero zero)],
		arg_flag => [qw(all-tags remove-signatures quiet tls-verify)],
		arg_str => [qw(authfile blob-cache cert-dir creds override-os override-arch signature-policy)],
		arg_array => [qw(decryption-key)],
		}, $params);

	# run command and return output
	my $pull = $cb->buildah({capture_output => 1, %$extract}, "pull", @args,  $image);
	return $pull;
}

# front end to "buildah push" subcommand
# named push_image() to de-conflict with Perl builtin push, but Container::Buildah links push() as an alias
# usage: $str = $cb->push_image([{option => value, ...}], image, [destination])
# or:    $str = $cb->push([{option => value, ...}], image, [destination])
# public class method
sub push_image
{
	my ($class_or_obj, @in_args) = @_;
	my $cb = (ref $class_or_obj) ? $class_or_obj : $class_or_obj->instance();
	my $params = {};
	if (ref $in_args[0] eq "HASH") {
		$params = shift @in_args;
	}

	# process parameters
	my ($extract, @args) = process_params({name => 'push_image',
		extract => [qw(suppress_output suppress_error nonzero zero)],
		arg_flag => [qw(disable-compression quiet remove-signatures tls-verify)],
		arg_str => [qw(authfile blob-cache cert-dir creds digestfile format sign-by signature-policy)],
		arg_array => [qw(encryption-key encrypt-layer)],
		}, $params);

	# run command and return output
	$cb->buildah({%$extract}, "push_image", @args,  @in_args);
	return;
}

# front end to "buildah rename" subcommand
# named rename_image() to de-conflict with Perl builtin rename, but Container::Buildah links rename() as an alias
# usage: $str = $cb->rename_image(image, new-name)
# or:    $str = $cb->rename(image, new-name)
# public class method
sub rename_image
{
	my ($class_or_obj, @in_args) = @_;
	my $cb = (ref $class_or_obj) ? $class_or_obj : $class_or_obj->instance();
	my $params = {};
	if (ref $in_args[0] eq "HASH") {
		$params = shift @in_args;
	}

	# process parameters
	my ($extract, @args) = process_params({name => 'rename_image',
		extract => [qw(suppress_output suppress_error nonzero zero)],
		}, $params);

	# run command and return output
	$cb->buildah({%$extract}, "rename_image", @in_args);
	return;
}


# front end to "buildah tag" subcommand
# usage: $cb->tag({image => "image_name"}, new_name, ...)
# public class method
sub tag
{
	my ($class_or_obj, @in_args) = @_;
	my $cb = (ref $class_or_obj) ? $class_or_obj : $class_or_obj->instance();
	my $params = {};
	if (ref $in_args[0] eq "HASH") {
		$params = shift @in_args;
	}

	# process parameters
	my ($extract, @args) = process_params({name => 'tag',
		extract => [qw(image suppress_output suppress_error nonzero zero)],
		}, $params);
	my $image = $extract->{image}
		or croak "tag: image parameter required";
	delete $extract->{image};

	# run buildah-tag
	$cb->buildah($extract, "tag", $image, @in_args);
	return;
}

# front end to "buildah rm" (remove container) subcommand
# usage: $cb->rm(container, [...])
#    or: $cb->rm({all => 1})
# public class method
sub rm
{
	my ($class_or_obj, @in_args) = @_;
	my $cb = (ref $class_or_obj) ? $class_or_obj : $class_or_obj->instance();
	my $params = {};
	if (ref $in_args[0] eq "HASH") {
		$params = shift @in_args;
	}

	# process parameters
	my ($extract, @args) = process_params({name => 'rm',
		extract => [qw(suppress_output suppress_error nonzero zero)],
		arg_flag => [qw(all)],
		exclusive => [qw(all)]
		}, $params);

	# remove containers listed in arguments
	# buildah will error out if --all is provided with container names/ids
	$cb->buildah($extract, "rm", @args, @in_args);
	return;
}

# front end to "buildah rmi" (remove image) subcommand
# usage: $cb->rmi([{force => 1},] image, [...])
#    or: $cb->rmi({prune => 1})
#    or: $cb->rmi({all => 1})
# public class method
sub rmi
{
	my ($class_or_obj, @in_args) = @_;
	my $cb = (ref $class_or_obj) ? $class_or_obj : $class_or_obj->instance();
	my $params = {};
	if (ref $in_args[0] eq "HASH") {
		$params = shift @in_args;
	}

	# process parameters
	my ($extract, @args) = process_params({name => 'rmi',
		extract => [qw(suppress_output suppress_error nonzero zero)],
		arg_flag => [qw(all prune force)],
		exclusive => [qw(all prune)],
		}, $params);

	# remove images listed in arguments
	# buildah will error out if --all or --prune are provided with image names/ids
	$cb->buildah($extract, "rmi", @args, @in_args);
	return;
}

# front-end to "buildah umount" subcommand
# usage: $cb->umount({[notruncate => 1]}, container, ...)
# public class method
sub umount
{
	my ($class_or_obj, @in_args) = @_;
	my $cb = (ref $class_or_obj) ? $class_or_obj : $class_or_obj->instance();
	my $params = {};
	if (ref $in_args[0] eq "HASH") {
		$params = shift @in_args;
	}

	# process parameters
	my ($extract, @args) = process_params({name => 'umount',
		extract => [qw(suppress_output suppress_error nonzero zero)],
		arg_flag => [qw(all)],
		exclusive => [qw(all)],
		}, $params);

	# run buildah-tag
	$cb->buildah($extract, "umount", @args, @in_args);
	return;
}


# front end to "buildah unshare" (user namespace share) subcommand
# usage: $cb->unshare({container => "name_or_id", [envname => "env_var_name"]}, "cmd", "args", ... )
# public class method
sub unshare
{
	my ($class_or_obj, @in_args) = @_;
	my $cb = (ref $class_or_obj) ? $class_or_obj : $class_or_obj->instance();
	my $params = {};
	if (ref $in_args[0] eq "HASH") {
		$params = shift @in_args;
	}

	# process parameters
	my ($extract, @args) = process_params({name => 'unshare',
		extract => [qw(container envname suppress_output suppress_error nonzero zero)],
		arg_str => [qw(mount)],
		}, $params);

	# construct arguments for buildah-unshare command
	# note: --mount may be specified directly or constructed from container/envname - use only one way, not both
	if (exists $extract->{container}) {
		if (exists $extract->{envname}) {
			CORE::push @args, "--mount", $extract->{envname}."=".$extract->{container};
			delete $extract->{envname};
		} else {
			CORE::push @args, "--mount", $extract->{container};
		}
		delete $extract->{container};
	}

	# run buildah-unshare command
	$cb->buildah($extract, "unshare", @args, "--", @in_args);
	return;
}

# front end to "buildah version" subcommand
# usage: $str = $cb->version([{debug => 1, format => format}])
# this uses YAML::XS with the assumption that buildah-version's JSON output is a proper subset of YAML
# public class method
sub version
{
	my ($class_or_obj, @in_args) = @_;
	my $cb = (ref $class_or_obj) ? $class_or_obj : $class_or_obj->instance();
	my $params = {};
	if (ref $in_args[0] eq "HASH") {
		$params = shift @in_args;
	}

	# process parameters
	my ($extract, @args) = process_params({name => 'version',
		extract => [qw(suppress_error nonzero zero)],
		}, $params);

	# run command and return output
	my $yaml = $cb->buildah({capture_output => 1, %$extract}, "version", @args);
	my $version = YAML::XS::Load($yaml);
	return $version;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Container::Buildah::Subcommand - wrapper class for Container::Buildah to run subcommands of buildah

=head1 VERSION

version 0.3.1

=head1 SYNOPSIS

    use <Container::Buildah>;

=head1 DESCRIPTION

Container::Buildah::Subcommand provides the following methods, which should be called as methods of
L<Container::Buildah>. Since Container::Buildah is a singleton, these methods can be called as
class or instance methods. For example:

=over 1

=item call buildah() as a class method

Container::Buildah->buildah("run", @args, $container_name, "--", @command);

=item call buildah() as an instance method

my $cb = Container::Buildah->instance("run", @args, $container_name, "--", @command);
$cb->buildah();

=back

=head1 FUNCTIONS AND METHODS

=over 1

=item prog

=item cmd

=item buildah

=item bud

=item containers

=item from

=item images

=item info

=item inspect

=item mount

=item pull

=item push

=item rename

=item rm

=item rmi

=item tag

=item umount

=item unshare

=item version

=back

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/Container-Buildah/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/Container-Buildah/pulls>

Containers can only be run with a Linux kernel revision 2.8 or newer.

=head1 AUTHOR

Ian Kluft <https://github.com/ikluft>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Ian Kluft.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
