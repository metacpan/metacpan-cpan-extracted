package Alien::ZMQ;
{
  $Alien::ZMQ::VERSION = '0.06';
}
# ABSTRACT: find and install libzmq, the core zeromq library

use warnings;
use strict;

use String::ShellQuote qw/shell_quote/;


sub inc_version { }


sub lib_version { }


sub inc_dir { }


sub lib_dir { }


sub cflags {
    if (wantarray) {
        "-I" . inc_dir;
    } else {
        "-I" . shell_quote(inc_dir);
    }
}


sub libs {
    if (wantarray) {
        "-L" . lib_dir, "-lzmq";
    } else {
        "-L" . shell_quote(lib_dir) . " -lzmq";
    }
}

1;

__END__

=pod

=head1 NAME

Alien::ZMQ - find and install libzmq, the core zeromq library

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    use Alien::ZMQ;
    use version;
    
    my $version = version->parse(Alien::ZMQ::lib_version);
    my $lib_dir = Alien::ZMQ::lib_dir;
    
    print "zeromq $version is installed at $lib_dir\n";

=head1 DESCRIPTION

Upon installation, the target system is probed for the presence of libzmq.  If
it is not found, B<libzmq 3.2.4> is installed in a shared directory.  In
short, modules that need libzmq can depend on this module to make sure that it
is available, or use it independently as a way to install zeromq.

=head1 METHODS

=head2 inc_version

Get the version number of libzmq as a v-string (version string), according to
the F<zmq.h> header file.

=head2 lib_version

Get the version number of libzmq as a v-string (version string), according to
the F<libzmq.so> file.

=head2 inc_dir

Get the directory containing the F<zmq.h> header file.

=head2 lib_dir

Get the directory containing the F<libzmq.so> file.

=head2 cflags

Get the C compiler flags required to compile a program that uses libzmq.  This
is a shortcut for constructing a C<-I> flag using L</inc_dir>.  In scalar
context, the flags are quoted using L<String::ShellQuote> and returned as
a single string.

=head2 libs

Get the linker flags required to link a program against libzmq.  This is
a shortcut for constructing a C<-L> flag using L</lib_dir>, plus C<-lzmq>.  In
scalar context, the flags are quoted using L<String::ShellQuote> and returned
as a single string.

On some platforms, you may also want to add the library path to your
executable or library as a runtime path; this is usually done by passing
C<-rpath> to the linker.  Something like this could work:

    my @flags = (Alien::ZMQ::libs, "-Wl,-rpath=" . Alien::ZMQ::lib_dir);

This will allow your program to find libzmq, even if it is installed in
a non-standard location, but some systems don't have this C<RPATH> mechanism.

=head1 OPTIONS

These options to F<Build.PL> affect the installation of this module.

=over 4

=item --zmq-skip-probe

By default, libzmq is not compiled and installed if it is detected to already
be on the system.  Use this to skip those checks and always install libzmq.

=item --zmq-cflags

Pass extra flags to the compiler when probing for an existing installation of
libzmq.  You can use this, along with L</--zmq-libs>, to help the probing
function locate libzmq if it is installed in an unexpected place.  For
example, if your libzmq is installed at F</opt/zeromq>, you can do something
like this:

    perl Build.PL --zmq-cflags="-I/opt/zeromq/include" \
                  --zmq-libs="-L/opt/zeromq/lib -lzmq"

These flags are only used by the probing function to locate libzmq; they will
not be used when compiling libzmq from source (if it needs to be).  To affect
the compiling of libzmq, using the L</--zmq-config> flag instead.

A better alternative to using L</--zmq-cflags> and L</--zmq-libs> is to help
the L<pkg-config> program find your libzmq by using the C<PKG_CONFIG_PATH>
environment variable.  Of course, this method requires that you have the
L<pkg-config> program installed.  Here's an example:

    perl Build.PL
    PKG_CONFIG_PATH=/opt/zeromq/lib/pkgconfig ./Build

=item --zmq-libs

Pass extra flags to the linker when probing for an existing installation of
libzmq.  You can use this, along with L</--zmq-cflags>, to help the probing
function locate libzmq if it is installed in an unexpected place.  Like
L</--zmq-cflags>, these flags are only used by the probing function to locate
libzmq.

=item --zmq-config

Pass extra flags to the libzmq F<configure> script.  You may want to consider
passing either C<--with-pgm> or C<--with-system-pgm> if you need support for
PGM; this is not enabled by default because it is not supported by every
system.

=back

=head1 CAVEATS

Probing is only done during the installation of this module, so if you are
using a system-installed version of libzmq and you uninstall or upgrade it,
you will also need to reinstall L<Alien::ZMQ>.

If S<libzmq-2.x> is found on the system, L<Alien::ZMQ> will use it.  There are
a few incompatibilities between S<libzmq-2.x> and S<libzmq-3.x>, so your
program may want to use the L</lib_version> method to check which version of
libzmq is installed.

=head1 BUGS

MSWin32 is not yet supported, but cygwin works.

=head1 SEE ALSO

=over 4

=item * L<GitHub project|https://github.com/chazmcgarvey/p5-Alien-ZMQ>

=item * L<ZMQ> - good perl bindings for zeromq

=item * L<ZeroMQ|http://www.zeromq.org/> - official libzmq website

=back

=head1 ACKNOWLEDGEMENTS

The design and implementation of this module were influenced by other L<Alien>
modules, including L<Alien::GMP> and L<Alien::Tidyp>.

=head1 AUTHOR

Charles McGarvey <ccm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
