package App::LXC::Container::Data::common;

# Author, Copyright and License: see end of file

=head1 NAME

App::LXC::Container::Data::common - define common configuration data

=head1 SYNOPSIS

    # This module should only be used by OS-specific classes deriving from
    # it!

=head1 ABSTRACT

This module provides common configuration data.

=head1 DESCRIPTION

see L<App::LXC::Container::Data>

=head1 METHODS

=cut

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

use Cwd 'abs_path';

our $VERSION = '0.26';

use App::LXC::Container::Texts;

#########################################################################

=head1 EXPORT

Nothing is exported as access should only be done using the singleton
object.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw();

my $singleton = undef;		# App::LXC::Container::Data::*'s singleton!

#########################################################################
#########################################################################

=head1 METHODS

(alphabetically and case-insensitive except for constructor)

=cut

#########################################################################

=head2 B<new> - constructor

simplest standard constructor for a singleton

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# LXC default configuration read for default network configuration; this is
# only variable for the unit tests:
our $_system_default = '/etc/lxc/default.conf';

sub new($)
{
    unless (defined $singleton)
    {
	local $_ = shift;
	$singleton =
	{
	 SYSTEM_COMMON => '/usr/share/lxc/config/common.conf',
	 SYSTEM_DEFAULT => $_system_default,
	};
	bless $singleton, $_;
    }
    return $singleton;
}

#########################################################################

=head2 B<content_audio_packages> - return package configuration for audio

    internal object-oriented implementation of the function
    L<App::LXC::Container::Data::content_audio_packages>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub content_audio_packages($)
{
    _check_singleton(shift);
    my @output =
	('# list of mandatory packages needed for audio',
	 '# See 30-PKG-default.packages for more explanations.');
    local $_;
    foreach (qw(pactl))
    {
	my $exec = App::LXC::Container::Data::find_executable($_);
	if ($exec)
	{
	    my $pkg = App::LXC::Container::Data::package_of($exec);
	    push @output, $pkg  if  $pkg;
	}
    }
    return @output;
}

#########################################################################

=head2 B<content_device_default> - return default device configuration

    internal object-oriented implementation of the function
    L<App::LXC::Container::Data::content_device_default>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub content_device_default($)
{
    my $self = _check_singleton(shift);
    my @output = ('# changes to ' . $self->{SYSTEM_COMMON} . ':',
		  '',
		  '# lxc.autodev = 1	# The default should be sufficient!',
		  'lxc.pty.max = 8',
		  'lxc.mount.auto = cgroup:ro proc:mixed sys:ro');
    return @output
}

#########################################################################

=head2 B<content_default_filter> - return default filter

    internal object-oriented implementation of the function
    L<App::LXC::Container::Data::content_default_filter>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub content_default_filter($)
{
    use constant POSSIBLE_LINKS =>
	qw(/bin /lib /lib32 /lib64 /libx32 /libx64 /sbin);

    _check_singleton(shift);
    my @head =
	('# The filter contains paths that are always ignored (excluded) when',
	 '# considering mount-points derived from packages.  But there are',
	 '# still some specials possible, the paths may be followed (after some',
	 '# white-spaces) by one of the following keywords:',
	 '#	copy	path (usually a symbolic link) is simply copied',
	 '#	empty	creates empty file or directory for path',
	 '#	ignore	path is completely ignored (never creates mount-point)',
	 '#	nomerge	sub-directories of this path are never merged into it',
	 '',
	 '# common:');
    my @output =
      ('/boot				ignore',
       '/dev				ignore',
       '/home				nomerge',
       '/proc				ignore',
       '/sys				ignore',
       '/usr				nomerge',
       '/usr/games			nomerge',
       '/usr/include			nomerge',
       '/usr/lib			nomerge',
       '/usr/share			nomerge',
       '/usr/share/doc			nomerge',
       '/usr/share/dpkg			ignore',
       '/usr/share/info			nomerge',
       '/usr/share/lintian/overrides	ignore',
       '/usr/share/man			ignore',
       '/usr/share/misc/magic.mgc	ignore',
       '/usr/src			nomerge',
       '/var				nomerge',
       '/var/backups			ignore',
       '/var/cache			nomerge',
       # Note that /var/lib would break the start of a container due to
       # /var/lib/lxc* behaving unexpectedly:
       '/var/lib			nomerge',
       '/var/lib/dpkg			ignore',
       '/var/log			empty',
       '/var/spool			nomerge');
    local $_;
    foreach (POSSIBLE_LINKS)
    {	push @output, "$_\t\t\t\tcopy"  if  -l $_;   }
    return (@head, sort @output);
}

#########################################################################

=head2 B<content_default_mounts> - return default mount configuration

    internal object-oriented implementation of the function
    L<App::LXC::Container::Data::content_default_mounts>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub content_default_mounts($)
{
    _check_singleton(shift);
    my @output =
	('# Some notes to the list of default mounts (mounts that are needed in',
	 '# every application container):',
	 '#',
	 '# 1. Default mounts are read-only bind mounts.',
	 '# 2. Other mount options must be specified explicitly in field 2.',
	 '# 3. Special filesystems must be specified explicitly in field 3.',
	 '#',
	 '# In addition to directories (for mount-points) this list may also',
	 '# contain symbolic links, that are simply copied to the created',
	 '# configuration.',
	 '',
	 '# common:');
    local $_;
    foreach
      ('/bin',
       '/dev/shm	create=dir,rw			tmpfs',
       # the next 3 are needed by su:
       '/etc/login.defs',
       '/etc/pam.d',
       '/etc/security',
       '/lib',
       '/root		create=dir,rw,mode=700		tmpfs',
       '/sbin',
       # a shared and writable /tmp and extra unshared /usr/tmp and /var/tmp:
       '/tmp		create=dir,rw,bind',
       '/usr/tmp	create=dir,rw			tmpfs',
       '/var/tmp	create=dir,rw			tmpfs',
      )
    {
	(my $entry = $_) =~ s/\s+.*//;
	next  if  -l $entry;
	next  unless  -d $entry  or  -f $entry;
	push @output, abs_path($_);
    }
    return @output;
}

#########################################################################

=head2 B<content_default_packages> - return default packages

    internal object-oriented implementation of the function
    L<App::LXC::Container::Data::content_default_packages>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub content_default_packages($)
{
    _check_singleton(shift);
    local $_;
    my @paths = ('/bin/sh');
    foreach (qw(ldd ls su))
    {
	my $exec = App::LXC::Container::Data::find_executable($_);
	$exec  or  fatal('mandatory_package__1_missing', $_);
	push @paths, $exec;
    }
    my %packages = ();
    foreach (@paths)
    {
	$_ = App::LXC::Container::Data::package_of($_);
	$_  and  $packages{$_} = 1;
    }
    my @output =
	('# list of mandatory packages that are needed in every',
	 '# application container:',
	 '#',
	 '# Their dependencies will lead to a list of additionally needed',
	 '# mount-points.',
	 sort keys %packages);
    return @output;
}

#########################################################################

=head2 B<content_network_default> - return default network configuration

    internal object-oriented implementation of the function
    L<App::LXC::Container::Data::content_network_default>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub content_network_default($)
{
    my $self = _check_singleton(shift);
    my $sys_default = $self->{SYSTEM_DEFAULT};
    open my $conf, '<', $sys_default
	or  fatal 'can_t_open__1__2', $sys_default, $!;
    my $nr = undef;
    my %net = (type => 'veth',
	       flags => 'up',
	       link => 'lxcbr0',
	       'ipv4.address' => '10.0.3.$N/24',
	       hwaddr => '00:16:3e:xx:xx:xx');
    my @keys = qw(type flags link name ipv4.address hwaddr);
    local $_;
    while (<$conf>)
    {
	m/^\s*lxc\.net\.([0-9]+)\.([.\w]+)\s*=\s*(\S+)($|\s)/  or  next;
	$nr = $1;
	$net{$2} = $3;
    }
    close $conf;
    defined $nr  or  $nr = 0;
    defined $net{name}  or  $net{name} = 'eth' . $nr;
    my @output = ('# initial configuration derived from ' . $sys_default . ':',
		  '');
    # All keys are defined: 5 have defaults and name gets one if undefined.
    foreach (@keys)
    {
	my $key = 'lxc.net.' . $nr . '.' . $_;
	push @output, $key . ' = ' . $net{$_};
    }
    return @output
}

#########################################################################

=head2 B<content_network_mounts> - return mount configuration for NETWORK

    internal object-oriented implementation of the function
    L<App::LXC::Container::Data::content_network_mounts>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub content_network_mounts($)
{
    _check_singleton(shift);
    my @output =
	('# This is an additional mount configuration file for applications with',
	 '# network access.  See 40-MNT-default.mounts for more explanations.',
	 '',
	 '# network:',
	 '/etc/ssl/certs',
	 '/usr/lib/ssl',
	 '/usr/share/ca-certificates',
	 '/usr/share/ssl-cert');
    return @output
}

#########################################################################

=head2 B<content_network_packages> - return mount configuration for NETWORK

    internal object-oriented implementation of the function
    L<App::LXC::Container::Data::content_network_packages>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub content_network_packages($)
{
    _check_singleton(shift);
    my @output =
	('# This is an additional packages needed for network access.',
	 '# See 30-PKG-default.packages for more explanations.');
    local $_;
    foreach (qw(ip))
    {
	my $exec = App::LXC::Container::Data::find_executable($_);
	if ($exec)
	{
	    my $pkg = App::LXC::Container::Data::package_of($exec);
	    push @output, $pkg  if  $pkg;
	}
    }
    return @output;
}

#########################################################################

=head2 B<content_x11_mounts> - return mount configuration for X11

    internal object-oriented implementation of the function
    L<App::LXC::Container::Data::content_x11_mounts>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub content_x11_mounts($)
{
    _check_singleton(shift);
    my @output =
      ('# This is an additional mount configuration file for X11 applications.',
       '# See 40-MNT-default.mounts for more explanations.',
       '',
       '# common:',
       '/dev/dri	create=dir,rw,bind,optional',
       '/usr/share/icons',
       '/usr/share/mime',
       '/usr/share/pixmaps',
       '/var/cache/fontconfig',
       '/var/lib/dbus');
    return @output
}

#########################################################################

=head2 B<content_x11_packages> - return package configuration for X11

    internal object-oriented implementation of the function
    L<App::LXC::Container::Data::content_x11_packages>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub content_x11_packages($)
{
    _check_singleton(shift);
    my @output =
	('# list of mandatory packages needed for X11',
	 '# See 30-PKG-default.packages for more explanations.',
	 'fontconfig-config');
    return @output;
}

#########################################################################

=head2 depends_on - find package of file

    internal object-oriented implementation of the function
    L<App::LXC::Container::Data::depends_on>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub depends_on($$$)
{
    my $self = _check_singleton(shift);
}

#########################################################################

=head2 package_of - find package of file

    internal object-oriented implementation of the function
    L<App::LXC::Container::Data::package_of>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub package_of($$)
{
    _check_singleton(shift);
    my ($file) = @_;
    -f $file  or  fatal 'internal_error__1', 'not a file: ' . $file;
}

#########################################################################

=head2 paths_of - find package of file

    internal object-oriented implementation of the function
    L<App::LXC::Container::Data::paths_of>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub paths_of($$)
{
    _check_singleton(shift);
}

#########################################################################

=head2 regular_users - return list of regular users

    internal object-oriented implementation of the function
    L<App::LXC::Container::Data::regular_users>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub regular_users($)
{
    _check_singleton(shift);
    use constant PWD => '/etc/passwd';
    my @users = ();
    my $pwd;
    # Here I prefer to keep the PWD path hard-coded and not mockable!
    # uncoverable branch false
    unless (open $pwd, '<', PWD)
    {	error 'can_t_open__1__2', PWD, $!;   }	# uncoverable statement
    else
    {
	my $re_user = qr'[-a-z_A-Z.0-9]+';
	local $_;
	while (<$pwd>)
	{
	    m|^($re_user):[^:]*:([^:]*):(?:[^:]*:){2}/home(?:$re_user)?|o
		and  push @users, $2 . ':' . $1;
	}
	close $pwd;
    }
    return @users;
}

#########################################################################
#########################################################################

=head1 INTRNAL METHODS

The following methods may only be used internally:

=cut

#########################################################################

=head2 B<_check_singleton> - check 1st parameter to be reference to singleton

    my $his = _check_singleton(shift);

=head3 parameters:

    $self               should be reference to singleton

=head3 description:

Check that the passed parameter is the reference to the singleton and abort
the whole script otherwise.

=head3 returns:

reference to singleton

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _check_singleton($)
{
    my $self = shift;
    $self == $singleton
	or  fatal 'wrong_singleton__1__2', ref($self), ref($singleton);
    return $self;
}

1;

#########################################################################
#########################################################################

=head1 SEE ALSO

C<L<App::LXC::Container::Data>>

=head1 LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

=head1 AUTHOR

Thomas Dorner E<lt>dorner (at) cpan (dot) orgE<gt>

=cut
