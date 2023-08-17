# NAME

App::LXC::Container - configure, create and run LXC application containers

# SYNOPSIS

    lxc-app-setup <container>
    lxc-app-update <container>...
    lxc-app-run [{-u|--user} <user>] <container> <command> <parameters>...

# ABSTRACT

**Currently this module is unfinished work in progress!  It is only uploaded
to test the development processes and see how the tests run and fail on the
various different platforms.  In the first versions it also only supports
Debian (and maybe Ubuntu and some other derivates) using Pipewire or
Pulseaudio as audio system and X11 as windowing system.  Also see KNOWN BUGS
below!**

App::LXC::Container provides a toolbox to configure, create and run one or
more applications inside of simple and secure LXC ([Linux
containers](https://linuxcontainers.org/lxc/)) application containers.  Those
containers have minimal overhead compared to the underlying Linux system.
See below for a discrimination against tools like
[Docker](https://www.docker.com/), [Snap](https://snapcraft.io/) /
[Flatpak](https://flatpak.org/) or full-blown [virtual
machines](http://www.linux-kvm.org/).

Minimal overhead includes main memory, disk storage, run-time and to a
certain extend administration.  Its main purpose is to run one or more
simple applications (e.g. a browser or a stand-alone third party
application) in a more secure environment, especially on desktop systems.

Note that this toolbox uses [UI::Various](https://metacpan.org/pod/UI%3A%3AVarious) to be able to run with or without
Graphical User Interface.  If you want to use the GUI, you need to install
[Tk](https://metacpan.org/pod/Tk) yourself as it's only an optional dependency.

Also note that both [LXC](https://linuxcontainers.org/lxc/introduction/) and
[LXCFS](https://linuxcontainers.org/lxcfs/introduction/) must be installed.

# DESCRIPTION

The goal of App::LXC::Container is to allow applications installed on the
machine to be run inside of LXC application containers.  LXC needs almost no
overhead while still providing good additional security compared to running
the applications directly on the machine.  Its main disadvantages compared
to the four alternatives aforementioned in the abstract are:

- -

    It must use the same kernel as the underlying machine.

- -

    It must use the same program and library versions.

- -

    Some components (e.g. the display server) are not as secure as with
    the alternatives.

- -

    The concept is not useful if you need to run and scale an application
    across several machines.

These disadvantages are compensated by several advantages:

- +

    All applications are automatically updated together with the Linux
    distribution of the machine.

- +

    The applications do not need additional disk space (except for the
    configuration files as well as some directories, bind-mounts and symbolic
    links - we're writing about 250-2500 additional inodes and 500-2500 kB of
    disk space).

- +

    The applications do not use additional main memory when compared to
    running outside of the LXC container (except for the overhead of a few
    scripts and LXC itself).

App::LXC::Container is a toolbox basically providing three commands:

## lxc-app-setup

is the script used to configure an LXC application container.  Depending on
the environment it uses a graphical or non-graphical user interface for the
configuration.  When run for the first time it also asks for the location of
the toolbox's configuration directory and creates a symbolic link to it in
the user's home directory.

## lxc-app-update

is the script used to update the LXC configuration file of one container
from one or more simpler configuration files created by `lxc-app-setup`.
The name of the LXC container is the name of the last of the names of the
simpler configuration files.  The script must be run after major updates of
one of the programs (packages) used within the application container or the
Linux distribution itself.

## lxc-app-run

is the script called to run a program within its specific application
container.  It automatically starts a new container or attaches to an
already running container and also allows running the application as a
specific user (provided that user exists within the container).

# BUILT-IN CONTAINERS

Two container names are special built-in for testing purposes.  Using them
allows you to check for principle LXC configuration problems:

- no-network

    is a minimal container only providing a minimal set of everything without
    any network access.  It can be used to check what can be seen from every LXC
    application container created by the scrips.

- local-network

    is a minimal container providing a minimal set of everything with network
    access limited to the host of the container.  This is also the minimum
    network configuration needed by a container supporting `X11` or `audio`.

- network

    is a minimal container providing a minimal set of everything with full
    network access.  It can be used to check principle network problems of LXC
    application containers with network access.

# EXAMPLE

Let's go through a typical use-case for the three scripts:

You want to make surfing through the Internet a bit more secure by confining
the applications used into an application container called `internet`.
You're using `chromium` as your browser.  Instead of the embedded PDF
viewer yor're also using `evince` as an external one.  Finally you want to
use the separate account `browser` to use them for additional security.

Before you start all programs must be already installed, and all needed user
accounts must be already created.

You now first start by setting up the meta-configuration of the container by
calling `lxc-app-setup internet`.  (If this is the first time running the
command you now need to chose a directory for all configuration files and
the root directory for the LXC application containers.  The first directory
must be writable by the calling user.  Note that to select a directory in
one of the file-selection dialogues of [UI::Various](https://metacpan.org/pod/UI%3A%3AVarious) you need to enter the
directory without selecting anything in it.)

In the main window you now add the needed programs: Select `+` in the
`packages` box followed by the programs `chromium` and `evince` in the
file-selection dialogue.  `OK` in the later should now present you with
your Linux distribution's packages for those programs.

Next select full network access, X11 and audio support using the radio- and
check-boxes near the bottom.  Finally select `+` in the `users` box to add
the needed user `browser`.  Leave the script with `OK` to create the
meta-configuration.

The second step is creating the real LXC configuration by calling
`lxc-app-update internet`.  Note that it might be possible to re-run the
update after any _major_ change in one of the used distribution's packages.

Now you can do a first check of the created application container by calling
`lxc-app-run --user browser internet chromium`.  Your browser should start
inside of the LXC application container and you can test it with a video to
check correct audio access.

While testing you might notice that you can't access local HTML
documentation beneath the directory `/usr/share/doc`.  To change that you
re-run `lxc-app-setup internet` and add this directory by selecting `+` in
the `files` box.  In the file-selection dialogue you navigate to
`/usr/share/doc` and select `OK` without selecting anything in the
directory.  Again leave the script with (another) `OK` to recreate the
meta-configuration and re-run `lxc-app-update internet`.

The next test of `lxc-app-run --user browser internet chromium` now can
access the local documentation.

# LIMITS

As above `-` count against App::LXC::Container, `+` count for it.

## compared to Docker containers

- -

    Docker containers are much better for scalable server applications.

- -

    Docker containers may use different versions of an application or even a
    different Linux distribution.

- +

    With Docker containers you must either trust that the provider(s) of the
    image(s) used to build the container take care of installing all security
    updates of everything used within it or check those versions yourself
    against those of the distribution used by the container.

- +

    Docker containers need additional disk space for the images and additional
    main memory as nothing is shared with the main system.

- +

    Installing / updating Docker containers can be quite time-consuming.

## compared to Snap / Flatpak

- -

    Snap / Flatpak packages may come from a source providing faster and/or more
    recent versions of at least their main programs.

- +

    For Snap / Flatpak you must either trust that the provider of that package
    takes care of installing all security updates of all packages used within it
    or check those versions yourself against those of the used distribution.

- +

    Snap / Flatpak packages need additional disk space for the packages and
    additional main memory as nothing is shared with the main system (usually
    less than Docker containers).

## compared to virtual machines

- -

    Virtual machines allow running different versions of applications, different
    Linux distributions and even other operating systems.

- -

    Like Docker containers virtual machines are also much better for scalable
    server applications.

- -

    Virtual machines are completely separated (except for low-level hardware
    attacks like Heartbleed etc.) and more secure than any type of container.

- +

    The images for virtual machines need a lot more disk space and main memory
    as nothing is shared with the main system (even more than Docker
    containers).

- +

    Virtual machines must be updated separately from the main system.

- +

    Starting an application inside of a virtual machine is slower than starting
    an application container.

_Additional advantages/disadvantages are welcome._

# BEST PRACTICES

Especially external packages often haven't all their real dependencies
configured.  For those it is often necessary to manually add some packages
and bind mount points like the following:

## additional packages

Note that the examples are from Debian.

- fontconfig-config (select `/usr/share/fontconfig`)
- locales (select `/usr/share/locale/locale.alias`)

## additional bind mounts

Note that again the examples are from Debian.

- `/usr/share/fonts`

# KNOWN BUGS

Currently the package only supports Debian based distributions.  If you're
using something different please get in touch to extend the support.  (The
framework is already there, but the specific commands are missing, and
that's where I need some help.)  Everything derived from Debian should be
easy to add.  For RPM based distributions I've also already some ideas.

Also only X11 graphic and pulseaudio/pipewire sound has been tested so far.
Wayland probably works as well but other sound systems most surely not.
(Again, some help would be appreciated.)

Non-standard user configuration (not using `/etc/passwd`, `/etc/group`
etc. or not using `/home` as location for normal users) are currently not
supported.

It is not properly checked that LXC and LXCFS are really installed.  If not,
this will produce some other errors.

Currently recommended or suggested packages are ignored while following the
dependencies.  This will be fixed (and configurable) in a later version.

Some other not yet supported configurations may cause fatal error messages
as well.

If the container needs to use `su` to switch user inside of it, root
(currently?) can not have a mapped user ID.  See
[App::LXC::Container::Run](https://metacpan.org/pod/root%20access)

Files or symbolic links created by post-install activities are currently not
automatically included.  This may cause strange errors until they are
manually added to a configuration.  One most prominent example are the links
in `/etc/alternatives`.

Dependencies within multiple architectures are sometimes wrong,
e.g. `wine32` would install the 64 bit `libwine` instead of the correct 32
bit version.  The workaround is manually adding the correct package.

# MAIN FUNCTIONS

The module defines the following main functions for the scripts
`lxc-app-setup` and `lxc-app-update`:

## **setup** - setup meta-configuration

    App::LXC::Container::setup($container);

### parameters:

    $container          name of the container to be configured

### description:

This is the actual code for the wrapper script `lxc-app-setup`.

## **update** - update LXC configuration

    App::LXC::Container::update(@containers);

### parameters:

    @container          name of the container(s) to be updated

### description:

This is the actual code for the wrapper script `lxc-app-update`.

## **run** - run LXC configuration

    App::LXC::Container::run([@options,] $name, <program> [, <program-options>]);

### parameters:

    @options            parameters for container:
                        {-d|--dir|--directory} <starting-directory>
                        {-u|--user} <user-to-be-used>
    $container          the name of the container to be run

### description:

This is the actual code for the wrapper script `lxc-app-run`.

# SEE ALSO

`[App::LXC::Container::Setup](https://metacpan.org/pod/App%3A%3ALXC%3A%3AContainer%3A%3ASetup)`, `[App::LXC::Container::Update](https://metacpan.org/pod/App%3A%3ALXC%3A%3AContainer%3A%3AUpdate)`

man pages `lxc.container.conf`, `lxc` and `lxcfs`

LXC documentation on [https://linuxcontainers.org](https://linuxcontainers.org)

# LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

# AUTHOR

Thomas Dorner &lt;dorner (at) cpan (dot) org>

## Contributors

none so far
