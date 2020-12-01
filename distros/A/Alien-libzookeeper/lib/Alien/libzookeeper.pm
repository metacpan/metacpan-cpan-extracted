package Alien::libzookeeper;

use 5.006;
use strict;
use warnings;

use parent 'Alien::Base';

=head1 NAME

Alien::libzookeeper - libzookeeper, with alien

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

    use Alien::libzookeeper;

    Alien::libzookeeper->libs;
    Alien::libzookeeper->libs_static;
    Alien::libzookeeper->cflags;

    # Or a more realistic example; in your makefile:
    use Config;
    my $zk_libs        = Alien::libzookeeper->libs;
    my $zk_libs_static = Alien::libzookeeper->libs_static;

    my $lddflags = $Config{lddlflags} // '';
    $lddlflags  .= ' ';

    my $libext = $Config{lib_ext};
    if ( $libs_static =~ /libzookeeper\.\Q$libext\E/ ) {
        # We can statically link against libzookeeper.
        # To link statically, we need to pass arguments to `ld`, not to the C
        # compiler, and we need to drop the dynamic version from the arguments:
        $_ =~ s/-lzookeeper\b// for $zk_libs, $zk_libs_static;
        $lddlflags .= ' ' . $zk_libs_static;
    }

    WriteMakefile(
        INC       => Alien::libzookeeper->cflags,
        LIBS      => [ $zk_libs ],
        LDDLFLAGS => [ $lddlflags ],
        ...
    );

=head1 DESCRIPTION

C<Alien::libzookeeper> is an C<Alien> interface to C<libzookeeper>.

Turns out that C<libzookeeper> is pretty hard to get hold of!  It's source is
shipped as part of ZooKeeper, so in some systems you need to install ZooKeeper
-- and all the Java stack it needs -- just to get the C shared library.

In other systems, you can get it from package managers just fine, but it doesn't
have a C<pkg-config> meta file, and so finding it ends up requiring writing and
running C.

And in some systems (Alpine, Arch-Linux) there's just no way to get the library.

And even if you got it -- it might be called C<libzookeeper_mt> instead!

This module tries very hard to get a working C<libzookeeper>:  It checks pkg-config,
it checks by compiling code, and if there's nothing in the system that we can use,
it builds version 3.5.6 from source.

=head1 NOTES

The built-from-source version comes with some caveats!

First, we use version 3.5.6 because that's the last official release that
can be built from source without needing Java; see L<https://issues.apache.org/jira/browse/ZOOKEEPER-3530>
for details.

Second, we patch a bug fixed upstream in the 3.6.x releases that lead
to segfaults on connection errors; see L<https://issues.apache.org/jira/browse/ZOOKEEPER-3954>

Third, we patch its C<CMakeLists.txt> with some missing make targets;
see L<https://issues.apache.org/jira/browse/ZOOKEEPER-4012>.

Fourth, we patch its C<CMakeLists.txt> to change how it generates the
statically-linked C<libzookeeper.a>; see L<https://issues.apache.org/jira/browse/ZOOKEEPER-4014>

Fifth, we patch its build process to generate a C<pkg-config> meta
file; see L<https://issues.apache.org/jira/browse/ZOOKEEPER-4013>

Hopefully as the above get addressed, there will be less and less
cases where this module ends up building the library itself;
or at least we'll be able to get rid of some of these patches!

=head1 AUTHOR

B Fraser, C<< <fraserbn at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-alien-libzookeeper at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Alien-libzookeeper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by B Fraser.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Alien::libzookeeper
