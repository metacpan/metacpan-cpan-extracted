package Alien::OpenMP;

use strict;
use warnings;
use Config ();

our $VERSION = '0.003';

# set as package variable since %Config::Config is read only, (per docs and in practice)
our $CCNAME = $Config::Config{ccname};

# per-compiler meta data, each supported compiler will require an entry

our $omp_flags = {
    # used by ccflags, lddlflags
    gcc => '-fopenmp',
};

our $omp_check_libs = {
    # used by _check_libs, intended for use by Devel::CheckLib
    gcc => [qw/gomp/],
};

our $omp_check_headers = {
    # used by _check_headers, intended for use by Devel::CheckLib
    gcc => [qw/omp.h/],
};

# "public" Alien::Base method implementations

sub cflags {
    my $cn = $CCNAME;
    _assert_os($omp_flags, $cn);
    return $omp_flags->{$cn};
}

# we can reuse cflags for gcc/gomp; hopefully this will
# remain the case for all supported compilers

sub lddlflags {
    my $cn = $CCNAME;
    _assert_os($omp_flags, $cn);
    return $omp_flags->{$cn};
}

# Inline related methods

sub Inline {
  my ($self, $lang) = @_;
  return {
    CCFLAGS     => cflags(),
    LDDLFLAGS   => join( q{ }, $Config::Config{lddlflags}, lddlflags() ),
  };
}

# "private" internal helper subs

sub _assert_os {
    my ($omp, $cn) = @_;
    # OpenMP pragmas live behind source code comments
    if ( not defined $omp->{$cn} ) {
      # dies the same way as ExtUtils::MakeMaker::os_unsupported()
      die qq{OS unsupported\n};
    }
    return;
}

sub _check_libs {
    my $cn = $CCNAME;
    _assert_os($omp_check_libs, $cn);
    return $omp_check_libs->{$cn};
}

sub _check_headers {
    my $cn = $CCNAME;
    _assert_os($omp_check_headers, $cn);
    return $omp_check_headers->{$cn};
}

1;

__END__

=head1 NAME

Alien::OpenMP - Encapsulate system info for OpenMP

=head1 SYNOPSIS

    use Alien::OpenMP;
    say Alien::OpenMP->cflags;    # e.g. -fopenmp if gcc 
    say Alien::OpenMP->lddlflags; # e.g. -fopenmp if gcc 

=head1 DESCRIPTION

This module encapsulates the knowledge required to compile OpenMP programs
C<$Config{ccname}>. C<C>, C<Fortran>, and C<C++> programs annotated
with declarative OpenMP pragmas will still compile if the compiler (and
linker if this is a separate process) is not passed the appropriate flag
to enable OpenMP support. This is because all pragmas are hidden behind
full line comments (with the addition of OpenMP specific C<sentinels>,
as they are called).

All compilers require OpenMP to be explicitly activated during compilation;
for example, GCC's implementation, C<GOMP>, is invoked by the C<-fopenmp>
flag.

Most major compilers support OpenMP, including: GCC, Intel, IBM,
Portland Group, NAG, and those compilers created using LLVM. GCC's OpenMP
implementation, C<GOMP>, is available in all modern versions. Unfortunately,
while OpenMP is a well supported standard; compilers are not required to
use the same commandline switch to activate support. All compilers that
support OpenMP use slightly different ways of invoking it.

=head2 Compilers Supported by this module

At this time, the following compilers are supported:

=over 4

=item C<gcc>

C<-fopenmp> enables OpenMP support in via compiler and linker:

    gcc -fopenmp ./my-openmp.c -o my-openmp.x

=back

=head2 Note On Compiler Support

If used for an unsupported compiler, C<ExtUtils::MakeMaker::os_unsupported> is
invoked, which results an exception propagating from this method being raised
with the value of C<qq{OS unsupported\n}> (note the new line).

This module assumes that the compiler in question is the same one used to
build C<perl>. Since the vast majority of C<perl>s are building using C<gcc>,
initial support is targeting it. However, like C<perl>, many other compilers
may be used.

Adding support for a new compiler should be straightforward; please section on
contributing, below.

=head2 Contributing

The biggest need is to support additional compilers. OpenMP is a well established
standard across compilers, but there is guarantee that all compilers will use the
same flags, library names, or header files. It should also be easy to contribute
a patch to add this information, which is effectively its purpose. At the very least,
please create an issue at the official issue tracker to request this support, and
be sure to include the relevant information. Chances are the maintainers of this
module do not have access to an unsupported compiler.

=head1 METHODS

=over 3

=item C<cflags>

Returns flag used by a supported compiler to enable OpenMP. If not support,
an empty string is provided since by definition all OpenMP programs must compile
because OpenMP pramgas are annotations hidden behind source code comments.

Example, GCC uses, C<-fopenmp>.

=item C<lddlflags>

Returns the flag used by the linker to enable OpenMP. This is usually the same
as what is returned by C<cflags>.

Example, GCC uses, C<-fopenmp>, for this as well.

=item C<Inline>

Used in support of L<Inline::C>'s C<with> method (inherited from
L<Inline>). This method is not called directly, but used when compiling
OpenMP programs with C<Inline::C>:

    use Alien::OpenMP;
    use Inline (
        C           => 'DATA',
        with        => qw/Alien::OpenMP/,
    );

The nice, compact form above replaces this mess:

    use Alien::OpenMP;
    use Inline (
        C           => 'DATA',
        ccflagsex   => Alien::OpenMP::cflags(),
        lddlflags   => join( q{ }, $Config::Config{lddlflags}, Alien::OpenMP::lddlflags() ),
    );

=item C<_check_libs>

Internal method.

Returns an array reference of libraries, e.g., C<gomp> for C<gcc>. It is meant
specifically as an internal method to support L<Devel::CheckLib> in this module's
C<Makefile.PL>.

=item C<_check_headers>

Internal method.

Returns an array reference of header files, e.g., C<omp.h> for C<gcc>. It is meant
specifically as an internal method to support L<Devel::CheckLib> in this module's
C<Makefile.PL>.

=back

=head1 AUTHOR

OODLER 577 <oodler@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2021 by oodler577

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.30.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<PDL>, L<OpenMP::Environment>,
L<https://gcc.gnu.org/onlinedocs/libgomp/index.html>.
