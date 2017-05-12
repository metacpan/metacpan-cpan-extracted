package Bundle::Net::Radius::Server;

use 5.008006;
our $VERSION = do { sprintf " %d.%03d", (q$Revision: 1.3 $ =~ /\d+/g) };

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Bundle::Net::Radius::Server - Prerequisites for Net::Radius::Server

=head1 SYNOPSIS

  perl -MCPAN -e 'install Bundle::Net::Radius::Server'

=head1 CONTENTS

Authen::PAM 0.16

Class::Accessor 0.27

File::Basename 2.71

File::Spec 3.19

IO::Prompt v0.99.4

IO::Prompt v0.99.4

Net::LDAP 0.33

Net::Radius::Dictionary 1.51

Net::Radius::Packet 1.51

Net::Radius::Server 1.3

Net::Server 0.94

NetAddr::IP 4.005

Pod::Usage 1.16

Test::More 0.64

Test::Warn 0.08

Time::HiRes 1.65

=head1 CONFIGURATION

Summary of my perl5 (revision 5 version 8 subversion 6) configuration:
  Platform:
    osname=darwin, osvers=8.0, archname=darwin-thread-multi-2level
    uname='darwin b01.apple.com 8.0 darwin kernel version 8.0.0: tue nov 15 13:23:51 pst 2005; root:xnu-792.99.1.obj~6release_ppc power macintosh powerpc '
    config_args='-ds -e -Dprefix=/usr -Dccflags=-g  -pipe  -Dldflags=-Dman3ext=3pm -Duseithreads -Duseshrplib'
    hint=recommended, useposix=true, d_sigaction=define
    usethreads=define use5005threads=undef useithreads=define usemultiplicity=define
    useperlio=define d_sfio=undef uselargefiles=define usesocks=undef
    use64bitint=undef use64bitall=undef uselongdouble=undef
    usemymalloc=n, bincompat5005=undef
  Compiler:
    cc='cc', ccflags ='-g -pipe -fno-common -DPERL_DARWIN -no-cpp-precomp -fno-strict-aliasing -I/usr/local/include',
    optimize='-O3',
    cppflags='-no-cpp-precomp -g -pipe -fno-common -DPERL_DARWIN -no-cpp-precomp -fno-strict-aliasing -I/usr/local/include'
    ccversion='', gccversion='4.0.1 (Apple Computer, Inc. build 5250)', gccosandvers=''
    intsize=4, longsize=4, ptrsize=4, doublesize=8, byteorder=1234
    d_longlong=define, longlongsize=8, d_longdbl=define, longdblsize=16
    ivtype='long', ivsize=4, nvtype='double', nvsize=8, Off_t='off_t', lseeksize=8
    alignbytes=8, prototype=define
  Linker and Libraries:
    ld='env MACOSX_DEPLOYMENT_TARGET=10.3 cc', ldflags ='-L/usr/local/lib'
    libpth=/usr/local/lib /usr/lib
    libs=-ldbm -ldl -lm -lc
    perllibs=-ldl -lm -lc
    libc=/usr/lib/libc.dylib, so=dylib, useshrplib=true, libperl=libperl.dylib
    gnulibc_version=''
  Dynamic Linking:
    dlsrc=dl_dlopen.xs, dlext=bundle, d_dlsymun=undef, ccdlflags=' '
    cccdlflags=' ', lddlflags='-bundle -undefined dynamic_lookup -L/usr/local/lib'

=head1 AUTHOR

Luis E. Muñoz, E<lt>luismunoz@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Luis E. Muñoz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5.8.6 itself.

=cut
