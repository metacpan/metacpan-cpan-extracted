package Alien::Build::Plugin::Build::MSYS;

use strict;
use warnings;
use Alien::Build::Plugin;
use Env qw( @PATH );
use constant _win => $^O eq 'MSWin32';

# ABSTRACT: MSYS plugin for Alien::Build
our $VERSION = '0.36'; # VERSION


sub init
{
  my($self, $meta) = @_;
  
  if(_win)
  {
    $meta->add_requires('share' => 'Alien::MSYS' => '0.07');
    
    $meta->around_hook(
      build => sub {
        my $orig = shift;
        my $build = shift;

        local $ENV{PATH} = $ENV{PATH};
        unshift @PATH, Alien::MSYS::msys_path();

        $orig->($build, @_);
      },
    );

  
    # Most likely if we are trying to build something unix-y and
    # we are using MSYS, then we want to use the make that comes
    # with MSYS.
    $meta->interpolator->replace_helper(
      make => sub { 'make' },
    );

  }
  
  $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Build::Plugin::Build::MSYS - MSYS plugin for Alien::Build

=head1 VERSION

version 0.36

=head1 SYNOPSIS

 use alienfile;
 plugin 'Build::MSYS' => ();

=head1 DESCRIPTION

This plugin sets up the MSYS environment for your build on Windows.  It does
not do anything on non-windows platforms.  MSYS provides the essential tools
for building software that is normally expected in a UNIX or POSIX environment.
This like C<sh>, C<awk> and C<make>.  To provide MSYS, this plugin uses
L<Alien::MSYS>.

=head1 HELPERS

=head2 make

 %{make}

On windows the default C<%{make}> helper is replace with the make that comes with
L<Alien::MSYS>.  This is almost certainly what you want, as most unix style make
projects will not build with C<nmake> or C<dmake> typically used by Perl on Windows.

=head1 SEE ALSO

L<Alien::Build::Plugin::Autoconf>, L<Alien::Build::Plugin>, L<Alien::Build>, L<Alien::Base>, L<Alien>

L<http://www.mingw.org/wiki/MSYS>

=cut

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
