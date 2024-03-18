package Alien::xmake 0.05 {
    use strict;
    use warnings;
    use File::Which qw[which];
    use File::ShareDir;
    use File::Spec::Functions qw[rel2abs catdir catfile];
    #
    sub config {
        CORE::state $config //= sub {
            if ( eval 'require Alien::xmake::ConfigData' ) {
                return { map { $_ => Alien::xmake::ConfigData->config($_) }
                        Alien::xmake::ConfigData->config_names };
            }

            # TODO: die if running xmake fails... we obviously don't have it installed
            { xmake_type => 'system' };
            }
            ->();
        $config;
    }

    # Pointless
    sub cflags       {''}
    sub libs         {''}
    sub dynamic_libs { }

    # Valuable
    sub install_type {
        CORE::state $type
            //= eval { -d rel2abs( catdir( File::ShareDir::dist_dir('Affix-xmake'), 'bin' ) ) }
            ? 'share' :
            'system';

        #config()->{xmake_type}
        return $type;
    }

    sub bin_dir {
        CORE::state $dir
            //= eval { rel2abs( catdir( File::ShareDir::dist_dir('Affix-xmake'), 'bin' ) ) };
        return $dir // config()->{xmake_dir};
    }

    sub exe {
        CORE::state $exe //= eval {
            rel2abs(
                catfile(
                    File::ShareDir::dist_dir('Affix-xmake'), 'bin',
                    'xmake' . ( $^O eq 'MSWin32' ? '.exe' : '' )
                )
            );
        };
        return $exe // config()->{xmake_exe};
    }

    sub version {
        CORE::state $ver;
        if ( !defined $ver ) {
            if ( config->{xmake_type} eq 'system' ) {
                my $xmake = exe();
                my $run   = `$xmake --version`;
                ($ver) = $run =~ m[xmake (v.+?), A cross-platform build utility based on Lua];
            }
            else {
                $ver = config()->{xmake_ver};
            }
        }
        $ver;
    }

    sub alien_helper {
        { xmake => sub { __PACKAGE__->exe } }
    }
}
1;
__END__

=encoding utf-8

=head1 NAME

Alien::xmake - Locate, Download, or Build and Install xmake

=head1 SYNOPSIS

    use Alien::xmake;
    system Alien::xmake->exe, '--help';
    system Alien::xmake->exe, 'create -t qt.widgetapp test';

=head1 DESCRIPTION

xmake is a lightweight, cross-platform build utility based on Lua. It uses a
Lua script to maintain project builds, but is driven by a dependency-free core
program written in C. Compared with Makefiles or CMake, the configuration
syntax is (in the opinion of the author) much more concise and intuitive. As
such, it's friendly to novices while still maintaining the flexibly required in
a build system. With xmake, you can focus on your project instead of the build.

xmake can be used to directly build source code (like with Make or Ninja), or
it can generate project source files like CMake or Meson. It also has a
built-in package management system to help users integrate C/C++ dependencies.

=head1 Methods

Not many are required or provided.

=head2 C<install_type()>

Returns 'system' or 'shared'.

=head2 C<exe()>

    system Alien::xmake->exe;

Returns the full path to the xmake executable.

=head2 C<bin_dir()>

    use Env qw[@PATH];
    unshift @PATH, Alien::xmake->bin_dir;

Returns a list of directories you should push onto your PATH.

For a 'system' install this step will not be required.

=head2 C<version()>

    my $ver = Alien::xmake->version;

Returns the version of xmake installed.

Under a 'system' install, C<xmake --version> is run once and the version number
is cached.

=head1 Alien::Base Helper

To use xmake in your C<alienfile>s, require this module and use C<%{xmake}>.

    use alienfile;
    # ...
        [ '%{xmake}', 'install' ],
    # ...

=head1 xmake Cookbook

xmake is severely underrated so I'll add more nifty things here but for now
just a quick example.

You're free to create your own projects, of course, but xmake comes with the
ability to generate an entire project for you:

    $ xmake create -P hi    # generates a basic console project in C++ and xmake.lua build script
    $ cd hi
    $ xmake -y              # builds the project if required, installing defined prerequisite libs, etc.
    $ xmake run             # runs the target binary which prints 'hello, world!'

C<xmake create> is a lot like C<minil new> in that it generates a new project
for you that's ready to build even before you change anything. It even tosses a
C<.gitignore> file in. You can generate projects in C++, Go, Objective C, Rust,
Swift, D, Zig, Vale, Pascal, Nim, Fortran, and more. You can also generate
boilerplate projects for simple console apps, static and shared libraries,
macOS bundles, GUI apps based on Qt or wxWidgets, IOS apps, and more.

See C<xmake create --help> for a full list.

=head1 Prerequisites

Windows simply downloads an installer but elsewhere, you gotta have git, make,
and a C compiler installed to build and install xmake. If you'd like
Alien::xmake to use a pre-built or system install of xmake, install it yourself
first with one of the following:

=over

=item Built from source

    $ curl -fsSL https://xmake.io/shget.text | bash

...or on Windows with Powershell...

    > Invoke-Expression (Invoke-Webrequest 'https://xmake.io/psget.text' -UseBasicParsing).Content

...or if you want to do it all by hand, try...

    $ git clone --recursive https://github.com/xmake-io/xmake.git
    # xmake maintains dependencies via git submodule so --recursive is required
    $ cd ./xmake
    # On macOS, you may need to run: export SDKROOT=$(xcrun --sdk macosx --show-sdk-path)
    $ ./configure
    $ make
    $ ./scripts/get.sh __local__ __install_only__
    $ source ~/.xmake/profile

...or building from source on Windows...

    > git clone --recursive https://github.com/xmake-io/xmake.git
    > cd ./xmake/core
    > xmake

=item Windows

The easiest way might be to use the installer but you still have options.

=over

=item Installer

Download a 32- or 64-bit installer from
https://github.com/xmake-io/xmake/releases and run it.

=item Via scoop

    $ scoop install xmake

See https://scoop.sh/

=item Via the Windows Package Manager

    $ winget install xmake

See https://learn.microsoft.com/en-us/windows/package-manager/

=item Msys/Mingw

    $ pacman -Sy mingw-w64-x86_64-xmake # 64-bit

    $ pacman -Sy mingw-w64-i686-xmake   # 32-bit

=back

=item MacOS with Homebrew

    $ brew install xmake

See https://brew.sh/

=item Arch

    # sudo pacman -Sy xmake

=item Debian

    # sudo add-apt-repository ppa:xmake-io/xmake
    # sudo apt update
    # sudo apt install xmake

=item Fedora/RHEL/OpenSUSE/CentOS

    # sudo dnf copr enable waruqi/xmake
    # sudo dnf install xmake

=item Gentoo

    # sudo emerge -a --autounmask dev-util/xmake

You'll need to add GURU to your system repository first.

=item FreeBSD

Build from source using gmake instead of make.

=item Android (Termux)

    $ pkg install xmake

=back

=head1 See Also

L<https://xmake.io/>

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=for stopwords xmake macOS wxWidgets CMake gotta FreeBSD MacOS

=cut
