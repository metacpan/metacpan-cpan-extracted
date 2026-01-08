use v5.40;
use experimental 'class';
class Alien::Xmake 0.06 {
    use File::Spec;
    use File::Basename qw(dirname);
    field $windows = $^O eq 'MSWin32';
    field $config : param //= sub {
        my $conf;
        try {
            require Alien::Xmake::ConfigData;    # Try to load the ConfigData module generated during install
            $conf = { map { $_ => Alien::Xmake::ConfigData->config($_) } Alien::Xmake::ConfigData->config_names };

            # The raw 'bin' value in config is a relative path string.
            # We must call the generated helper method to get the absolute path.
            if ( Alien::Xmake::ConfigData->can('bin') ) {
                $conf->{bin} = Alien::Xmake::ConfigData->bin;
            }
        }
        catch ($e) {    # Fallback / manual install detection
            $conf = { install_type => 'system' };
        }
        return $conf;
        }
        ->();

    # We don't really need $dir detection if ConfigData is working,
    # but we keep it for fallback scenarios (running from blib/lib, etc).
    field $dir;
    ADJUST {
        if ( !$config->{bin} || !-e $config->{bin} ) {
            my @parts = qw[auto share dist Alien-Xmake];
            push @parts, 'bin' unless $windows;

            # Look through @INC for the share directory
            foreach my $inc (@INC) {
                my $d = File::Spec->catdir( $inc, @parts );
                if ( -d $d ) {
                    $dir = $d;
                    last;
                }
            }
        }
    }

    # Pointless stubs required by some Alien::Base consumers
    method cflags ()       {''}
    method libs ()         {''}
    method dynamic_libs () { }

    # Valuable
    method install_type () { $config->{install_type} }

    method bin_dir () {

        # Return the directory of the raw path (unquoted)
        my $exe = $self->_resolve_path;
        return dirname($exe);
    }

    method exe () {

        # Return a potentially quoted path for execution
        my $path = $self->_resolve_path;
        return $self->_quote_path($path);
    }

    method xrepo () {

        # xrepo is usually in the same folder as Xmake
        my $exe_path   = $self->_resolve_path;
        my $parent     = dirname($exe_path);
        my $xrepo_name = 'xrepo' . ( $windows ? '.bat' : '' );

        # Check sibling
        my $try = File::Spec->catfile( $parent, $xrepo_name );
        if ( -e $try ) {
            return $self->_quote_path($try);
        }

        # Fallback to config path calculation if the sibling check failed
        if ( $config->{bin} ) {
            my $conf_parent = dirname( $config->{bin} );
            my $target      = File::Spec->catfile( $conf_parent, $xrepo_name );
            return $self->_quote_path($target);
        }

        # Last resort: return bare command
        return $xrepo_name;
    }
    method version ()             { $self->install_type eq 'system' ? $self->_getver : $config->{version} }
    method build ()               { $self->_getbuild }
    method config ( $key //= () ) { defined $key ? $config->{$key} : $config }

    sub alien_helper () {
        { xmake => sub { __PACKAGE__->new->exe }, xrepo => sub { __PACKAGE__->new->xrepo } }
    }
    #
    method _getver() {
        my ( $ver, undef ) = $self->_getver_build;
        "v$ver";
    }

    method _getbuild() {
        my ( undef, $build ) = $self->_getver_build;
        $build;
    }

    method _getver_build() {
        my $cmd = $self->exe;
        state $out //= qx[$cmd --version];
        return ( $1, $2 ) if $out =~ /xmake\s+v?(\d+\.\d+\.\d+)(?:\+(.+),)?/i;
        ( '0.0.0', () );
    }

    # Resolve absolute path without quotes
    method _resolve_path () {
        my $bin = $config->{bin};

        # If ConfigData failed or we are in a fallback state:
        $bin = File::Spec->catfile( $dir, 'xmake' . ( $windows ? '.exe' : '' ) ) if !$bin && $dir;
        $bin //= 'xmake';

        # Ensure we return a stringified absolute path safe for system()
        File::Spec->rel2abs($bin);
    }

    # Quote path if on Windows and spaces exist
    method _quote_path ($path) {
        return qq{"$path"} if $windows && $path =~ /\s/;
        $path;
    }
} 1;
__END__

=pod

=encoding utf-8

=head1 NAME

Alien::Xmake - Locate, Download, or Build and Install Xmake

=head1 SYNOPSIS

    use Alien::Xmake;

    my $xmake = Alien::Xmake->new;

    system $xmake->exe, '--help';
    system $xmake->exe, qw[create -t qt.widgetapp test];

    system $xmake->xrepo, qw[info libpng];

=head1 DESCRIPTION

Xmake is a lightweight, cross-platform build utility based on Lua. It uses a Lua script to maintain project builds, but
is driven by a dependency-free core program written in C. Compared with Makefiles or CMake, the configuration syntax is
(in the opinion of the author) much more concise and intuitive. As such, it's friendly to novices while still
maintaining the flexibly required in a build system. With Xmake, you can focus on your project instead of the build.

Xmake can be used to directly build source code (like with Make or Ninja), or it can generate project source files like
CMake or Meson. It also has a built-in package management system to help users integrate C/C++ dependencies.


If you want to know more, please refer to the L<Documentation|https://xmake.io/guide/quick-start.html>,
L<GitHub|https://github.com/xmake-io/xmake>, or L<Gitee|https://gitee.com/tboox/xmake>. You are also welcome to join
the L<community|https://xmake.io/about/contact.html>.

=for html <p align="center"><img width="916" height="236" src="https://xmake.io/assets/img/index/xmake-basic-render.gif"></p>

=head1 Methods

Not many are required or provided.

=head2 C<install_type()>

Returns 'system' or 'shared'.

=head2 C<exe()>

    system Alien::Xmake->exe;

Returns the full path to the Xmake executable.

=head2 C<xrepo()>

    system Alien::Xmake->xrepo;

Returns the full path to the L<xrepo|https://github.com/xmake-io/xmake-repo> executable.

=head2 C<bin_dir()>

    use Env qw[@PATH];
    unshift @PATH, Alien::Xmake->bin_dir;

Returns a list of directories you should push onto your PATH.

For a 'system' install this step will not be required.

=head2 C<version()>

    my $ver = Alien::Xmake->version;

Returns the version of Xmake installed.

Under a 'system' install, C<xmake --version> is run once and the version number is cached.

=head1 Alien::Base Helper

To use Xmake in your C<alienfile>s, require this module and use C<%{xmake}> and C<%{xrepo}>.

    use alienfile;
    # ...
        [ '%{xmake}', 'install' ],
        [ '%{xrepo}', 'install ...' ]
    # ...

=head1 Xmake Cookbook

Xmake is severely underrated so I'll add more nifty things here but for now just a quick example.

You're free to create your own projects, of course, but Xmake comes with the ability to generate an entire project for
you:

    $ xmake create -P hi    # generates a basic console project in C++ and xmake.lua build script
    $ cd hi
    $ xmake -y              # builds the project if required, installing defined prerequisite libs, etc.
    $ xmake run             # runs the target binary which prints 'hello, world!'

C<xmake create> is a lot like C<minil new> in that it generates a new project for you that's ready to build even before
you change anything. It even tosses a C<.gitignore> file in. You can generate projects in C++, Go, Objective C, Rust,
Swift, D, Zig, Vale, Pascal, Nim, Fortran, and more. You can also generate boilerplate projects for simple console
apps, static and shared libraries, macOS bundles, GUI apps based on Qt or wxWidgets, IOS apps, and more.

See C<xmake create --help> for a full list.

=head1 Prerequisites

Windows simply downloads an installer but elsewhere, you gotta have git, make, and a C compiler installed to build and
install Xmake. If you'd like Alien::Xmake to use a pre-built or system install of Xmake, install it yourself first with
one of the following:

=over

=item Built from source

    $ curl -fsSL https://xmake.io/shget.text | bash

...or on Windows with Powershell...

    > Invoke-Expression (Invoke-Webrequest 'https://xmake.io/psget.text' -UseBasicParsing).Content

...or if you want to do it all by hand, try...

    $ git clone --recursive https://github.com/xmake-io/xmake.git
    # Xmake maintains dependencies via git submodule so --recursive is required
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

Download a 32- or 64-bit installer from https://github.com/xmake-io/xmake/releases and run it.

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

Build from source using gmake instead of make or try this:

    $

=item Android (Termux)

    $ pkg install xmake

=back

=head1 See Also

L<https://xmake.io/>

Demos for both `xmake` and `xrepo` in `eg/`.

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2. Other copyrights, terms, and conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=for stopwords xmake macOS wxWidgets CMake gotta FreeBSD MacOS

=cut
