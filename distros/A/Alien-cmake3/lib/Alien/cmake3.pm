package Alien::cmake3;

use strict;
use warnings;
use 5.008001;
use base qw( Alien::Base );

# ABSTRACT: Find or download or build cmake 3 or better
our $VERSION = '0.08'; # VERSION


sub exe
{
  my($class) = @_;
  $class->runtime_prop->{command};
}

sub alien_helper
{
  return {
    cmake3 => sub {
      # return the executable name for GNU make,
      # usually either make or gmake depending on
      # the platform and environment
      Alien::cmake3->exe;
    },
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::cmake3 - Find or download or build cmake 3 or better

=head1 VERSION

version 0.08

=head1 SYNOPSIS

From Perl:

 use Alien::cmake3;
 use Env qw( @PATH );
 
 unshift @PATH, Alien::cmake3->bin_dir;
 system 'cmake', ...;

From L<alienfile>

 use alienfile;
 
 share {
   # Build::CMake plugin pulls in Alien::cmake3 automatically
   plugin 'Build::CMake';
   build [
     # this is the default build step, if you do not specify one.
     [ '%{cmake3}', -G => '%{cmake_generator}', '-DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=true', '-DCMAKE_INSTALL_PREFIX:PATH=%{.install.prefix}', '.' ],
     '%{make}',
     '%{make} install',
   ];
 };

=head1 DESCRIPTION

This L<Alien> distribution provides an external dependency on the build tool C<cmake>
version 3.0.0 or better.  C<cmake> is a popular alternative to autoconf.

=head1 METHODS

=head2 bin_dir

 my @dirs = Alien::cmake3->bin_dir;

List of directories that need to be added to the C<PATH> in order for C<cmake> to work.

=head2 exe

 my $exe = Alien::cmake3->exe;

The name of the C<cmake> executable.

=head1 HELPERS

=head2 cmake3

 %{cmake3}

The name of the C<cmake> executable.

=head1 SEE ALSO

=over 4

=item L<Alien::Build::Plugin::Build::CMake>

L<Alien::Build> plugin for C<cmake>  This will automatically pull in Alien::cmake3 if you
need it.

=item L<Alien::CMake>

This is an older distribution that provides an alienized C<cmake>.  It is different in
these ways:

=over 4

=item L<Alien::cmake3> is based on L<alienfile> and L<Alien::Build>

It integrates better with L<Alien>s that are based on that technology.

=item L<Alien::cmake3> will provide version 3.0.0 or better

L<Alien::CMake> will provide 2.x.x on some platforms where more recent binaries are not available.

=item L<Alien::cmake3> will install on platforms where there is no system C<cmake> and no binary C<cmake> provided by cmake.org

It does this by building C<cmake> from source.

=item L<Alien::cmake3> is preferred

In the opinion of the maintainer of both L<Alien::cmake3> and L<Alien::CMake> for these reasons.

=back

=back

=head1 ENVIRONMENT

=over 4

=item ALIEN_INSTALL_TYPE

This is the normal L<Alien::Build> environment variable and you can set it to one of
C<share>, C<system> or C<default>.

=item ALIEN_CMAKE_FROM_SOURCE

If set to true, and if a share install is attempted, L<Alien::cmake3> will not try a
binary share install (even if available), and instead a source share install.

=back

=head1 CAVEATS

If you do not have a system C<cmake> of at least 3.0.0 available, then a share install
will be attempted.

Binary share installs are attempted on platforms for which the latest version of C<cmake>
are provided.  As of this writing, this includes: Windows (32/64 bit), macOS
(intel/arm universal) and Linux (intel/arm 64 bit).  No checks are made to ensure that
your platform is supported by this binary installs.  Typically the same versions
supported by the operating system vendor and supported by C<cmake>, so that should not
be a problem.  If you are using an operating system not supported by its vendor
Please Stop That, this is almost certainly a security vulnerability.

That said if you really do need L<Alien::cmake3> on an unsupported system,
you have some options:

=over 4

=item Install system version of C<cmake>

If you can find an older version better than 3.0.0 that is supported by your operating
system.

=item Force a source code install

Set the C<ALIEN_CMAKE_FROM_SOURCE> environment variable to a true value to build a
share install from source.

=back

Source share installs are attempted on platforms for which the latest version of
C<cmake> are not available, like the various flavours of *BSD.  This may not be ideal,
and if you can install a system version of C<cmake> it may work better.

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Adriano Ferreira (FERREIRA)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
