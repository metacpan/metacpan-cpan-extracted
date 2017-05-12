=head1 NAME

README.txt - build and installation instructions

=head1 DESCRIPTION

Alien::wxWidgets allows wxPerl to easily find information about
your wxWidgets installation. It can store this information for multiple
wxWidgets versions or configurations (debug, Unicode, etc.). It can also
build and install a private copy of wxWidgets as part of the build process.

=head1 Installing wxWidgets

If you do not know how to do it, please answer 'yes' to the question 'Do you
want to build wxWidgets?'; Alien::wxWidgets will build and install a
copy of wxWidgets for you.

=head1 Installing Alien::wxWidgets

Please note that the steps below can be repeated multiple times in order
install multiple configurations (differing for the wxWidgets version,
compiler, compiler version, debug/unicode settings).

=head2 Unices and Mac OS X

Important: If you are going to use the system wxWidgets or your own build of 
wxWidgets then either your required wx-config must be the first wx-config in 
the PATH or the WX_CONFIG environment variable must be set to the full path 
to wx-config. The environment WX_CONFIG variable can also be used to specify 
a different wx-config.

    perl Build.PL
    perl Build
    perl Build test
    perl Build install

=head3 Requirements for building on Unices

If you are going to ask Alien::wxWidgets to build wxWidgets you will need to
install development prerequisites. The following is the list for Ubuntu but
you can adapt for your own distribution where the package names may vary.

gcc
g++
libgtk2.0-dev
libgstreamer0.10-dev
libgstreamer-plugins-base0.10-dev
libglu1-mesa-dev
libexpat1-dev
libtiff4-dev
libpng12-dev
libjpeg-dev
libcairo2-dev
freeglut3-dev
libxmu-dev
libwebkitgtk-dev*

To build the wxWebView componenent you need libwebkitgtk version 1.3.1 or
greater. For Linux distributions currently this means a fairly recent
release. For example, Ubuntu ge 11.10

If you do not have a recent enough libwebkitgtk installed then configure
will simply not build the library. This is harmless.

=head2 Windows

If you are going to build your own wxWidgets then
    <add your compiler to the path>
    <build wxWidgets>
    set WXDIR=C:\Path\to\wxWidgets

Then whether you have built your own wxWidgets or not:

    perl Build.PL
    perl Build
    perl Build test
    perl Build install

Important: If you do not allow Alien to build wxWidgets, the command line 
options to Build.PL must match the build settings used to build wxWidgets.


=head2 Command Line Options for build

perl Build.PL --wxWidgets-graphicscontext

    For wxWidgets 2.8.x this flag will cause wxGraphicsContext to be built
    and used. On Windows, your compiler must support GDI+.
    For wxWidgets 2.9.x, the build system detects whether wxGraphicsContext
    is supported. However, the default for any flavour of MinGW or MSVC 6 
    is to assume that wxGraphicsContext is NOT supported. So if you know that
    wxGraphicsContext IS supported, you can use this flag to force inclusion.

perl Build.PL --wxWidgets-unicode=1

    Only relevant for wxWidgets 2.8.x, indicate if you want a unicode build.
    --wxWidgets-unicode=1|0, default is 1

perl Build.PL --wxWidgets-build=0

    Indicate if you want wxWidgets to be downloaded and built
    --wxWidgets-build=1|0, default depends on whether Aline-wxWidgets finds
    a usable wxWidgets installation on your system. An explict value always 
    overrides the default.
    Always use an explicit flag if you want to avoid prompts.
    
perl Build.PL --wxWidgets-version=2.8.12
	
	If --wxWidgets-build=1, indicate the version of wxWidgets to build.
	e.g. --wxWidgets-version=2.9.4.   The current default is 2.8.12.
	Always use an explicit flag if you want to avoid prompts.
	
perl Build.PL --wxWidgets-source=tar.gz
    
    If --wxWidgets-build=1, indicate the type of archive to download
    e.g. --wxWidgets-source=tar.bz2,   then default for wxWidgets 2.8.x is 
    tar.gz and the default for wxWidgets 2.9.x is tar.bz2.
    Always use an explicit flag if you want to avoid prompts.
    
perl Build.PL --wxWidgets-build-opengl=1
	
	Build the wxGLCanvas libraries. 
	--wxWidgets-build-opengl=1|0     default is 1.
	Always use an explicit flag if you want to avoid prompts.

perl Build.PL --wxWidgets-extraflags="--disable-compat26"

    On Unices and Mac OS X you may use this to pass through any flags you
    may wish to configure. Doing so however will drop any additional default 
    flags that Alien wxWidgets would normally pass to configure to ensure
    that wxWidgets builds as required on your system. This approach is used 
    so that you can use this to configure precisely to your requirement
    and not have Alien-wxWidgets override it.
    
    e.g. --wxWidgets-extraflags="CC=gcc-4.0 --with-expat=builtin --disable-compat28"
    
    On Windows this option can be used to pass options directly to mingw32-make
    or nmake. You can usefully pass any of the options in build/msw/config.(vc|gcc)
    
    e.g. --wxWidgets-extraflags="USE_STC=0 VENDOR=anameIchose"

perl Build.PL --wxWidgets-userpatch=/some/path/to/user.patch
	
    If you have automated building scripts and use some wxWidgets customisations
    you may give the path to a patch file (unified diff style) to be applied
    to the wxWidgets source. Any standard Alien::wxWidgets patches will be
    applied first.

perl Build.PL --prefix
	
	Set a custom installation prefix.
	Works exactly the same as perl Makefile.PL PREFIX=/some/path
	
	e.g. --prefix=/some/custom/path

=cut
