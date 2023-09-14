package App::LXC::Container::Run;

# Author, Copyright and License: see end of file

=head1 NAME

App::LXC::Container::Run - run real LXC configuration

=head1 SYNOPSIS

    lxc-app-run [{-u|--user} <user>] [{-d|--dir|--directory} <directory>] \
        <container> <command> <parameters>...

=head1 ABSTRACT

This is the module used to run a command inside of an LXC application
container previously created or updated with L<App::LXC::Container::Update>
(via its calling script L<lxc-app-update>).  It is called from
L<lxc-app-run> via the main module L<App::LXC::Container>.

=head1 DESCRIPTION

The module starts the specified container and runs the given command either
as the user specified with the C<--user> option or as the root account of
the container if no other user is given.  Note that the root account of the
container usually is restricted to the container, unless explicitly
configured otherwise (which usually is a bad idea).  Likewise any other user
inside of the container is also restricted unless it has been added to the
list of allowed users in the configuration (see L<lxc-app-setup> and its
main module L<App::LXC::Container::Setup>).  The C<--directory> option can
be used to set the initial working directory of the command.  The default
working directory is the root of the container (C</>).

=head2 root access

Note that starting an LXC application container via C<L<lxc-execute>>
(unfortunately) needs root privileges, e.g. to set-up the UID map.  Another
aspect is restricting network access of a container with only local access,
which needs to run C<L<nft>>.

FIXME: add example sudoers configuration

In addition the container currently can't map root to a safe ID if you have
other users than root added to the container.  The problem is that I've not
figured out to get C<su> working inside of a container with a mapped root
ID (e.g. C<lxc.idmap = u 0 100000 1>).

=head2 restrictions for command and parameters

As the script used to run the command needs some way of quoting the command
and its parameters the following restrictions apply:

=over

=item the command may not contain single quotes (C<'>)

=item parameters may not contain both single (C<'>) and double (C<">) quotes

=back

As a work-around for those restrictions put your command into an extra
script and add it to the container.

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

our $VERSION = "0.27";

use App::LXC::Container::Data;
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

    $configuration =
        App::LXC::Container::Run->new($container, $user, $dir, @command);

=head3 parameters:

    $container          name of the container to be run
    $user               name of the user running the command
    $dir                name of the start directory for the command
    @command            the command to be run itself

=head3 description:

This is the constructor for the object used to run the LXC application
container of the given name as the given user using the given command.  It
reads and checks the configuration, but does not yet run any external
programs.

=head3 returns:

the configuration object for the application container

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub new($$$$@)
{
    my $class = shift;
    $class eq __PACKAGE__  or  fatal 'bad_call_to__1', __PACKAGE__ . '->new';
    debug(1, __PACKAGE__, '::new("', join('", "', @_), '")');
    my $container = shift;
    my $user = shift;
    my $dir = shift;

    my %configuration = (audio => '-',
			 command => [@_],
			 dir => $dir,
			 gateway => '',
			 gids => [],
			 init => '/initialisation/script/is/undefined',
			 ip => '',
			 mounts => {},
			 name => $container,
			 network => 0,
			 network_type => 'N',
			 rc => _ROOT_DIR_ . '/' . $container . '.conf',
			 root => 'root/of/container/not/found',
			 running => 0,
			 uids => [],
			 user => $user,
			 x11 => '-');
    my $self = bless \%configuration, $class;
    -e _ROOT_DIR_  or  fatal 'link_to_root_missing';
    -l _ROOT_DIR_  or  fatal '_1_is_not_a_symbolic_link' , _ROOT_DIR_;

    open my $in, '<', $self->{rc}  or  fatal 'can_t_open__1__2', $self->{rc}, $!;
    my $found = 0;
    while (<$in>)
    {
	if (m/^\s*#\s*MASTER\s*:\s*([GLN])(\d+)?\s*,\s*([-X])\s*,\s*([-A])\s*$/)
	{
	    if ($1 ne 'N')
	    {
		defined $2  or  fatal 'bad_master__1', $1 . ',' . $3 . ',' . $4;
		$2 > 1  or  fatal 'bad_master__1', $1 . $2;
		$self->{network_type} = $1;
		$self->{network} = $2;
	    }
	    $self->{x11} = $3;
	    $self->{audio} = $4;
	    $found = 1;
	}
	elsif (m|^\s*lxc\.rootfs\.path\s*=\s*(/\S+)\s*$|)
	{
	    $_ = $self->{root} = abs_path($1);
	    -d $_  or  fatal 'missing_directory__1', $_;
	    m|^/\w+/|  or  fatal 'bad_directory__1', $_;
	    $self->{init} = $_ . '/lxc-run.sh';
	}
	elsif (m|^\s*lxc\.net\.0\.ipv4\.address\s*=\s*(\d[.0-9]+)/\d+\s*$|)
	{
	    $self->{ip} = $1;
	    $_ = $self->{network};
	    $self->{ip} =~ m/\.$_$/
		or  fatal 'bad_master__1', $self->{ip} . ' (!~ ' . $_ . '$)';
	    $_ = $self->{ip};
	    s/\.\d+$/.1/;
	    $self->{gateway} = $_;
	}
	elsif (m|^\s*lxc\.idmap\s*=\s*u\s+(\d+)\s+\1\s+1$|)
	{
	    push @{$self->{uids}}, $1  if  $1 > 0;
	}
	elsif (m|^\s*lxc\.idmap\s*=\s*g\s+(\d+)\s+\1\s+1$|)
	{
	    push @{$self->{gids}}, $1  if  $1 > 0;
	}
	elsif (m|^\s*lxc\.mount\.entry\s*=\s*(/\S+)\s|)
	{
	    $self->{mounts}{$1} = 1;
	}
    }
    close $in;
    $found == 1  or  fatal 'bad_master__1', '???';

    return $self;
}

#########################################################################

=head2 B<main> - run LXC application container

    $configuration->main();

=head3 description:

This method runs the container or attaches to it, if it's already running.
In addition it creates the container's start-up script C</lxc-run.sh>, if
one is needed.  It also sets up the C<L<nft>> packet filtering if a local
network is required.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub main($)
{
    my $self = shift;
    debug(1, __PACKAGE__, '::main($self)');
    $self->_check_running();
    $self->{network_type} eq 'L'  and  $self->_local_net();
    $self->_write_init_sh();
    # TODO: Do we need account files when only using root?
    # $self->{user} ne 'root'  and
    $self->_prepare_user();
    $self->_run();
}

#########################################################################
#########################################################################

=head1 HELPER METHODS

The following methods should not be used outside of this module itself:

=cut

#########################################################################

=head2 B<_check_running> - check if container is already running

    $self->_check_running();

=head3 description:

This method checks if the container is already running (and we just need to
attach to run a second application).

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _check_running($)
{
    my $self = shift;
    debug(2, __PACKAGE__, '::_check_running($self)');

    # check running containers:
    open my $lxcls, '-|', 'lxc-ls'
	or  fatal('call_failed__1__2', 'lxc-ls', $?);
    my $containers = join(' ', '', <$lxcls>, '');
    close $lxcls  or  fatal('call_failed__1__2', 'lxc-ls', $?);
    local $_ = $self->{name};
    $containers =~ m/(?:^|\s)$_(?:\s|$)/  and  $self->{running} = 1;
    debug(3, $_, ' is ', $self->{running} ? 'already' : 'not', ' running');
}

#########################################################################

=head2 B<_local_net> - check and set-up nft packet filtering

    $self->_local_net();

=head3 description:

This method checks the nft packet filtering of the host and adds the filter
for the local network, if it's not already in place.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _local_net($)
{
    my $self = shift;
    debug(2, __PACKAGE__, '::_local_net($self)');
    local $_;

    use constant NFT_LIST => (qw(nft list ruleset inet));
    use constant NFT_CHAIN => (qw(nft add chain inet lxc localfilter));
    use constant NFT_JUMP =>
	(qw(nft insert rule inet lxc forward jump localfilter));
    use constant NFT_IP =>
	(qw(nft add rule inet lxc localfilter ip saddr)); # $ip 'reject'

    # check current configuration:
    open my $nft, '-|', NFT_LIST
	or  fatal('nft_error__1__2', join(' ', NFT_LIST), $?);
    my $re_ip = $self->{ip};
    $re_ip =~ s/\./\./g;
    my ($mode, $has_chain, $has_jump, $has_ip, $chain) = (0, 0, 0, 0, '');
    while (<$nft>)
    {
	if (m/^\s*table\s+inet\s+lxc\b/)
	{   $mode = 1;   }
	elsif ($mode == 1)
	{
	    if (m/^\}$/)
	    {   $mode = 2;   }
	    elsif (m/^\s+chain\s+forward\b/)
	    {   $chain = 'F';   }
	    elsif (m/^\s+\}\s*$/)
	    {   $chain = '';   }
	    elsif (m/^\s+chain\s+localfilter\b/)
	    {   $chain = 'L';   $has_chain = 1;   }
	    elsif ($chain eq 'F'  and  m/^\s+jump\s+localfilter\s*$/)
	    {   $has_jump = 1;   }
	    elsif ($chain eq 'L'  and  m/^\s+ip\s+saddr\s+$re_ip\s+reject\s+/)
	    {   $has_ip = 1;   }
	}
    }
    debug(3, 'NFT: ', $has_chain ? 'chain' : '-', '/',
	  $has_jump ? 'jump' : '-', '/', $has_ip ? 'ip' : '-');
    close $nft
	or  fatal('nft_error__1__2', join(' ', NFT_LIST), $?);

    # update configuration, if necessary:
    unless ($has_chain)
    {
	debug(3, "adding chain 'localfilter' in nftables");
	system(NFT_CHAIN) == 0
	    or  fatal('nft_error__1__2', join(' ', NFT_CHAIN), $?);
    }
    unless ($has_jump)
    {
	debug(3, "adding jump to 'localfilter' in nftables");
	system(NFT_JUMP) == 0
	    or  fatal('nft_error__1__2', join(' ', NFT_JUMP), $?);
    }
    unless ($has_ip)
    {
	debug(3, 'adding IP address ', $self->{ip},
	      " to 'localfilter' in nftables");
	system(NFT_IP, $self->{ip}, 'reject') == 0
	    or  fatal('nft_error__1__2',
		      join(' ', NFT_IP, $self->{ip}, 'reject'), $?);
    }
}

#########################################################################

=head2 B<_prepare_user> - prepare selected user

    $self->_prepare_user();

=head3 description:

This method prepares the container to be able to switch to the selected user
by creating minimal C</etc/passwd> / C</etc/shadow> and C</etc/group> /
C</etc/gshadow> files for the user, unless the ones from the host are used.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

our $_root_etc = '/etc/';	# variable for unit tests only

sub _prepare_user($)
{
    my $self = shift;
    debug(2, __PACKAGE__, '::_prepare_user($self)');

    if ($self->{mounts}{'/etc'})
    {   debug(3, 'using user/groups from host (/etc)');   }
    else
    {
	use constant ACCOUNT_FILES => (qw(group gshadow passwd shadow));
	use constant ACCOUNT_FILES_STR => join(' ', ACCOUNT_FILES);
	local $_;
	my $mapped = 0;
	foreach (ACCOUNT_FILES)
	{   $self->{mounts}{'/etc/'.$_}  and  $mapped++;   }
	if ($mapped == 4)
	{   debug(3, 'using user/groups from host (/etc/<all 4 files>)');   }
	elsif ($mapped > 0)
	{   error('broken_user_mapping__1', ACCOUNT_FILES_STR);   }
	else
	{
	    my $lxc_etc = $self->{root} . '/etc/';
	    my $re_ids = $self->{user};
	    # TODO: Should we distinguish UIDs/GIDs?  For now we just simply
	    # add them all.  This has the charm that files of other users
	    # within the same group will be visible with their names in
	    # directory listings.  The disadvantage is making them known by
	    # name (but the password hashes are always safe):
	    foreach (@{$self->{uids}}, @{$self->{gids}})
	    {   $re_ids .= '|' . $_;   }
	    foreach (ACCOUNT_FILES)
	    {
		# remove first to be sure not to overwrite something linked:
		if (-f $lxc_etc . $_)
		{
		    unlink $lxc_etc . $_
			or  fatal 'can_t_remove__1__2', $lxc_etc . $_, $!;
		}
		open my $in, '<', $_root_etc . $_
		    or  fatal 'can_t_open__1__2', $_root_etc . $_, $!;
		open my $out, '>', $lxc_etc . $_
		    or  fatal 'can_t_open__1__2', $lxc_etc . $_, $!;
		while (<$in>)
		{
		    next unless m/(?:^|[:,])(?:$re_ids|root)(?:[:,]|$)/;
		    # If applicable, remove the encrypted password, as it's
		    # not needed inside of the container:
		    s/^([^:]+):([^!:*][^:*][^:]+):/$1:!:/;
		    print $out $_;
		}
		close $out;
		close $in;
	    }
	}
    }
}

#########################################################################

=head2 B<_run> - run command in container

    $self->_run();

=head3 description:

This method attaches to the container, if it's already running.  Otherwise
it starts it.  In either case it runs the previously (C<L<_write_init_sh>>)
created initialisation script C</lxc-run.sh> inside of it.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _run($)
{
    my $self = shift;
    debug(2, __PACKAGE__, '::_run($self)');

    # FIXME: exec instead of system when Devel::Cover supports it
    if ($self->{running})
    {
	debug(3, 'attaching LXC application container ', $self->{name});
	0 == system(
#	exec(
	     'lxc-attach', '--rcfile', $self->{rc},
	     '--name', $self->{name}, '--', '/lxc-run.sh')
	    or  fatal('call_failed__1__2', 'lxc-attach', $!);
    }
    else
    {
	debug(3, 'starting LXC application container ', $self->{name});
	0 == system(
#	exec(
	     'lxc-execute', '--rcfile', $self->{rc},
	     '--name', $self->{name}, '--', '/lxc-run.sh')
	    or  fatal('call_failed__1__2', 'lxc-execute', $!);
    }
}

#########################################################################

=head2 B<_write_init_sh> - write startup script for container

    $self->_write_init_sh();

=head3 description:

This method writes the startup script C</lxc-run.sh>.  It is used when the
container is started or attached to set up the initial configuration of the
container and to run the requested command (or the interactive shell
C</bin/sh>, if none is specified).

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub _write_init_sh($)
{
    my $self = shift;
    debug(2, __PACKAGE__, '::_write_init_sh($self)');

    use constant SHELL => '/bin/sh';
    my @todo = ('#!' . SHELL);

    if ($self->{running})
    {
	push @todo, '', '# PipeWire / PulseAudio:',
	    'export PULSE_SERVER=' . $self->{gateway}
	    if $self->{audio} eq 'A';
	if ($self->{x11} eq 'X'  and  defined $ENV{DISPLAY})
	{
	    push @todo, '', '# X11:', 'export DISPLAY=' . $ENV{DISPLAY};
	    push @todo, 'export XAUTHORITY=/.xauth/.Xauthority'
		if defined $ENV{XAUTHORITY};
	}
    }
    else
    {
	# network needs gateway and DNS:
	if ($self->{network_type} ne 'N')
	{
	    debug(3, 'gateway is ', $self->{gateway});
	    push @todo,
		'',
		'# set-up network via lxc bridge:',
		'gateway=' . $self->{gateway},
		# alternative way inside of container:
		#'gateway=$(ip route show protocol kernel)',
		#'gateway="${gateway%.*}.1"',
		#'gateway=${gateway##* }',
		'ip route add default via "$gateway"',
		'echo "nameserver $gateway" >/etc/resolv.conf';
	}

	# audio needs PipeWire / PulseAudio environment:
	if ($self->{audio} eq 'A')
	{
	    debug(3, 'pulse server is also ', $self->{gateway});
	    push @todo, '', '# PipeWire / PulseAudio:',
		'export PULSE_SERVER=' . $self->{gateway};
	}

	if ($self->{x11} eq 'X'  and  defined $ENV{DISPLAY})
	{
	    my $display = $ENV{DISPLAY};
	    debug(3, 'DISPLAY is ', $display);
	    push @todo, '', '# X11:', 'export DISPLAY=' . $display;
	    # We must pass the X11-authority for the correct display here:
	    if (defined $ENV{XAUTHORITY})
	    {
		# A writable directory is needed for the lock-file!
		my $xauth_dir = $self->{root} . '/.xauth';
		-d $xauth_dir
		    or  mkdir $xauth_dir, 0700
		    or  fatal('can_t_create__1__2', $xauth_dir, $!);
		my $xauth = $xauth_dir . '/.Xauthority';
		my @entries = `xauth list`;
		my $name = $self->{name};
		my $entry = undef;
		foreach (@entries)
		{
		    if (s|^[^/]+(?=/[^:]+$display)|$name|)
		    {	$entry = $_;   }
		}
		defined $entry
		    or  fatal('call_failed__1__2',
			      'xauth list', 'no ' . $display);
		debug(4, 'Xauthority entry is: ', $entry);
		my $xauth_add = 'xauth -b -f ' . $xauth . ' add ' . $entry;
		system($xauth_add) == 0
		    or  fatal('call_failed__1__2', $xauth_add, $?);
		# This is a branch we can't really mock as non-root:
		# uncoverable branch true
		if ($self->{user} ne 'root')
		{
		    # uncoverable statement
		    my ($uid, $gid) = (getpwnam($self->{user}))[2..3];
		    # uncoverable statement
		    chown $uid, $gid, $xauth_dir, $xauth;
		}
		push @todo, 'export XAUTHORITY=/.xauth/.Xauthority';
	    }
	}
    }

    # next to last build command:
    push @todo, '', '# run command:', 'cd "' . $self->{dir} . '"';
    my @command = @{$self->{command}};
    @command > 0  or  @command = (SHELL);
    my $cmd = shift @command;
    $cmd =~ m/'/  and  fatal 'can_t_run_with__1__2', $cmd, "'";
    local $_;
    foreach (@command)
    {
	if (! m/'/)
	{   $_ = "'$_'";   }
	elsif (! m/"/)
	{   $_ = '"' . $_ . '"';   }
	else
	{   fatal 'can_t_run_with__1__2', $_, "'\"";   }
    }
    if ($self->{user} ne 'root')
    {
	if ($cmd eq SHELL)
	{   @command = ('su', $self->{user}, '-s', SHELL);   }
	elsif (0 == @command)
	{   @command = ('su', $self->{user}, '-s', SHELL, '-c', "'$cmd'");   }
	else
	{
	    # su with command parameters is a bit tricky, but the following
	    # should do the job:
	    $cmd .= ' "$@"';	# a literal $@ in the command line itself
	    unshift @command,
		'su', $self->{user}, '-s', SHELL, '-c', "'$cmd'",
		'--', 'dummy_argv0';
	}
    }
    else
    {   unshift @command, "'$cmd'";   }
    debug(4, 'command is "exec', join(' ', @command), '"');
    push @todo, join(' ', 'exec', @command);

    # finally write startup script:
    open my $f, '>', $self->{init}
	or  fatal 'can_t_open__1__2', $self->{init}, $!;
    say $f $_ foreach @todo;
    close $f;
    # A failing chmod can only happen in very unlikely race conditions:
    # uncoverable branch true
    unless (chmod(0755, $self->{init}) == 1)
    {
	# uncoverable statement
	fatal 'call_failed__1__2', 'chmod', $self->{init};
    }
    # TODO: We could optimise everything if we only have /bin/sh as single
    # command (no script needed)!
}

#########################################################################

1;

#########################################################################
#########################################################################

=head1 SEE ALSO

man pages C<lxc-execute>, C<lxc-attach>, C<lxc.container.conf> and C<nft>

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
