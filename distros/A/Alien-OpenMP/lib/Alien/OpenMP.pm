package Alien::OpenMP;

use parent 'Alien::Base';
use Config ();
use Alien::OpenMP::configure ();

our $VERSION = '0.003006';

# "public" Alien::Base method implementations

# we can reuse cflags for gcc/gomp; hopefully this will
# remain the case for all supported compilers
sub lddlflags { shift->libs }

# Inline related methods

sub Inline {
  my ($self, $lang) = @_;
  my $params = $self->SUPER::Inline($lang);
  $params->{CCFLAGSEX} = delete $params->{INC};
  return {
    %$params,
    LDDLFLAGS     => join( q{ }, $Config::Config{lddlflags}, $self->lddlflags() ),
    AUTO_INCLUDE  => $self->runtime_prop->{auto_include},
  };
}

1;

__END__

=head1 NAME

Alien::OpenMP - Encapsulate system info for OpenMP

=head1 SYNOPSIS

    use Alien::OpenMP;
    say Alien::OpenMP->cflags;       # e.g. '-fopenmp' if gcc
    say Alien::OpenMP->lddlflags;    # e.g. '-fopenmp' if gcc
    say Alien::OpenMP->auto_include; # e.g. '#include <omp.h>' if gcc

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

=item C<clang> EXPERIMENTAL

C<-fopenmp> enables OpenMP support via compiler and linker in recent
versions of C<clang>. MacOS shipped versions are missing the library
which needs installing either with L<Homebrew|https://brew.sh> or
L<Macports|https://www.macports.org>.

=back

=head2 Note On Compiler Support

If used for an unsupported compiler, C<ExtUtils::MakeMaker::os_unsupported>
is invoked, which results an exception propagating from this method being
raised with the value of C<qq{OS unsupported\n}> (note the new line).

This module assumes that the compiler in question is the same one used to
build C<perl>. Since the vast majority of C<perl>s are building using
C<gcc>, initial support is targeting it. However, like C<perl>, many
other compilers may be used.

Adding support for a new compiler should be straightforward; please
section on contributing, below.

=head2 Contributing

The biggest need is to support additional compilers. OpenMP is a well
established standard across compilers, but there is no guarantee that
all compilers will use the same flags, library names, or header files. It
should also be easy to contribute a patch to add this information, which
is effectively its purpose. At the very least, please create an issue
at the official issue tracker to request this support, and be sure to
include the relevant information. Chances are the maintainers of this
module do not have access to an unsupported compiler.

=head1 METHODS

=over 3

=item C<cflags>

Returns flag used by a supported compiler to enable OpenMP. If not support,
an empty string is provided since by definition all OpenMP programs
must compile because OpenMP pragmas are annotations hidden behind source
code comments.

Example, GCC uses, C<-fopenmp>.

=item C<lddlflags>

Returns the flag used by the linker to enable OpenMP. This is usually
the same as what is returned by C<cflags>.

Example, GCC uses, C<-fopenmp>, for this as well.

=item C<Inline>

Used in support of L<Inline::C>'s C<with> method (inherited from
L<Inline>). This method is not called directly, but used when compiling
OpenMP programs with C<Inline::C>:

    use Alien::OpenMP; use Inline (
        C           => 'DATA',
        with        => qw/Alien::OpenMP/,
    );

The nice, compact form above replaces this mess:

    use Alien::OpenMP; use Inline (
        C             => 'DATA',
        ccflagsex     => Alien::OpenMP->cflags(),
        lddlflags     => join( q{ }, $Config::Config{lddlflags}, Alien::OpenMP::lddlflags() ),
        auto_include => Alien::OpenMP->auto_include(),
    );

It also means that the standard I<include> for OpenMP is not required in
the C<C> code, i.e., C<< #include <omp.h> >>.

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
