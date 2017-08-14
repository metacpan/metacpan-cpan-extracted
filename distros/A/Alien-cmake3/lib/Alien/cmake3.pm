package Alien::cmake3;

use strict;
use warnings;
use 5.008001;
use base qw( Alien::Base );

# ABSTRACT: Find or download or build cmake 3 or better
our $VERSION = '0.02'; # VERSION


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

version 0.02

=head1 SYNOPSIS

From Perl:

 use Alien::cmake3;
 use Env qw( @PATH );
 
 unshift @PATH, Alien::cmake->bin_dir;
 system 'cmake', ...;

From L<alienfile>

 use alienfile;
 
 share {
   requires Alien::cmake3;
   build [
     '%{cmake3} ...'
     '%{make}',
     '%{make} install',
   ],
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

The name of the <cmake> executable.

=head1 SEE ALSO

=over 4

=item L<Alien::CMake>

This is an older distribution that provides an alienized C<cmake>.  It is different in
these ways:

=over 4

=item L<Alien::cmake3> is based on L<alienfile> and L<Alien::Build> and integrates better with L<Alien>s that are based on that technology.

=item L<Alien::cmake3> will provide version 3.0.0 or better.  L<Alien::CMake> will provide 2.x.x on some platforms where more recent binaries are not available.

=item L<Alien::cmake3> will install on platforms where there is no system C<cmake> and no binary C<cmake> provided by cmake.org.  It does this by building C<cmake> from source.

=item L<Alien::cmake3> is preferred in the opinion of the maintainer of both L<Alien::cmake3> and L<Alien::CMake> for these reasons.

=back

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
