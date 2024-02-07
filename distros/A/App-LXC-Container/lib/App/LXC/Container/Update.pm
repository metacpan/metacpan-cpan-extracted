package App::LXC::Container::Update;

# Author, Copyright and License: see end of file

=head1 NAME

App::LXC::Container::Update - update real LXC configuration

=head1 SYNOPSIS

    lxc-app-update <container>

=head1 ABSTRACT

This is the module used to (re-)create the real concrete configuration for
an LXC application container from one (or more) meta-configurations created
with L<App::LXC::Container::Create> (via its calling script
L<lxc-app-setup>).  It is called from L<lxc-app-update> via the main module
L<App::LXC::Container>.

=head1 DESCRIPTION

The module takes the default configuration for the operating system and
meta-configuration for one (or more) containers to create one long real
concrete configuration file for LXC itself.  Each section of this created
configuration file starts with a comment naming the corresponding (used)
meta-configuration file to make debugging and analysis easy.

=cut

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

use Cwd 'abs_path';
use File::Path qw(make_path remove_tree);
use File::stat;

our $VERSION = "0.41";

use App::LXC::Container::Data;
use App::LXC::Container::Mounts;
use App::LXC::Container::Texts;

#########################################################################
#
# internal constants and data:

use constant _ROOT_DIR_ =>  $ENV{HOME} . '/.lxc-configuration';

our @CARP_NOT = (substr(__PACKAGE__, 0, rindex(__PACKAGE__, "::")));

#########################################################################
#########################################################################

=head1 MAIN METHODS

The module defines the following main methods which are used by
L<App::LXC::Container>:

=cut

#########################################################################

=head2 B<new> - create configuration object for application container

    $configuration = App::LXC::Container::Update->new(@container);

=head3 parameters:

    @container          name of the container(s) to be configured

=head3 description:

This is the constructor for the object used to transform the
meta-configuration into the real one.  It reads all global configuration
files.  Note that the name of the last container is the one actually used
for the created configuration (as it's the one overwriting most other
configurations, see C<_parse> methods for details).

=head3 returns:

the configuration object for the application container

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub new($@)
{
    my $class = shift;
    $class eq __PACKAGE__  or  fatal 'bad_call_to__1', __PACKAGE__ . '->new';
    debug(1, __PACKAGE__, '::new("', join('", "', @_), '")');
    local $_;
    foreach (@_)
    {	m/^[A-Za-z][-A-Z_a-z.0-9]+$/  or  fatal 'bad_container_name';   }

    my %configuration = (audio => 0,
			 audio_from => '???',
			 containers => [ @_ ],
			 empty_files => [],
			 filter => {},
			 mount_entry => {},
			 mount_source => {},
			 mount_sources => [],
			 mounts_of_source => {},
			 name => $_[-1],
			 network => 0,
			 network_from => '???',
			 networks => {_bridge => 1},
			 next_network => 2,
			 package_source => {},
			 package_sources => [],
			 packages => [],
			 root_fs => '/var/lib/lxc',
			 specials => [],
			 user_ids => [],
			 users => {},
			 users_from => [],
			 x11 => 0,
			 x11_from => '???');
    my $self = bless \%configuration, $class;
    -e _ROOT_DIR_  or  fatal 'link_to_root_missing';
    -l _ROOT_DIR_  or  fatal '_1_is_not_a_symbolic_link' , _ROOT_DIR_;

    my $path = _ROOT_DIR_ . '/.networks.lst';
    open my $in, '<', $path  or  fatal 'can_t_open__1__2', $path, $!;
    while (<$in>)
    {
	next if m/^\s*(?:#.*)?$/;
	if (m/^(\d+):([-A-Z_a-z.0-9]+)$/)
	{   $self->{networks}{$2} = $1;   }
	else
	{   error 'ignoring_unknown_item_in__1__2', $path, $.;   }
    }
    close $in;
    foreach (sort {$a <=> $b} values %{$self->{networks}})
    {	$self->{next_network}++  if  $self->{next_network} == $_;   }

    $path = _ROOT_DIR_ . '/.root_fs';
    open $in, '<', $path  or  fatal 'can_t_open__1__2', $path, $!;
    while (<$in>)
    {
	if (m|^(/.*)$|)
	{   $self->{root_fs} = $1;   }
	else
	{   error 'ignoring_unknown_item_in__1__2', $path, $.;   }
    }
    close $in;

    return $self;
}

#########################################################################

=head2 B<main> - transform meta-configuration(s) into real one

    $configuration->main();

=head3 description:

This method reads the meta-configuration files for the operating system and
the specified container(s), analysis them and creates the real LXC
application container configuration.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub main($)
{
    my $self = shift;
    debug(1, __PACKAGE__, '::main($self)');
    local $_ = $self->{containers}[0];

    if (m/^(?:no-|local-)?network$/)
    {
	1 == @{$self->{containers}}  or  fatal 'special_container__1_alone', $_;
	m/^local-network$/  and  $self->{network} = 1;
	m/^network$/  and  $self->{network} = 2;
	$self->{audio_from} = $_;
	$self->{network_from} = $_;
	$self->{x11_from} = $_;
	$self->{containers} = [];
    }
    else
    {
	$self->_parse_master();
	@{$self->{user_ids}}  and  $self->_parse_users();
    }

    $self->_parse_packages();
    $self->_parse_mounts();
    $self->_parse_filter();
    $self->_parse_specials();

    m/^(no-|local-)?network$/  and  $self->{containers} = [ $_ ];

    $self->_write_lxc_configuration();
}

#########################################################################

=head2 B<network_number> - return current container's network number

    $network_number = $self->network_number();

=head3 description:

This method determines the network number (the last number of the IP v4
network address) of the current container.  If the number is not yet defined
the next free number is used and stored in the global network configuration
file.

=head3 returns:

current container's network number

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub network_number($)
{
    my $self = shift;
    debug(1, __PACKAGE__, '::network_number($self)');
    my $container = $self->{name};

    unless (defined $self->{networks}{$container})
    {
	local $_ = _ROOT_DIR_ . '/.networks.lst';
	open my $out, '>>', $_  or  fatal 'can_t_open__1__2', $_, $!;
	$self->{networks}{$container} = $self->{next_network}++;
	say $out $self->{networks}{$container}, ':', $container;
	close $out;
    }
    return $self->{networks}{$container};
}

#########################################################################
#########################################################################

=head1 HELPER METHODS

The following methods should not be used outside of this module itself:

=cut


#########################################################################

=head2 B<_create_mount_points> - create all mount points for path

    $self->_create_mount_points($mounts, '/');

=head3 parameters:

    $path               root path
    $mounts             App::LXC::Container::Mounts object

=head3 description:

This method (recursively) creates all (real) mount-points below (including)
the given path.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _create_mount_points($$$)
{
    my $self = shift;
    my ($mounts, $path, $out) = @_;
    debug(3, __PACKAGE__,
	  '::_create_mount_points::($self, "', join('", "', @_), '")');
    local $_ = $mounts->mount_point($path);
    if ($_ == EMPTY  or  $_ == EXPLICIT  or  $_ == IMPLICIT)
    {	$self->_make_lxc_path($path);   }
    elsif ($_ == COPY  or  $_ == IMPLICIT_LINK)
    {
	(my $parent = $path) =~ s|/[^/]+$||;
	$self->_make_lxc_path($parent);
	-d $path  and  not -l $path
	    and  fatal('internal_error__1', $path.' is directory in COPY');
	my $target = $self->{root_fs} . '/' . $self->{name} . $path;
	unless (-e $target  or  -l $target)
	{
	    system('cp', '--archive', $path, $target) == 0
		or  error('can_t_copy__1__2', $path, $?);
	}
    }
    $self->_create_mount_points($mounts, $_)
	foreach $mounts->sub_directories($path);
}

#########################################################################

=head2 B<_make_lxc_path> - create path in LXC directory tree of container

    $self->_make_lxc_path($path);

=head3 parameters:

    $path               the path to be created

=head3 description:

This method creates the given path below the containers LXC directory
(usually C</var/lib/lxc/CONTAINER>).  The path will have the same
permissions as the original one.  If the update is run by root, it will also
have the same ownership as the original one.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _make_lxc_path($$)
{
    my ($self, $path) = @_;
    debug(4, __PACKAGE__, '::_make_lxc_path($self, "', $path, '")');
    local $_ = $path . '/';
    s|(?<=.)/+$||;		# remove trailing / (just to be on the safe side)
    my @paths = ($_);
    unshift @paths, $_  while s|/+(?:[^/]+)$||  and  $_;

    my $root = $self->{root_fs} . '/' . $self->{name};
    -d $root  or  mkdir $root  or  fatal('can_t_create__1__2', $root, $!);
    foreach (@paths)
    {
	-e $_  or  fatal('_1_does_not_exist', $path);
	my $target = $root . $_;
	next if -e $target;
	my $stat = stat($_);
	my ($mode, $uid, $gid) = ($stat->mode, $stat->uid, $stat->gid);
	if (-d)
	{
	    $mode |= 0200;	# prevent blocking ourselves later on
	    if (-l)
	    {
		# links can be arbitrarily deep, so we use make_path on the
		# absolute path and hope for no clashes:
		$target = $root . abs_path($_);
		my $errors = [];
		make_path($target, {chmod => $mode, error => \$errors});
		$errors = join(' ', map { (values(%$_)) } @$errors);
		$errors eq ''
		    or  error('can_t_create__1__2', $target, $errors);
	    }
	    else
	    {
		mkdir $target  or  fatal('can_t_create__1__2', $target, $!);
	    }
	    # There are no standard files known to me meeting condition 2 or
	    # 4 (but not 1 and 3):
	    # uncoverable condition right
	    # uncoverable condition right count:3
	    $uid == 0  or  $gid == 0  or  $mode & 0001  or  $_ eq $path
		or  warning('_1_may_be_inaccessible', $_);
	}
	else
	{
	    open my $f, '>', $target
		or  fatal('can_t_create__1__2', $target, $!);
	    close $f;
	}
	if (-W $target)
	{
	    # ignoring errors as mounting overrules most problems anyway:
	    chmod $mode, $target;
	    chown $uid, $gid, $target;
	}
    }
}

#########################################################################

=head2 B<_parse_filter> - parse filter configuration file

    $self->_parse_filter();

=head3 description:

This method parses the applicable global special filter meta-configuration
files and those of the chosen container(s) into the configuration object.

Note that in the case of multiple containers the filter configurations are
merged and only the last occurrence of a filter is the one used in the
created LXC configuration file.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _parse_filter($)
{
    my $self = shift;
    debug(2, __PACKAGE__, '::_parse_filter($self)');

    my @special = ('50-default');
    foreach my $container (@special, @{$self->{containers}})
    {
	my $fname = substr($container, 0, 1) . substr($container, -1, 1)
	    . '-NOT-' . $container . '.filter';
	$container =~ m/^\d\d-/  and
	    $fname = (substr($container, 0, 2) . '-NOT-' .
		      substr($container, 3) . '.filter');
	my $path = _ROOT_DIR_ . '/conf/' . $fname;
	open my $in, '<', $path  or  fatal 'can_t_open__1__2', $path, $!;
	local $_;

	while (<$in>)
	{
	    next if m/^\s*(?:#|$)/;
	    s/\s*#.*$//;
	    if (m{^\s*(/\S+)\s+(copy|empty|ignore|nomerge)\s*$})
	    {	$self->{filter}{$1} = $2;   }
	    else
	    {	error 'ignoring_unknown_item_in__1__2', $path, $.;   }
	}
	close $in;
    }
}

#########################################################################

=head2 B<_parse_master> - parse master configuration file(s)

    $self->_parse_master();

=head3 description:

This method parses the master meta-configuration file(s) of the chosen
container(s) into the configuration object.

Note that in the case of multiple containers the master configurations are
merged and the least restrictive (e.g. full network access) overrides the
more restrictive ones (e.g. only local network) regardless of their
sequence.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _parse_master($)
{
    my $self = shift;
    debug(2, __PACKAGE__, '::_parse_master($self)');

    foreach my $container (@{$self->{containers}})
    {
	my $path = _ROOT_DIR_ . '/conf/'
	    . substr($container, 0, 1) . substr($container, -1, 1)
	    . '-CNF-' . $container . '.master';
	open my $in, '<', $path  or  fatal 'can_t_open__1__2', $path, $!;
	local $_;
	while (<$in>)
	{
	    next if m/^\s*(?:#|$)/;
	    if (m/^\s*network\s*=\s*([0-2])\s*(?:#|$)/)
	    {
		if ($self->{network} < $1)
		{
		    $self->{network} = $1;
		    $self->{network_from} = $container;
		}
	    }
	    elsif (m/^\s*x11\s*=\s*([0-1])\s*(?:#|$)/)
	    {
		if ($self->{x11} < $1)
		{
		    $self->{x11} = $1;
		    $self->{x11_from} = $container;
		}
	    }
	    elsif (m/^\s*audio\s*=\s*([0-1])\s*(?:#|$)/)
	    {
		if ($self->{audio} < $1)
		{
		    $self->{audio} = $1;
		    $self->{audio_from} = $container;
		}
	    }
	    elsif (m/^\s*users\s*=\s*(?:([-a-z_A-Z.0-9:, ]+)\s*)?(?:#|$)/)
	    {
		if ($1)
		{
		    foreach (split(' *, *', $1))
		    {
			my ($uid, $user) = split(':', $_);
			push @{$self->{user_ids}}, $uid;
			$self->{users}{$uid} = $user;
		    }
		    push @{$self->{users_from}}, $container;
		}
	    }
	    else
	    {	error 'ignoring_unknown_item_in__1__2', $path, $.;   }
	}
	close $in;
    }
    if ($self->{audio}  and  not  $self->{network})
    {	warning('audio_network_only');   }

}

#########################################################################

=head2 B<_parse_mounts> - parse mounts configuration file

    $self->_parse_mounts();

=head3 description:

This method parses the applicable global special mounts meta-configuration
files and those of the chosen container(s) into the configuration object.

Note that in the case of multiple containers the mounts configurations are
merged and only the last occurrence of a mount-point is the one used in the
created LXC configuration file.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _parse_mounts($)
{
    my $self = shift;
    debug(2, __PACKAGE__, '::_parse_mounts($self)');

    my @special = ('40-default');
    $self->{network}  and  push @special, '41-network';
    $self->{x11}  and  push @special, '61-X11';
    foreach my $container (@special, @{$self->{containers}})
    {
	my $source = substr($container, 0, 1) . substr($container, -1, 1)
	    . '-MNT-' . $container . '.mounts';
	$container =~ m/^\d\d-/  and
	    $source = (substr($container, 0, 2) . '-MNT-' .
		       substr($container, 3) . '.mounts');
	my $path = _ROOT_DIR_ . '/conf/' . $source;
	open my $in, '<', $path  or  fatal 'can_t_open__1__2', $path, $!;
	push @{$self->{mount_sources}}, $source;
	$self->{mounts_of_source}{$source} = [];
	local $_;
	while (<$in>)
	{
	    next if m/^\s*(?:#|$)/;
	    s/\s*#.*$//;
	    if (m|^\s*(/\S+)(?:\s+(\S+)(?:\s+(\S+)\s*)?)?$|)
	    {
		my ($path, $options, $fsys) = ($1, $2, $3);
		my $entry = ($fsys
			     ? $fsys . ' ' . substr($path, 1) . ' ' . $fsys
			     : $path . ' ' . substr($path, 1) . ' none');
		$entry .=
		    ' ' .
		    ($options
		     ? $options
		     : 'create=' . (-d $path ? 'dir' : 'file') . ',ro,bind')
		    . ' 0 0';
		$self->{mount_entry}{$path} = $entry;
		$self->{mount_source}{$path} = $source;
		push @{$self->{mounts_of_source}{$source}}, $path;
	    }
	    else
	    {	error 'ignoring_unknown_item_in__1__2', $path, $.;   }
	}
	close $in;
    }
}

#########################################################################

=head2 B<_parse_packages> - parse packages configuration file

    $self->_parse_packages();

=head3 description:

This method parses the applicable global packages meta-configuration files
and those of the chosen container(s) into the configuration object.

Note that in the case of multiple containers the packages configurations are
merged and only the first occurrence of a package is the one reported in the
comment of the created LXC configuration file.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _parse_packages($)
{
    my $self = shift;
    debug(2, __PACKAGE__, '::_parse_packages($self)');

    my @special = ('30-default');
    $self->{network}  and  push @special, '31-network';
    $self->{x11}  and  push @special, '60-X11';
    $self->{audio}  and  push @special, '70-audio';
    foreach my $container (@special, @{$self->{containers}})
    {
	my $source = substr($container, 0, 1) . substr($container, -1, 1)
	    . '-PKG-' . $container . '.packages';
	$container =~ m/^\d\d-/  and
	    $source = (substr($container, 0, 2) . '-PKG-' .
		       substr($container, 3) . '.packages');
	my $path = _ROOT_DIR_ . '/conf/' . $source;
	open my $in, '<', $path  or  fatal 'can_t_open__1__2', $path, $!;
	push @{$self->{package_sources}}, $source;
	local $_;
	while (<$in>)
	{
	    next if m/^\s*(?:#|$)/;
	    if (m/^\s*(\S+)\s*(?:#|$)/)
	    {
		unless (defined $self->{package_source}{$1})
		{
		    $self->{package_source}{$1} = $source;
		    push @{$self->{packages}}, $1;
		}
	    }
	    else
	    {	error 'ignoring_unknown_item_in__1__2', $path, $.;   }
	}
	close $in;
    }
}

#########################################################################

=head2 B<_parse_specials> - parse special configuration file

    $self->_parse_specials();

=head3 description:

This method parses the container's optional special configuration file(s)
into the configuration object.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _parse_specials($)
{
    my $self = shift;
    debug(2, __PACKAGE__, '::_parse_specials($self)');

    foreach my $container (@{$self->{containers}})
    {
	my $fname = substr($container, 0, 1) . substr($container, -1, 1)
	    . '-SPC-' . $container . '.special';
	my $path = _ROOT_DIR_ . '/conf/' . $fname;
	-f $path  or  next;
	open my $in, '<', $path  or  fatal 'can_t_open__1__2', $path, $!;
	local $_;

	while (<$in>)
	{
	    next if m/^\s*(?:#|$)/;
	    s/\s*#.*$//;
	    s/\r?\n$//;
	    push @{$self->{specials}}, $_;
	}
	close $in;
    }
}

#########################################################################

=head2 B<_parse_users> - add mounts for users' home directories

    $self->_parse_users();

=head3 description:

This method parses C</etc/passwd> to add the users' home directories to the
list of global mounts.

TODO: better move reading of passwd to new function ...::Data::users_homes

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _parse_users($)
{
    my $self = shift;
    debug(2, __PACKAGE__, '::_parse_users($self)');

    use constant PWD => '/etc/passwd';
    my $key = 'container users';
    push @{$self->{mount_sources}}, $key;
    $self->{mounts_of_source}{$key} = [];
    my $re_users =
	'^(?:' . join('|', values %{$self->{users}}) . '):.*:(/[^:]+):[^:]+$';
    # Normally this could never fail:
    # uncoverable branch true
    open my $pwd, '<', PWD  or  fatal 'can_t_open__1__2', PWD, $!;
    my @users = ();
    local $_;
    while (<$pwd>)
    {
	next unless m/$re_users/o;
	$self->{mount_entry}{$1} =
	    $1 . ' ' . substr($1, 1) . ' none create=dir,rw,bind';
	$self->{mount_source}{$1} = $key;
	push @{$self->{mounts_of_source}{$key}}, $1;
    }
    close $pwd;
}

#########################################################################

=head2 B<_write_lxc_configuration> - write LXC configuration file

    $self->_write_lxc_configuration();

=head3 description:

This method writes the parsed meta-configuration into the real concrete
LXC configuration file for the selected (command-line) application
container.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _write_lxc_configuration($)
{
    my $self = shift;
    debug(2, __PACKAGE__, '::_write_lxc_configuration($self)');

    use constant HEADER_1 => "\n#################### ";
    use constant HEADER_1s =>  '#################### ';
    use constant HEADER_2 =>  ' ####################';

    local $_;
    my $container = $self->{name};
    my $path = _ROOT_DIR_ . '/' . $container . '.conf';
    open my $out, '>', $path  or  fatal 'can_t_open__1__2', $path, $!;

    ################################
    # part 1 - global definitions:
    say $out '# container description created by ', __PACKAGE__;
    say($out
	'# MASTER: ',
	($self->{network} == 2 ? 'G' . $self->network_number() :
	 $self->{network} == 1 ? 'L' . $self->network_number() : 'N'),
	',', ($self->{x11} ? 'X' : '-'),
	',', ($self->{audio} ? 'A' : '-'));
    say $out 'lxc.uts.name = ' . $container;
    say $out 'lxc.rootfs.path = ' . $self->{root_fs} . '/' . $container;
    say $out 'lxc.rootfs.options = idmap=container';

    if ($self->{network})
    {
	say $out
	    HEADER_1, $self->{network_from}, ', 10-NET-default.conf', HEADER_2;
	$_ = _ROOT_DIR_ . '/conf/10-NET-default.conf';
	open my $in, '<', $_  or  fatal 'can_t_open__1__2', $_, $!;
	my $network_number = $self->network_number();
	while (<$in>)
	{
	    next if m/^\s*(?:#|$)/;
	    s|\.\$N/|.$network_number/|;
	    print $out $_;
	}
	close $in;
    }
    else
    {
	say $out HEADER_1, 'no network', HEADER_2;
	say $out 'lxc.net.0.type = empty';
    }

    say $out HEADER_1, '20-DEV-default.conf', HEADER_2;
    $_ = _ROOT_DIR_ . '/conf/20-DEV-default.conf';
    open my $in, '<', $_  or  fatal 'can_t_open__1__2', $_, $!;
    while (<$in>)
    {	print $out $_  unless  m/^\s*(?:#|$)/;   }
    close $in;

    my @users_from = @{$self->{users_from}};
    my %groups = ();
    if (@users_from)
    {
	# TODO: This is a workaround while su does not work with a mapped root:
	# uncoverable branch false
	unless (defined $self->{users}{root})
	{
	    push @{$self->{user_ids}}, 0;
	    $self->{users}{0} = 'root';
	}
	say $out HEADER_1, join(', ', @users_from), HEADER_2;
	my $uid = 0;
	foreach (sort {$a <=> $b} keys %{$self->{users}})
	{
	    say $out 'lxc.idmap = u ', $uid, ' ', 100000 + $uid, ' ', $_ - $uid
		if  $_ - $uid > 1;
	    my $user = $self->{users}{$_};
	    say $out '# ', $user, ':';
	    say $out 'lxc.idmap = u ', $_, ' ', $_, ' 1';
	    $uid = $_;
	    foreach (groups_of($uid))
	    {
		# There are no standard users with multiple groups:
		# uncoverable branch false
		defined $groups{$_}  or  $groups{$_} = '';
		$groups{$_} .= ' ' . $user;
	    }
	    $uid++;
	}
	say $out 'lxc.idmap = u ', $uid, ' ', 100000 + $uid, ' ', 65536 - $uid;
    }
    else
    {
	say $out HEADER_1, '-no privileged users-', HEADER_2;
	say $out 'lxc.idmap = u 0 100000 65536';
    }
    if (0 < keys(%groups))
    {
	my $gid = 0;
	foreach (sort {$a <=> $b} keys %groups)
	{
	    say $out 'lxc.idmap = g ', $gid, ' ', 100000 + $gid, ' ', $_ - $gid
		if  $_ - $gid > 1;
	    say $out '#', $groups{$_}, ':';
	    say $out 'lxc.idmap = g ', $_, ' ', $_, ' 1';
	    $gid = $_ + 1;
	}
	say $out 'lxc.idmap = g ', $gid, ' ', 100000 + $gid, ' ', 65536 - $gid;
    }
    else
    {   say $out 'lxc.idmap = g 0 100000 65536';   }

    ################################
    # part 2 - special configuration:
    if (@{$self->{specials}})
    {
	say $out HEADER_1, 'special configuration', HEADER_2;
	say $out $_ foreach @{$self->{specials}};
    }

    ################################
    # part 3 - explicit mounts:
    my $mounts = App::LXC::Container::Mounts->new();
    foreach my $source (@{$self->{mount_sources}})
    {
	say $out HEADER_1, $source, HEADER_2;
	foreach (@{$self->{mounts_of_source}{$source}})
	{
	    next unless $self->{mount_source}{$_} eq $source;
	    say $out 'lxc.mount.entry = ', $self->{mount_entry}{$_};
	    $mounts->mount_point($_, EXPLICIT);
	}
    }

    ################################
    # part 4a - implicit mounts (from packages) - determine prerequisites:
    print $out "\n";
    foreach my $source (@{$self->{package_sources}})
    {
	say $out HEADER_1s, $source, HEADER_2;
	foreach (sort keys %{$self->{package_source}})
	{
	    say $out '# ', $_
		if  $self->{package_source}{$_} eq $source;
	}
    }
    # We sort packages according to their reference count and put the user
    # selections at or near the end (by initialising them with a negative
    # reference count):
    my @packages = @{$self->{packages}};
    my %referenced_packages =
	map { ($_, ($self->{package_source}{$_} =~ m/^\d/) ? 0 : -2) }
	@packages;
    my $include = 0;		# TODO: Get initial value via interface!
    while (@packages)
    {
	my @add = ();
	foreach (@packages)
	{   push @add, depends_on($_, $include);   }
	@packages = ();
	$include = -1;
	foreach (@add)
	{
	    unless (defined $referenced_packages{$_})
	    {
		$referenced_packages{$_} = 0;
		push @packages, $_;
	    }
	    $referenced_packages{$_}++;
	}
    }
    @packages =
	sort { $referenced_packages{$b} <=> $referenced_packages{$a} }
	keys %referenced_packages;

    ################################
    # part 4b - implicit mounts (from packages) - prepare filters:
    my $header = 0;
    foreach my $key (sort keys %{$self->{filter}})
    {
	$_ = $self->{filter}{$key};
	if ($_ eq 'copy')
	{   $mounts->mount_point($key, COPY);   }
	elsif ($_ eq 'empty')
	{
	    if (-d $key)
	    {
		unless ($header)
		{
		    say $out HEADER_1, 'empty filters', HEADER_2;
		    $header = 1;
		}
		say($out
		    'lxc.mount.entry = tmpfs ', substr($key, 1),
		    ' tmpfs create=dir,rw 0 0');
		$mounts->mount_point($key, EMPTY);
	    }
	    else
	    {   push @{$self->{empty_files}}, $key;   }
	}
	elsif ($_ eq 'ignore')
	{   $mounts->mount_point($key, IGNORE);   }
	elsif ($_ eq 'nomerge')
	{   $mounts->mount_point($key, NO_MERGE);   }
	else
	{   fatal 'internal_error__1', 'bad filter value: ' . $_;   }
    }

    ################################
    # part 4c - implicit mounts (from packages) - gather and merge paths of
    # packages (while respecting the filters!):

    foreach my $package (@packages)
    {
	# gather paths of next package:
	foreach (paths_of($package))
	{
	    unless (-e)
	    {
		error('_1_does_not_exist', $_);
		next;
	    }
	    my $state = undef;
	    if (-l)
	    {
		$state = $mounts->mount_point($_);
		$mounts->mount_point($_, IMPLICIT_LINK)  if  $state == UNDEFINED;
		next;
	    }
	    next if -d;
	    $_ =  abs_path($_);		# resolve links in path!
	    $state = $mounts->mount_point($_);
	    if ($state == UNDEFINED)
	    {	$mounts->mount_point($_, IMPLICIT);   }
	}
	# TODO: tune heuristic, put into constant or make configurable:
	$mounts->merge_mount_points(100, 30, 4, 3);
    }

    ################################
    # part 4d - implicit mounts (from packages) - write configuration:
    say $out HEADER_1, 'mounts derived from above packages', HEADER_2;
    say $out $_  foreach  $mounts->implicit_mount_lines('/');

    ################################
    # part 5 - create all mount points:
    my $errors = [];
    $_ = $self->{root_fs} . '/' . $container;
    -d $_  and  remove_tree($_, {error => \$errors, safe => 1});
    $errors = join(' ', map { (values(%$_)) } @$errors);
    $errors eq ''  or  error('can_t_remove__1__2', $_, $errors);
    $self->_create_mount_points($mounts, '/');

    ################################
    # part 6 - create all empty files:
    foreach (@{$self->{empty_files}})
    {
	$_ = $self->{root_fs} . '/' . $container . $_;
	# As we just deleted the whole tree we can't create a test for a
	# failed empty file here:
	# uncoverable branch true
	open my $empty, '>', $_  or  fatal 'can_t_open__1__2', $_, $!;
	close $empty;
	chmod 0600, $_;
    }

    close $out;
}

#########################################################################

1;

#########################################################################
#########################################################################

=head1 SEE ALSO

man pages C<lxc.container.conf>, C<lxc> and C<lxcfs>

LXC documentation on L<https://linuxcontainers.org>

=head1 LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

=head1 AUTHOR

Thomas Dorner E<lt>dorner (at) cpan (dot) orgE<gt>

=head2 Contributors

none so far

=cut
