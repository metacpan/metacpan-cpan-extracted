# Container::Buildah::Stage
# ABSTRACT: object used by Container::Buildah to track a stage of a multi-stage container build
# by Ian Kluft

## no critic (Modules::RequireExplicitPackage)
# 'use strict' and 'use warnings' included here
use Modern::Perl qw(2015); # require 5.20.0
## use critic (Modules::RequireExplicitPackage)

package Container::Buildah::Stage;
$Container::Buildah::Stage::VERSION = '0.2.1';
use autodie;
use Carp qw(croak confess);
use Cwd;
use Readonly;
use File::stat;
use FindBin;

# import from Container::Buildah::Subcommand after BEGIN phase (where 'use' takes place), to avoid conflicts
require Container::Buildah;
require Container::Buildah::Subcommand;
Container::Buildah::Subcommand->import(qw(process_params prog));

Readonly::Scalar my $mnt_env_name => "BUILDAHUTIL_MOUNT";
Readonly::Array my @auto_accessors => qw(commit consumes depends from func_deps func_exec mnt name produces
	user user_home);
my $accessors_created = 0;

# instantiate an object
# this should only be called by Container::Buildah
# these objects will be passed to each stage's stage->func_*()
# private class method
sub new {
	my ($class, @in_args) = @_;

	my $self = { @in_args };
	bless $self, $class;

	# enforce that only Container::Buildah module can call this method
	my ($package) = caller;
	if ($package ne "Container::Buildah") {
		croak  __PACKAGE__."->new() can only be called from Container::Buildah";
	}

	# initialize accessor methods if not done on a prior call to new()
	generate_read_accessors();

	# check for required name parameter
	if (not exists $self->{name}) {
		croak __PACKAGE__.": cannot instantiate without a name parameter";
	}

	# get container mount point, if in the user namespace
	if (exists $ENV{$mnt_env_name}) {
		$self->{mnt} = $ENV{$mnt_env_name};
	}

	# get ref to stage configuation
	my $config = Container::Buildah->get_config("stages", $self->{name});
	if ((not defined $config) or (ref $config ne "HASH")) {
		croak __PACKAGE__.": no configuration for stage ".$self->{name};
	}
	foreach my $key (keys %$config) {
		$self->{$key} = $config->{$key};
	}

	# check for missing stage config settings
	my @missing;
	foreach my $key (qw(from func_exec)) {
		if (not exists $self->{$key}) {
			push @missing, $key;
		}
	}

	# fail if any required parameters are missing
	if (@missing) {
		croak __PACKAGE__.": required parameters missing in stage ".$self->{name}.": ".join(" ", @missing);
	}

	return $self;
}

# return entry from stage configuration subset of Container::Buildah configuation
# Note: this reads the stage configuration data, not to be confused with buildah's config subcommand
# public instance method
sub stage_config
{
	my ($self, $key) = @_;
	if (exists $self->{$key}) {
		if (ref $self->{$key} and ref $self->{$key} ne "ARRAY") {
			return $self->{$key};
		}

		# if the value is a scalar, perform variable expansion
		return Container::Buildah::expand($self->{$key});
	}
	return;
}

# status method forward to Container::Buildah::status()
# public instance method
sub status
{
	my ($self, @in_args) = @_;
	my $cb = Container::Buildah->instance();
	my @label;
	@label = ('['.$self->container_name().']');
	$cb->status(@label, @in_args);
	return;
}

# debug method forward to Container::Buildah::debug()
# public instance method
sub debug
{
	my ($self, @in_args) = @_;
	my $cb = Container::Buildah->instance();

	# collect debug parameters
	my %params;
	if (ref $in_args[0] eq "HASH") {
		my $params_ref = shift @in_args;
		%params = %$params_ref;
	}
	$params{wrapper} = 1; # tell Container::Buidlah::debug() to skip the stack frame for this wrapper

	# insert label parameter with container name, if we're in a state where it's defined
	if (exists $self->{config}{container_name}) {
		$params{label} = $self->{config}{container_name};
	}

	# call the debug method in Container::Buildah
	$cb->debug(\%params, @in_args);
	return;
}

# accessors - commented out but retained to show why we needed to generate accessor functions
#sub get_commit    { my $self = shift; return $self->stage_config("commit"); }
#sub get_consumes  { my $self = shift; return $self->stage_config("consumes"); }
#sub get_from      { my $self = shift; return $self->stage_config("from"); }
#sub get_func_deps { my $self = shift; return $self->stage_config("func_deps"); }
#sub get_func_exec { my $self = shift; return $self->stage_config("func_exec"); }
#sub get_mnt       { my $self = shift; return $self->stage_config("mnt"); }
#sub get_name      { my $self = shift; return $self->stage_config("name"); }
#sub get_produces  { my $self = shift; return $self->stage_config("produces"); }
#sub get_user_home { my $self = shift; return $self->stage_config("user_home"); }
#sub get_user      { my $self = shift; return $self->stage_config("user"); }

# generate read accessor methods
# note: these parameters are set only in new() - there are no write accessors so none are generated
# private class function
sub generate_read_accessors
{
	# check if accessors have been created
	if ($accessors_created) {
		# skip if already done
		return;
	}

	# create accessor methods
	foreach my $field_name (@auto_accessors) {
		# for read accessor name, prepend get_ to field name
		my $method_name = "get_".$field_name;
		
		# generate accessor method to handle this field
		my $method_sub = sub {
			my $self = shift;
			$self->isa(__PACKAGE__)
				or confess "$method_name method (from generate_read_accessors) expects ".__PACKAGE__." object, got "
					.((defined $self)?((ref $self)?ref $self:"scalar"):"(undef)");
			my $value = $self->stage_config($field_name);
			$self->debug({level => 3, name => __PACKAGE__."::".$method_name},
				(defined $value)?"value=$value":"(undef)");
			return $value;
		};

		# install and call the newly-generated method
		no strict 'refs'; ## no critic (ProhibitNoStrict)
		*{ $method_name } = $method_sub; # install generated method in class symbol table
	}
	$accessors_created = 1; # do this only once
	return;
}

# get container name
# generate it the first time
# public instance method
sub container_name
{
	my $self = shift;

	# derive container name
	if (not exists $self->{container_name}) {
		$self->{container_name} = Container::Buildah->get_config("basename")."_".$self->get_name;
	}
	return $self->{container_name};
}

#
# buildah subcommand front-end functions
# Within Container::Buildah::Stage the object has methods for subcommands which take a container name.
# Each method gets container_name from the object. So it is not passed as a separate parameter.
#
# Other more general subcommands are in Container::Buildah class.
#

# front-end to "buildah add" subcommand
# usage: $self->add( [{[dest => value]. [chown => mode]},] src, [src, ...] )
# public instance method
sub add
{
	my ($self, @in_args) = @_;
	$self->debug({level => 2}, @in_args);
	my $params = {};
	if (ref $in_args[0] eq "HASH") {
		$params = shift @in_args;
	}

	# process parameters
	my ($extract, @args) = process_params({name => 'add',
		extract => [qw(dest)],
		arg_init => [qw(--add-history)],
		arg_flag => [qw(quiet)],
		arg_str => [qw(chown)]
	}, $params);

	# get special parameter dest if it exists
	my $dest = $extract->{dest};

	# run command
	my $cb = Container::Buildah->instance();
	$cb->buildah("add", @args, $self->container_name, @in_args, ($dest ? ($dest) : ()));
	return;
}

# front-end to "buildah commit" subcommand
# usage: $self->commit( [{param => value, ...}], image-name )
# public instance method
sub commit
{
	my ($self, @in_args) = @_;
	$self->debug({level => 2}, @in_args);
	my $params = {};
	if (ref $in_args[0] eq "HASH") {
		$params = shift @in_args;
	}
	my $image_name = shift @in_args;

	# process parameters
	my ($extract, @args) = process_params({name => 'commit',
		arg_flag => [qw(disable-compression omit-timestamp quiet rm squash tls-verify)],
		arg_int => [qw(timestamp)],
		arg_str => [qw(authfile blob-cache cert-dir creds encryption-key format iidfile
			reference-time sign-by signature-policy tls-verify omit-timestamp)],
		arg_array => [qw(encrypt-layer)],
	}, $params);

	# do commit
	my $cb = Container::Buildah->instance();
	$cb->buildah("commit", @args, $self->container_name, ($image_name // ()));
	return;
}


# front-end to "buildah config" subcommand
# usage: $self->config({ param => value, ...})
# Note: this is for the container's configuration, not to be confused with configuration data of this module
# public instance method
sub config
{
	my ($self, @in_args) = @_;
	$self->debug({level => 2}, @in_args);
	my $params = {};
	if (ref $in_args[0] eq "HASH") {
		$params = shift @in_args;
	}

	# process parameters
	my ($extract, @args) = process_params({name => 'config',
		arg_init => [qw(--add-history)],
		arg_str => [qw(arch author cmd comment created-by domainname healthcheck healthcheck-interval
			healthcheck-retries healthcheck-start-period healthcheck-timeout history-comment hostname
			os shell stop-signal user workingdir)],
		arg_array => [qw(annotation env label onbuild port volume)],
		arg_list => [qw(entrypoint)],
	}, $params);

	# run command
	my $cb = Container::Buildah->instance();
	$cb->buildah("config", @args, $self->container_name);
	return;
}

# front-end to "buildah copy" subcommand
# usage: $self->copy( [{dest => value},] src, [src, ...] )
# public instance method
sub copy
{
	my ($self, @in_args) = @_;
	$self->debug({level => 2}, @in_args);
	my $params = {};
	if (ref $in_args[0] eq "HASH") {
		$params = shift @in_args;
	}

	# process parameters
	my ($extract, @args) = process_params({name => 'copy',
		extract => [qw(dest)],
		arg_init => [qw(--add-history)],
		arg_flag => [qw(quiet)],
		arg_str => [qw(chown)]
	}, $params);

	# get special parameter dest if it exists
	my $dest = $extract->{dest};

	# run command
	my $cb = Container::Buildah->instance();
	$cb->buildah("copy", @args, $self->container_name, @in_args, ($dest ? ($dest) : ()));
	return;
}

# front-end to "buildah run" subcommand
# usage: $self->run( [{param => value, ...}], [command], ... )
# Command parameter can be an array of strings for one command, or array of arrays of strings for multiple commands.
# This applies the same command-line arguments (from %params) to each command. To change parameters for a command,
# make a separate call to the function.
# public instance method
sub run
{
	my ($self, @in_args) = @_;
	$self->debug({level => 2}, @in_args);
	my $params = {};
	if (ref $in_args[0] eq "HASH") {
		$params = shift @in_args;
	}

	# process parameters
	my ($extract, @args) = process_params({name => 'run',
		arg_init => ['--add-history'],
		arg_flag => [qw(no-pivot terminal)],
		arg_str => [qw(cni-config-dir cni-plugin-path hostname ipc isolation network pid runtime
			user uts)],
		arg_array => [qw(cap-add cap-drop mount runtime-flag security-opt volume)],
	}, $params);

	# loop through provided commands
	# build outer array if only one command was provided
	my @commands = ref $in_args[0] ? @in_args : [@in_args];
	foreach my $command (@commands) {
		# if any entries are not arrays, temporarily make them into one
		if (not ref $command) {
			$command = [$command];
		} elsif (ref $command ne "ARRAY") {
			confess "run: command must be a scalar or array, got ".ref $command;
		}

		# run command
		my $cb = Container::Buildah->instance();
		$cb->buildah("run", @args, $self->container_name, '--', @$command);
	}
	return;
}

#
# private methods - container-stage processing utilities
#

# remove a container by name if it already exists - we need the name
# private instance method
sub rmcontainer
{
	my $self = shift;
	my $cb = Container::Buildah->instance();

	$cb->inspect({
		suppress_error => 1,
		nonzero => sub {},
		zero => sub {$cb->rm($self->container_name);}},
		$self->container_name);
	return;
}

# get path to the executing script
# used for file dependency checks and re-running the script in a container namespace
# private class function
sub progpath
{
	state $progpath = "$FindBin::Bin/$FindBin::Script";
	return $progpath;
}

# derive tarball name for stage which produces it
# defaults to the current stage
# private instance method
sub tarball
{
	my $self = shift;
	my $stage_name = shift // $self->get_name;
	return Container::Buildah->get_config("basename")."_".$stage_name.".tar.bz2";
}

# get file modification timestamp
# private class function
sub ftime
{
	my $file = shift;

	# follow symlinks, limit to 10 levels in case of loop
	my $count=10;
	my $f_file = $file;
	while ($count > 0) {
		if (-l $f_file) {
			$f_file = readlink $f_file;
		} else {
			last;
		}
		$count--;
	}
	if ($count <= 0) {
		croak "ftime: apparent symlink loop or more than 10 levels at $file";
	}

	# skip if the path doesn't point to a file
	if (not  -f $f_file ) {
		croak "ftime: not a regular file at $file";
	}

	# return the modification time of the file
	my $fstat = stat $f_file;
	return $fstat->mtime;
}

# check if this script or configuration is newer than a deliverable file, or if the deliverable doesn't exist
# private class function
sub check_deliverable
{
	my $depfile = shift;

	# if the deliverable doesn't exist, then it must be built
	if (not -e $depfile) {
		return "does not exist";
	}
	if (not -f $depfile) {
		croak "not a file: $depfile";
	}

	# if the program has been modified more recently than the deliverable, the deliverable must be rebuilt
	if (ftime(progpath()) > ftime($depfile)) {
		return "program modified";
	}

	# if the configuration has been modified more recently than the deliverable, the deliverable must be rebuilt
	my $cb = Container::Buildah->instance();
	my $config_files = $cb->get_config('_config_files');
	foreach my $file (@$config_files) {
		if (ftime($file) > ftime($depfile)) {
			return "config file modified";
		}
	}

	return;
}

# generic external wrapper function for all stages
# mount the container namespace and enter it to run the custom stage build function
# private instance method
sub launch_namespace
{
	my $self = shift;

	# check if this stage produces a deliverable to another stage
	my $produces = $self->get_produces;
	if (defined $produces) {
		# generate deliverable file name
		my $tarball_out = $self->tarball;

		# check if deliverable tarball file already exists
		my $tarball_result = check_deliverable($tarball_out);
		if (not $tarball_result) {
			# skip this stage because the deliverable already exists and is up-to-date
			$self->status("build tarball skipped - deliverable up-to-date $tarball_out");
			return;
		}

		# continue with this build stage if tarball missing or program updated more recently than tarball
		$self->status("build tarball ($tarball_result): $tarball_out");
	}

	#
	# run container for this stage
	# commit it if configured (usually that's only for the final stage)
	# otherwise a stage is discarded except for its product tarball
	#

	# if the container exists, remove it
	$self->rmcontainer;

	# get the base image
	my $cb = Container::Buildah->instance();
	$cb->from({name => $self->container_name}, $self->get_from);

	# get copy of @ARGV saved by main() for use here re-launching in namespace
	my $argv_ref = Container::Buildah->get_config("argv");
	if (ref $argv_ref ne "ARRAY") {
		confess "wrong type for argv - expected ARRAY ref, got ".(ref $argv_ref);
	}

	# run the builder script in the container
	$cb->unshare({container => $self->container_name,
		envname => $mnt_env_name},
		progpath(),
		"--internal=".$self->get_name,
		@$argv_ref,
		);

	# commit the container if configured
	my $commit = $self->get_commit;
	my @tags;
	if (defined $commit) {
		if (not ref $commit) {
			@tags = ($commit);
		} elsif (ref $commit eq "ARRAY") {
			@tags = @$commit;
		} else {
			confess "reference to ".(ref $commit)." not supported in commit - use scalar or array";
		}
	}
	my $image_name = shift @tags;
	$self->commit($image_name);
	if (@tags) {
		$cb->tag({image => $image_name}, @tags);
	}
	return;
}

# import tarball(s) from other container stages if configured
# private instance method
sub consume
{
	my $self = shift;

	# create groups and users before import
	my $user = $self->get_user;
	if (defined $self->get_user) {
		my $user_name = $user;
		my ($uid, $group_name, $gid);
		if ($user =~ /:/x) {
			($user_name, $group_name) = split /:/x, $user;
			if ($user_name =~ /=/x) {
				($user_name, $uid) = split /=/x, $user_name;
			}
			if ($group_name =~ /=/x) {
				($group_name, $gid) = split /=/x, $group_name;
			}
		}
		# TODO: find distro-independent approach instead of assuming Linux Fileystem Standard /usr/sbin paths
		if (defined $group_name) {
			$self->run(["/usr/sbin/groupadd", ((defined $gid) ? ("--gid=$gid") : ()), $group_name]);
		}
		my $user_home = $self->get_user_home;
		$self->run(
			["/usr/sbin/useradd", ((defined $uid) ? ("--uid=$uid") : ()),
				((defined $group_name) ? ("--gid=$group_name") : ()),
				((defined $user_home) ? ("--home-dir=$user_home") : ()), $user_name],
		);
	}

	# import tarballs from each stage we depend upon
	my $consumes = $self->get_consumes;
	if (defined $consumes) {
		if (ref $consumes eq "ARRAY") {
			my @in_stages = @$consumes;
			my $cwd = getcwd();
			foreach my $in_stage (@in_stages) {
				my $tarball_in = $self->tarball($in_stage);
				$self->debug("in ".$self->get_name." stage before untar; pid=$$ cwd=$cwd tarball=$tarball_in");
				(-f $tarball_in) or croak "consume(".join(" ", @in_stages)."): ".$tarball_in." not found";
				$self->add({dest => "/"}, $tarball_in);
			}
		} else {
			croak "consume stage->consumes was set but not an array ref";
		}
	}
	return;
}

# drop leading slash from a path
# private class function
sub dropslash
{
	my $str = shift;
	if (substr($str,0,1) eq '/') {
		substr($str,0,1,'');
	}
	return $str;
}

# export tarball for availability to other container stages if configured
# private instance method
sub produce
{
	my $self = shift;

	# export directories to tarball for product of this stage
	my $produces = $self->get_produces;
	if (defined $produces) {
		if (ref $produces eq "ARRAY") {
			my $tarball_out = $self->tarball;
			my $cb = Container::Buildah->instance();
			my @product_dirs;
			foreach my $product (@$produces) {
				push @product_dirs, dropslash($product);
			}

			# move any existing tarball to backup
			if ( -f $tarball_out ) {
				rename $tarball_out, $tarball_out.".bak";
			}

			# create the tarball
			my $cwd = getcwd();
			$self->debug("in ".$self->get_name." stage before tar; pid=$$ cwd=$cwd product_dirs="
				.join(" ", @product_dirs));
			# ignore tar exit code 1 - appears to be unavoidable and meaningless when building on an overlayfs
			my $nonzero = sub { my $ret=shift; if ($ret>1) {croak "tar exited with code $ret";}};
			$cb->cmd({name => "tar", nonzero => $nonzero}, "/usr/bin/tar", "--create", "--bzip2",
				"--preserve-permissions", "--sparse", "--file=".$tarball_out, "--directory=".$self->get_mnt, @product_dirs);
		} else {
			croak "product: stage->consumes was set but not an array ref";
		}
	}
	return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Container::Buildah::Stage - object used by Container::Buildah to track a stage of a multi-stage container build

=head1 VERSION

version 0.2.1

=head1 SYNOPSIS

	# Container::Buildah:Stage objects are created only by Container::Buildah
	# It passes a separate instance to each stage function
	sub stage_runtime
	{
		my $stage = shift;
		$stage->run( [qw(/sbin/apk --update upgrade)] );
		$stage->add( { dest => "/opt/swpkg" }, "tarball.tar.xz" );
		$stage->config({
			env => ["SWPKG_LOG=-g"],
			volume => [qw(/var/cache/swpkg)],
			port => ["8881"],
			entrypoint => "/opt/swpkg/entrypoint.sh",
		});
	}

=head1 DESCRIPTION

B<Container::Buildah:Stage> objects are created and used by B<Container::Buildah>.
These are passed to the callback function for each build-stage container.

The class contains methods which are wrappers for the buildah subcommands that require a container name parameter
on the command line.
However, the container name is within the object.
So it is not passed as a separate parameter to these methods.

Each instance contains the configuration information for that stage of the build.

B<Container::Buildah::Stage> automatically adds the I<--add-history> option so that each action will be recorded
as part of the OCI container build history.

=head1 METHODS

=head2 new

instantiates a B<Container::Buildah:Stage> object.
This method is private and may only be called by B<Container::Buildah>.

=head2 status

prints a list of strings to STDOUT

=head2 debug

Prints a list of strings to STDERR, if debugging is at the specified level.
This is a wrapper around the Container::Buildah::debug() method, which adds a label parameter with the container name.

=head2 container_name

=head2 add

=head2 commit

=head2 config

=head2 copy

=head2 run ( {option => value, ...}, [command, arg, ...] | [[command, arg, ...], ...] )

The option parameter is a hash reference with command-line options for buildah-run.
For options with shortcut aliases, only the long form is recognized here in order to avoid duplication.

The command parameter can be an array of strings for one command, or array of arrays of strings for multiple commands.
This applies the same command-line arguments to each command it runs.

=head1 FUNCTIONS

=head2 stage_config

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
