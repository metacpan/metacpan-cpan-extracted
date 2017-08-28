package Alien::Libarchive;

use strict;
use warnings;
use Alien::Libarchive3;
use Path::Tiny qw( path );
use Text::ParseWords qw( shellwords );

# ABSTRACT: Legacy alien for libarchive
our $VERSION = '0.29'; # VERSION


sub new
{
  my($class) = @_;
  bless {}, $class;
}

sub cflags
{
  wantarray
    ? shellwords(Alien::Libarchive3->cflags)
    : Alien::Libarchive3->cflags;
}

sub libs
{
  wantarray
    ? shellwords(Alien::Libarchive3->libs)
    : Alien::Libarchive3->libs;
}

sub dlls
{
  my @libs = Alien::Libarchive3->dynamic_libs;
  wantarray ? @libs : $libs[0];
}

sub version
{
  Alien::Libarchive3->version;
}

sub install_type
{
  Alien::Libarchive3->install_type;
}

sub pkg_config_dir
{
  path(Alien::Libarchive3->dist_dir, 'lib', 'pkgconfig')->stringify;
}

sub pkg_config_name
{
  'libarchive';
}

sub _macro_list
{
  require Config;

  my $cc = "$Config::Config{ccname} $Config::Config{ccflags} " . Alien::Libarchive3->cflags;

  my $tempdir = Path::Tiny->tempdir;
  my $file = path($tempdir, 'test.c');
  $file->spew(
    "#include <archive.h>\n#include <archive_entry.h>\n"
  );

  my @list;
  my $cmd = "$cc -E -dM $file";
  foreach my $line (`$cmd`)
  {
    if($line =~ /^#define ((AE|ARCHIVE)_\S+)/)
    {
      push @list, $1;
    }
  }
  sort @list;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Libarchive - Legacy alien for libarchive

=head1 VERSION

version 0.29

=head1 SYNOPSIS

 use Alien::Libarchive3;

=head1 DESCRIPTION

This module provides a legacy interface used by
some older versions of L<Archive::Libarchive::XS>
and L<Archive::Libarchive::FFI>.  Please use the
new interface instead: L<Alien::Libarchive3>.

=head1 SEE ALSO

L<Alien::Libarchive3>

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
