package App::LXC::Container::Data;

# Author, Copyright and License: see end of file

=head1 NAME

App::LXC::Container::Data - provide OS-specific data for L<App::LXC::Container>

=head1 SYNOPSIS

    # This module should never be used directly!
    # It is used indirectly via the following:
    use App::LXC::Container;

=head1 ABSTRACT

This module provides the general and OS-specific configuration data (meaning
data specific to a subset of different Linux distributions) used by the main
package L<App::LXC::Container>.  This can be both static data (like the
basic LXC network configuration) as well as dynamic data (like the list of
files of installed software packages).

=head1 DESCRIPTION

The documentation of this module is only intended for developers of the
package itself.  Data is provided using an object-oriented approach:
Everything that behaves identically across all supported Linux distributions
is defined in the module C<Data::common>.  This is included by a module for
a basic distribution, e.g. the module C<Data::Debian>.  Those may extend,
modify or overwrite the common configuration.  Additional levels may be
added by derived Linux distributions, e.g. with the module C<Data::Ubuntu>.
C<Data.pm> itself then maps this internal OO-design into a functional one
hiding the internal singleton object.

=head2 Development hint

During development everything not already clearly OS-specific is put into
the common module first.  When support for another distribution is added,
the configuration is migrated into the appropriate OS-specific module(s).

=cut

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

use Cwd 'abs_path';

our $VERSION = '0.27';

use App::LXC::Container::Texts;

#########################################################################

=head1 EXPORT

All access functions are exported by default as that's the point of this
module.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(groups_of
		 initial_network_list
		 content_audio_packages
		 content_device_default
		 content_default_filter
		 content_default_mounts
		 content_default_packages
		 content_network_default
		 content_network_mounts
		 content_network_packages
		 content_x11_mounts
		 content_x11_packages
		 depends_on
		 package_of
		 paths_of
		 regular_users
	       );
# dependencies_of
	# TODO: Where do we get the network configuration???

#########################################################################
#########################################################################

=head1 FUNCTIONS (general)


The Data module provides the following general functions (alphabetically,
case-insensitive):

=cut

#########################################################################

=head2 find_executable - find executable in PATH

    $dir = find_executable($exec);

=head3 parameters:

    $exec               executable to search for (must be a base-name)

=head3 description:

This function searches for an executable in the standard search path (as
defined by the environment variable C<PATH>) and returns the absolute path
of the first one found.  Note that only absolute paths are checked.  Also
note that the executable must be indeed executable for the current user.

=head3 returns:

    absolute path to the executable, C<undef> if not found

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub find_executable($)
{
    my ($exec) = @_;
    $exec =~ m|/|
	and  fatal 'internal_error__1', $exec . ' may not contain directory';
    local $_;
    foreach (split /:/, $ENV{PATH})
    {
	s|/+$||;
	m|^/.+|
	    and  -d $_
	    and  -f $_ . '/' . $exec
	    and  -x $_ . '/' . $exec
	    and  return $_ . '/' . $exec;
    }
    return undef;
}

#########################################################################

=head2 groups_of - get groups of account

    @groups = groups_of($user);

=head3 parameters:

    $user               account of user

=head3 description:

This function returns the list of all groups a user belongs to.

=head3 returns:

    list of groups, should never be empty

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub groups_of($)
{
    my ($user) = @_;
    open my $id, '-|', 'id', '--groups', $user
	or  fatal 'can_t_open__1__2', 'id --groups ' . $user, $!;
    my $groups = join(' ', <$id>);
    close $id;
    return split /\s+/, $groups;
}

#########################################################################

=head2 B<initial_network_list> - return initial list of networks

    @output = initial_network_list();

=head3 description:

This function returns the initial list of containers using a network.

=head3 returns:

hard-coded header of network list

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub initial_network_list()
{
    my @output =
	('# list of all containers using a network (NUMBER:CONTAINER):',
	 '',
	 '# 1 is the LXC bridge!',
	 '2:local-network',
	 '3:network');
    return @output;
}

#########################################################################
#########################################################################

=head1 FUNCTIONS (OS-specific)

(We don't use general dynamic function as we want to add some minimal
documentation for each one anyway and fail cleanly in case of missing ones.
In addition this makes maintenance easier.)

The Data module provides the following OS-specific functions
(alphabetically, case-insensitive):

=cut

#########################################################################

=head2 B<content_audio_packages> - return package configuration for audio

    @output = content_audio_packages();

=head3 description:

This function returns the additional package configuration needed to support
audio within an application container.  The content depends on the
distribution used.

=head3 returns:

array of configuration lines

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub content_audio_packages()
{
    local $_ = _singleton();
    return $_->content_audio_packages();
}

#########################################################################

=head2 B<content_device_default> - return default device configuration

    @output = content_device_default();

=head3 description:

This function returns the basic device configuration for the application
containers (C<lxc.> variables configuring the setup of the directory
C</dev>).

=head3 returns:

array of configuration lines

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub content_device_default()
{
    local $_ = _singleton();
    return $_->content_device_default();
}

#########################################################################

=head2 B<content_default_filter> - return default filter

    @output = content_default_filter();

=head3 description:

This function returns the default filter of directories that are never
automatically derived from packages.  The content depends on the
distribution used.

=head3 returns:

array of configuration lines

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub content_default_filter()
{
    local $_ = _singleton();
    return $_->content_default_filter();
}

#########################################################################

=head2 B<content_default_mounts> - return default mount configuration

    @output = content_default_mounts();

=head3 description:

This function returns the minimal mount configuration for the application
containers.  The content depends on the distribution used.

=head3 returns:

array of configuration lines

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub content_default_mounts()
{
    local $_ = _singleton();
    return $_->content_default_mounts();
}

#########################################################################

=head2 B<content_default_packages> - return default packages

    @output = content_default_packages();

=head3 description:

This function returns the minimal list of packages that are always needed
for application containers.  The content depends on the distribution used.

=head3 returns:

array of configuration lines

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub content_default_packages()
{
    local $_ = _singleton();
    return $_->content_default_packages();
}

#########################################################################

=head2 B<content_network_default> - return default network configuration

    @output = content_network_default();

=head3 description:

This function returns the basic network configuration for the application
containers (C<lxc.net.0.*>).

=head3 returns:

array of configuration lines

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub content_network_default()
{
    local $_ = _singleton();
    return $_->content_network_default();
}

#########################################################################

=head2 B<content_network_mounts> - return mount configuration for network

    @output = content_network_mounts();

=head3 description:

This function returns the additional mount configuration needed to run
applications having network access within the application container.  The
content depends on the distribution used.

=head3 returns:

array of configuration lines

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub content_network_mounts()
{
    local $_ = _singleton();
    return $_->content_network_mounts();
}

#########################################################################

=head2 B<content_network_packages> - return package configuration for network

    @output = content_network_packages();

=head3 description:

This function returns the additional package configuration needed to run
applications having network access within the application container.  The
content depends on the distribution used.

=head3 returns:

array of configuration lines

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub content_network_packages()
{
    local $_ = _singleton();
    return $_->content_network_packages();
}

#########################################################################

=head2 B<content_x11_mounts> - return mount configuration for X11

    @output = content_x11_mounts();

=head3 description:

This function returns the additional mount configuration needed run X11
applications within the application container.  The content depends on the
distribution used.

=head3 returns:

array of configuration lines

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub content_x11_mounts()
{
    local $_ = _singleton();
    return $_->content_x11_mounts();
}

#########################################################################

=head2 B<content_x11_packages> - return mount configuration for X11

    @output = content_x11_packages();

=head3 description:

This function returns the additional package configuration needed to support
X11 within an application container.  The content depends on the
distribution used.

=head3 returns:

array of configuration lines

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub content_x11_packages()
{
    local $_ = _singleton();
    return $_->content_x11_packages();
}

#########################################################################

=head2 depends_on - find installed dependencies of package

    @packages = depends_on($package, $include);

=head3 parameters:

    $package            name of dependent package
    $include            types of dependencies to be used

=head3 description:

This function returns all installed dependencies of the given package (all
packages that it depends on).  This always includes mandatory dependencies.
With a positive 2nd parameter recommended dependencies are included as well.
Finally with a 2nd parameter greater than 1 optional (suggested)
dependencies are also included.

Note that further calls for the same package will always return an empty
list for performance reasons.  The calling will not terminate if this is
changed.

=head3 returns:

    all prerequisites of given package

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub depends_on($$)
{
    my ($package, $include) = @_;
    my $os_object = _singleton();
    return $os_object->depends_on($package, $include);
}

#########################################################################

=head2 package_of - find package of file

    $package = package_of($file);

=head3 parameters:

    $file               absolute path to file to search for

=head3 description:

This function searches for the given file in all installed packages and
returns the first one containing it.

=head3 returns:

    name of first package containing given file, C<undef> if not found

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub package_of($)
{
    my ($file) = @_;
    my $os_object = _singleton();
    $file = abs_path($file);
    # 1. try direct path:
    my $package = $os_object->package_of($file);
    # 2. try existing symbolic links between / and /usr:
    unless ($package)
    {
	# Due to abs_path above and variant distributions the branches and
	# conditions here are not completely coverable:
	local $_;
	if ($file =~ m|^/usr/|)
	{
	    $_ = $file;
	    s|^/usr(/[^/]+)(/.*)$|$1|;
	    my $alt = $1 . $2;
	    # uncoverable branch false
	    # uncoverable condition left
	    # uncoverable condition right
	    -l  and  readlink =~ m|^/?usr$_|
		and  $package = $os_object->package_of($alt);
	}
	else
	{
	    $_ = '/usr' . $file;
	    # uncoverable branch true
	    # uncoverable condition right
	    # uncoverable condition false
	    -e  and  abs_path($_) eq $file
		and  $package = $os_object->package_of($_);
	}
    }
    return $package;
}

#########################################################################

=head2 paths_of - get list of paths of package

    @paths = paths_of($package);

=head3 parameters:

    $package            name of package

=head3 description:

This function returns a list of all absolute paths (files and maybe
directories) installed by the given package.

=head3 returns:

    list of absolute paths

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub paths_of($)
{
    my ($package) = @_;
    my $os_object = _singleton();
    return $os_object->paths_of($package);
}

#########################################################################

=head2 regular_users - return list of regular users

    @users = regular_users();

=head3 description:

This function returns a list of all users on the system having a home
directory beneath a path beginning with /home.

=head3 returns:

    list of all regular users

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub regular_users()
{
    my $os_object = _singleton();
    return $os_object->regular_users();
}

#########################################################################
#########################################################################

=head1 INTRNAL FUNCTIONS

The following functions may only be used internally:

=cut

#########################################################################

=head2 B<_singleton> - return OS-specific singleton object

    $_ = _singleton();

=head3 description:

This function returns the OS-specific singleton object.  If the object does
not yet exist, the function checks the running OS by checking the variables
C<ID> and C<ID_LIKE> of the file C</etc/os-release>.  It then loads the
matching internal data module (C<Data/OS.pm>) providing the appropriate
configuration.

=head3 returns:

OS-specific singleton

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

our $_os_release = '/etc/os-release';	# only variable for unit tests

BEGIN {				# uncoverable statement
    my $os_object = undef;
    # list of OS aliases:
    my %alias = (Unittest => 'Debian');

    sub _singleton()
    {
	unless (defined $os_object)
	{
	    my ($id, $like, $osr) = ('', '');
	    open $osr, '<', $_os_release
		or  fatal 'can_t_open__1__2', $_os_release, $!;
	    local $_;
	    while (<$osr>)
	    {
		if (m/^ID\s*=\s*["']?([-a-z]+)["']?\s*$/)
		{   $id = $1;   }
		elsif (m/^ID_LIKE\s*=\s*["']?([-a-z]+)["']?\s*$/)
		{   $like = $1;   }
	    }
	    close $osr;
	    $_ = $id ? $id : $like;
	    $_  or  fatal 'can_t_determine_os';
	    $_ = ucfirst(lc($_));
	    defined $alias{$_}  and  $_ = $alias{$_};
	    my $os = $_;
	    s/-//g;
	    $_ = __PACKAGE__ . '::' . $_;
	    debug(2, __PACKAGE__, "::_singleton:\t", 'require ', $_);
	    unless (eval "require $_")
	    {
		# uncoverable branch false
		$@  and  error 'aborting_after_error__1', $@;
		fatal 'unknown_os__1', $os;
	    }
	    $_->import;
	    $os_object = $_->new();
	    $os_object->{OS} = $os;
	}
	return $os_object;
    }
}

1;

#########################################################################
#########################################################################

=head1 KNOWN BUGS

The current default configuration should work for Debian and probably also
for Ubuntu.  All other systems most likely require adaptions.  Feedback for
those is greatly appreciated!

=head1 SEE ALSO

C<L<App::LXC::Container>>

=head1 LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

=head1 AUTHOR

Thomas Dorner E<lt>dorner (at) cpan (dot) orgE<gt>

=cut
