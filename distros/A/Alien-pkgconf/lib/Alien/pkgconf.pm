package Alien::pkgconf;

use strict;
use warnings;
use JSON::PP ();
use File::Spec;
use File::ShareDir ();

our $VERSION = '0.14';

=head1 NAME

Alien::pkgconf - Discover or download and install pkgconf + libpkgconf

=head1 SYNOPSIS

 use Alien::pkgconf;
 
 my $cflags = Alien::pkgconf->cflags;
 my $libs   = Alien::pkgconf->libs;

=head1 DESCRIPTION

This module provides you with the information that you need to invoke
C<pkgconf> or link against C<libpkgconf>.  It isn't intended to be
used directly, but rather to provide the necessary package by a CPAN
module that needs C<libpkgconf>, such as L<PkgConfig::LibPkgConf>.

=cut

sub _dist_dir
{
  File::Spec->catdir(File::ShareDir::dist_dir('Alien-pkgconf'), @_);
}

sub _dist_file
{
  File::Spec->catfile(File::ShareDir::dist_dir('Alien-pkgconf'), @_);
}

my $config;
sub _config
{
  $config ||= do {
    my $filename = _dist_file('status.json');
    my $fh;
    open $fh, '<', $filename;
    my $json = JSON::PP::decode_json(do { local $/; <$fh> });
    close $fh;
    $json;
  };
}

=head1 METHODS

=head2 cflags

 my $cflags = Alien::pkgconf->cflags;

The compiler flags for compiling against C<libpkgconf>.

=cut

sub cflags
{
  my($class) = @_;
  $class->install_type eq 'share'
  # may induce duplicates :/
  ? "-I@{[ _dist_dir 'include', 'pkgconf' ]} @{[ _config->{cflags} ]}"
  : _config->{cflags};
}

=head2 libs

 my $libs = Alien::pkgconf->libs;

The linker flags for linking against C<libpkgconf>.

=cut

sub libs
{
  my($class) = @_;
  $class->install_type eq 'share'
  # may induce duplicates :/
  ? "-L@{[ _dist_dir 'lib' ]} @{[ _config->{libs} ]}"
  : _config->{libs};
}

=head2 dynamic_libs

 my($dll) = Alien::pkgconf->dynamic_libs;

The C<.so>, C<.dll> or <.dynlib> shared or dynamic library
which can be used via FFI.

=cut

sub dynamic_libs
{
  my($class) = @_;
  $class->install_type eq 'share'
  ? (_dist_file('dll', _config->{dll}))
  : (_config->{dll});
}

=head2 version

 my $version = Alien::pkgconf->version;

The C<libpkgconf> version.

=cut

sub version
{
  _config->{version};
}

=head2 bin_dir

 my($dir) = Alien::pkgconf->bin_dir;

The directory where you can find C<pkgconf>.  If it is not
already in the C<PATH>.  Adding this to C<PATH> should make
tools that require C<pkgconf> work.

=cut

sub bin_dir
{
  my($class) = @_;
  $class->install_type eq 'share'
  ? (_dist_dir 'bin')
  : ();
}

=head2 install_type

 my $type = Alien::pkgconf->install_type;

The type of install, should be either C<share> or C<system>.

=cut

sub install_type
{
  _config->{install_type};
}

=head1 HELPERS

=head2 pkgconf

 %{pkgconf}

The name of the C<pkgconf> binary.  This is usually just C<pkgconf>.

=cut

sub alien_helper {
  return {
    pkgconf => sub { 'pkgconf' },
  }
}

1;

=head1 SEE ALSO

=over 4

=item L<PkgConfig::LibPkgConf>

=back

=head1 PLATFORM NOTES

=head2 Solaris

You may need to have the GNU version of nm installed, which comes
with GNU binutils.

=head1 ACKNOWLEDGMENTS

Thanks to the C<pkgconf> developers for their efforts:

L<https://github.com/pkgconf/pkgconf/graphs/contributors>

=head1 AUTHOR

Graham Ollis

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 Graham Ollis.

This is free software; you may redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

