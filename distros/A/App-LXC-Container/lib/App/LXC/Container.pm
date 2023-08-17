package App::LXC::Container;

# Author, Copyright and License: see end of file

=head1 NAME

App::LXC::Container - configure, create and run LXC application containers

=head1 SYNOPSIS

    lxc-app-setup <container>
    lxc-app-update <container>...
    lxc-app-run [{-u|--user} <user>] <container> <command> <parameters>...

=head1 ABSTRACT

B<Currently this module is unfinished work in progress!  It is only uploaded
to test the development processes and see how the tests run and fail on the
various different platforms.  In the first versions it also only supports
Debian (and maybe Ubuntu and some other derivates) using Pipewire or
Pulseaudio as audio system and X11 as windowing system.  Also see KNOWN BUGS
below!>

App::LXC::Container provides a toolbox to configure, create and run one or
more applications inside of simple and secure LXC (L<Linux
containers|https://linuxcontainers.org/lxc/>) application containers.  Those
containers have minimal overhead compared to the underlying Linux system.
See below for a discrimination against tools like
L<Docker|https://www.docker.com/>, L<Snap|https://snapcraft.io/> /
L<Flatpak|https://flatpak.org/> or full-blown L<virtual
machines|http://www.linux-kvm.org/>.

Minimal overhead includes main memory, disk storage, run-time and to a
certain extend administration.  Its main purpose is to run one or more
simple applications (e.g. a browser or a stand-alone third party
application) in a more secure environment, especially on desktop systems.

Note that this toolbox uses L<UI::Various> to be able to run with or without
Graphical User Interface.  If you want to use the GUI, you need to install
L<Tk> yourself as it's only an optional dependency.

Also note that both L<LXC|https://linuxcontainers.org/lxc/introduction/> and
L<LXCFS|https://linuxcontainers.org/lxcfs/introduction/> must be installed.

=head1 DESCRIPTION

The goal of App::LXC::Container is to allow applications installed on the
machine to be run inside of LXC application containers.  LXC needs almost no
overhead while still providing good additional security compared to running
the applications directly on the machine.  Its main disadvantages compared
to the four alternatives aforementioned in the abstract are:

=over

=item -

It must use the same kernel as the underlying machine.

=item -

It must use the same program and library versions.

=item -

Some components (e.g. the display server) are not as secure as with
the alternatives.

=item -

The concept is not useful if you need to run and scale an application
across several machines.

=back

These disadvantages are compensated by several advantages:

=over

=item +

All applications are automatically updated together with the Linux
distribution of the machine.

=item +

The applications do not need additional disk space (except for the
configuration files as well as some directories, bind-mounts and symbolic
links - we're writing about 250-2500 additional inodes and 500-2500 kB of
disk space).

=item +

The applications do not use additional main memory when compared to
running outside of the LXC container (except for the overhead of a few
scripts and LXC itself).

=back

App::LXC::Container is a toolbox basically providing three commands:

=head2 lxc-app-setup

is the script used to configure an LXC application container.  Depending on
the environment it uses a graphical or non-graphical user interface for the
configuration.  When run for the first time it also asks for the location of
the toolbox's configuration directory and creates a symbolic link to it in
the user's home directory.

=head2 lxc-app-update

is the script used to update the LXC configuration file of one container
from one or more simpler configuration files created by C<lxc-app-setup>.
The name of the LXC container is the name of the last of the names of the
simpler configuration files.  The script must be run after major updates of
one of the programs (packages) used within the application container or the
Linux distribution itself.

=head2 lxc-app-run

is the script called to run a program within its specific application
container.  It automatically starts a new container or attaches to an
already running container and also allows running the application as a
specific user (provided that user exists within the container).

=head1 BUILT-IN CONTAINERS

Two container names are special built-in for testing purposes.  Using them
allows you to check for principle LXC configuration problems:

=over

=item no-network

is a minimal container only providing a minimal set of everything without
any network access.  It can be used to check what can be seen from every LXC
application container created by the scrips.

=item local-network

is a minimal container providing a minimal set of everything with network
access limited to the host of the container.  This is also the minimum
network configuration needed by a container supporting C<X11> or C<audio>.

=item network

is a minimal container providing a minimal set of everything with full
network access.  It can be used to check principle network problems of LXC
application containers with network access.

=back

=head1 EXAMPLE

Let's go through a typical use-case for the three scripts:

You want to make surfing through the Internet a bit more secure by confining
the applications used into an application container called C<internet>.
You're using C<chromium> as your browser.  Instead of the embedded PDF
viewer yor're also using C<evince> as an external one.  Finally you want to
use the separate account C<browser> to use them for additional security.

Before you start all programs must be already installed, and all needed user
accounts must be already created.

You now first start by setting up the meta-configuration of the container by
calling C<lxc-app-setup internet>.  (If this is the first time running the
command you now need to chose a directory for all configuration files and
the root directory for the LXC application containers.  The first directory
must be writable by the calling user.  Note that to select a directory in
one of the file-selection dialogues of L<UI::Various> you need to enter the
directory without selecting anything in it.)

In the main window you now add the needed programs: Select C<+> in the
C<packages> box followed by the programs C<chromium> and C<evince> in the
file-selection dialogue.  C<OK> in the later should now present you with
your Linux distribution's packages for those programs.

Next select full network access, X11 and audio support using the radio- and
check-boxes near the bottom.  Finally select C<+> in the C<users> box to add
the needed user C<browser>.  Leave the script with C<OK> to create the
meta-configuration.

The second step is creating the real LXC configuration by calling
C<lxc-app-update internet>.  Note that it might be possible to re-run the
update after any I<major> change in one of the used distribution's packages.

Now you can do a first check of the created application container by calling
C<lxc-app-run --user browser internet chromium>.  Your browser should start
inside of the LXC application container and you can test it with a video to
check correct audio access.

While testing you might notice that you can't access local HTML
documentation beneath the directory C</usr/share/doc>.  To change that you
re-run C<lxc-app-setup internet> and add this directory by selecting C<+> in
the C<files> box.  In the file-selection dialogue you navigate to
C</usr/share/doc> and select C<OK> without selecting anything in the
directory.  Again leave the script with (another) C<OK> to recreate the
meta-configuration and re-run C<lxc-app-update internet>.

The next test of C<lxc-app-run --user browser internet chromium> now can
access the local documentation.

=head1 LIMITS

As above C<-> count against App::LXC::Container, C<+> count for it.

=head2 compared to Docker containers

=over

=item -

Docker containers are much better for scalable server applications.

=item -

Docker containers may use different versions of an application or even a
different Linux distribution.

=item +

With Docker containers you must either trust that the provider(s) of the
image(s) used to build the container take care of installing all security
updates of everything used within it or check those versions yourself
against those of the distribution used by the container.

=item +

Docker containers need additional disk space for the images and additional
main memory as nothing is shared with the main system.

=item +

Installing / updating Docker containers can be quite time-consuming.

=back

=head2 compared to Snap / Flatpak

=over

=item -

Snap / Flatpak packages may come from a source providing faster and/or more
recent versions of at least their main programs.

=item +

For Snap / Flatpak you must either trust that the provider of that package
takes care of installing all security updates of all packages used within it
or check those versions yourself against those of the used distribution.

=item +

Snap / Flatpak packages need additional disk space for the packages and
additional main memory as nothing is shared with the main system (usually
less than Docker containers).

=back

=head2 compared to virtual machines

=over

=item -

Virtual machines allow running different versions of applications, different
Linux distributions and even other operating systems.

=item -

Like Docker containers virtual machines are also much better for scalable
server applications.

=item -

Virtual machines are completely separated (except for low-level hardware
attacks like Heartbleed etc.) and more secure than any type of container.

=item +

The images for virtual machines need a lot more disk space and main memory
as nothing is shared with the main system (even more than Docker
containers).

=item +

Virtual machines must be updated separately from the main system.

=item +

Starting an application inside of a virtual machine is slower than starting
an application container.

=back

I<Additional advantages/disadvantages are welcome.>

=head1 BEST PRACTICES

Especially external packages often haven't all their real dependencies
configured.  For those it is often necessary to manually add some packages
and bind mount points like the following:

=head2 additional packages

Note that the examples are from Debian.

=over

=item fontconfig-config (select C</usr/share/fontconfig>)

=item locales (select C</usr/share/locale/locale.alias>)

=back

=head2 additional bind mounts

Note that again the examples are from Debian.

=over

=item C</usr/share/fonts>

=back

=head1 KNOWN BUGS

Currently the package only supports Debian based distributions.  If you're
using something different please get in touch to extend the support.  (The
framework is already there, but the specific commands are missing, and
that's where I need some help.)  Everything derived from Debian should be
easy to add.  For RPM based distributions I've also already some ideas.

Also only X11 graphic and pulseaudio/pipewire sound has been tested so far.
Wayland probably works as well but other sound systems most surely not.
(Again, some help would be appreciated.)

Non-standard user configuration (not using C</etc/passwd>, C</etc/group>
etc. or not using C</home> as location for normal users) are currently not
supported.

It is not properly checked that LXC and LXCFS are really installed.  If not,
this will produce some other errors.

Currently recommended or suggested packages are ignored while following the
dependencies.  This will be fixed (and configurable) in a later version.

Some other not yet supported configurations may cause fatal error messages
as well.

If the container needs to use C<su> to switch user inside of it, root
(currently?) can not have a mapped user ID.  See
L<App::LXC::Container::Run|root access>

Files or symbolic links created by post-install activities are currently not
automatically included.  This may cause strange errors until they are
manually added to a configuration.  One most prominent example are the links
in C</etc/alternatives>.

Dependencies within multiple architectures are sometimes wrong,
e.g. C<wine32> would install the 64 bit C<libwine> instead of the correct 32
bit version.  The workaround is manually adding the correct package.

=cut

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

use File::Path 'make_path';

our $VERSION = "0.15";

# TODO: Caller dependent module usage to only include UI::Various for setup
# and corresponding tests.  Is there a better approach?
my $ui;
BEGIN {
    $ui = 0;
    if ($0 =~ m!(?:^|/)(?:lxc-app-setup|(?:0[2-4]|90)-[-a-z]+\.t)$|^-e!)
    {
	require UI::Various;
	UI::Various->import({log => 'INFO', stderr => 1});
	$ui = 1;
	require App::LXC::Container::Setup;
	App::LXC::Container::Setup->import;
    }
    if ($0 =~ m!(?:^|/)(?:lxc-app-update|06-update\.t)$|^-e!)
    {
	require App::LXC::Container::Update;
	App::LXC::Container::Update->import;
    }
    if ($0 =~ m!(?:^|/)(?:lxc-app-run|07-run\.t)$|^-e!)
    {
	require App::LXC::Container::Run;
	App::LXC::Container::Run->import;
    }
}
use App::LXC::Container::Texts;

#########################################################################
#########################################################################

=head1 MAIN FUNCTIONS

The module defines the following main functions for the scripts
C<lxc-app-setup> and C<lxc-app-update>:

=cut

#########################################################################

=head2 B<setup> - setup meta-configuration

    App::LXC::Container::setup($container);

=head3 parameters:

    $container          name of the container to be configured

=head3 description:

This is the actual code for the wrapper script C<lxc-app-setup>.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub setup($)
{
    defined $ENV{ALC_DEBUG}  and  $ENV{ALC_DEBUG} =~ m/^[0-9]+$/  and
	debug($ENV{ALC_DEBUG});
    my $container = App::LXC::Container::Setup->new(shift);
    $container->main();
}

#########################################################################

=head2 B<update> - update LXC configuration

    App::LXC::Container::update(@containers);

=head3 parameters:

    @container          name of the container(s) to be updated

=head3 description:

This is the actual code for the wrapper script C<lxc-app-update>.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub update(@)
{
    defined $ENV{ALC_DEBUG}  and  $ENV{ALC_DEBUG} =~ m/^[0-9]+$/  and
	debug($ENV{ALC_DEBUG});
    my $container = App::LXC::Container::Update->new(@_);
    $container->main();
}

#########################################################################

=head2 B<run> - run LXC configuration

    App::LXC::Container::run([@options,] $name, <program> [, <program-options>]);

=head3 parameters:

    @options            parameters for container:
                        {-d|--dir|--directory} <starting-directory>
                        {-u|--user} <user-to-be-used>
    $container          the name of the container to be run

=head3 description:

This is the actual code for the wrapper script C<lxc-app-run>.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub run(@)
{
    my ($user, $dir) = ('root', '/');
    while (2 < @_  and  $_[0] =~ m/^(?:-[du]|--(?:dir|directory|user))$/)
    {
	if ($_[0] =~ m/^(-u|--user)$/)
	{   shift;   $user = shift;   }
	else
	{   shift;   $dir = shift;   }
    }
    my $name = shift;
    $name =~ m/^[A-Za-z][-A-Z_a-z.0-9]+$/  or  fatal 'bad_container_name';
    defined $ENV{ALC_DEBUG}  and  $ENV{ALC_DEBUG} =~ m/^[0-9]+$/  and
	debug($ENV{ALC_DEBUG});
    my $container = App::LXC::Container::Run->new($name, $user, $dir, @_);
    $container->main();
}

#########################################################################
# Trick to see previously stored standard error output even when Curses
# clears the screen at the very end of program:

END {
    if ($ui  and  UI::Various::using() eq 'Curses')
    {
        print STDERR "\r\n waiting 10 seconds before screen is cleared\r\n";
        sleep 10;
    }
}

1;

__END__
#########################################################################
#########################################################################

=head1 SEE ALSO

C<L<App::LXC::Container::Setup>>, C<L<App::LXC::Container::Update>>

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
