package Alien::Build::Plugin::Probe::OverrideCI;

use strict;
use warnings;
use Alien::Build::Plugin;
use Path::Tiny qw( path );
use File::chdir;

# ABSTRACT: Override logic for continuous integration
our $VERSION = '0.02'; # VERSION


sub init
{
  my($self, $meta) = @_;
  
  my $ci_build_root;

  if(defined $ENV{TRAVIS} && $ENV{TRAVIS} eq 'true' && defined $ENV{TRAVIS_BUILD_DIR})
  {
    $ci_build_root = path($ENV{TRAVIS_BUILD_DIR})->realpath;
  }
  elsif(defined $ENV{APPVEYOR} && $ENV{APPVEYOR} eq 'True' && $ENV{APPVEYOR_BUILD_FOLDER})
  {
    $ci_build_root = path($ENV{APPVEYOR_BUILD_FOLDER})->realpath;
  }
  else
  {
    # are you sure you are running under CI?
    die "unable to detect the type of CI";
  }

  my $override =
    $ci_build_root->subsumes(path($CWD)->realpath)
      ? $ENV{ALIEN_INSTALL_TYPE_CI} || ''
      : $ENV{ALIEN_INSTALL_TYPE}    || '';

  #Alien::Build->log("override = $override");
  
  $meta->register_hook(
    override => sub {
      $override;
    },
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Build::Plugin::Probe::OverrideCI - Override logic for continuous integration

=head1 VERSION

version 0.02

=head1 SYNOPSIS

In your .travis.yml:

 language: perl
 
 install:
   - cpanm -n Alien::Build::Probe::OverrideCI
   - cpanm -n --installdeps .
 
 env:
   global:
     - ALIEN_BUILD_PRELOAD=Probe::OverrideCI
   matrix:
     - ALIEN_INSTALL_TYPE_CI=share
     - ALIEN_INSTALL_TYPE_CI=system

In your appveyor.yml

 install:
   - ... # however you install/select which Perl to use
   - cpanm -n Alien::Build::Probe::OverrideCI
   - cpanm -n --installdeps .
 
 environment:
   ALIEN_BUILD_PRELOAD: Probe::OverrideCI
   matrix:
     - ALIEN_INSTALL_TYPE_CI: share
       ALIEN_INSTALL_TYPE_CI: system

=head1 DESCRIPTION

This plugin provides an easy way to test both share and system installs using a
travis or appveyor environment matrix, without affecting the install type detection
of prereqs.  Thus if your library C<Alien::libfoo> depends on L<Alien::gmake> you
can test both a system and share install for C<Alien::libfoo> while building 
L<Alien::gmake> using the default (usually system) install and saving build time.

It does this using the appropriate environment variables from the CI tool to determine
if the L<alienfile> is in the build root.  If you are in the build root, then we use
the environment variable C<ALIEN_INSTALL_TYPE_CI>, if we are not in the build root,
then we fallback on the existing behavior (either C<ALIEN_INSTALL_TYPE>, or the default
for the L<alienfile> itself).

If you want to override the install type on a per-alien basis in a development or
production environment (not CI), then L<Alien::Build::Plugin::Probe::Override> may
be useful for you.

=head1 SEE ALSO

=over 4

=item L<alienfile>

=item L<Alien::Build>

=item L<Alien::Build::Plugin::Probe::Override>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
