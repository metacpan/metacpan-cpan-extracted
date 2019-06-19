package Alien::bz2;

use strict;
use warnings;
use Alien::Libbz2;

# ABSTRACT: Build and make available bz2
our $VERSION = '0.24'; # VERSION


sub new
{
  my($class) = @_;
  bless {}, $class;
}


sub cflags
{
  my $cflags = Alien::Libbz2->cflags;
  return $cflags if ! wantarray;
  require Text::ParseWords;
  Text::ParseWords::shellwords($cflags);
}


sub libs
{
  my $libs = Alien::Libbz2->libs;
  return $libs if ! wantarray;
  require Text::ParseWords;
  Text::ParseWords::shellwords($libs);
}


sub dlls
{
  my @dlls = Alien::Libbz2->dynamic_libs;
  wantarray ? @dlls : $dlls[0];
}


sub version
{
  Alien::Libbz2->version;
}


sub install_type
{
  Alien::Libbz2->install_type;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::bz2 - Build and make available bz2

=head1 VERSION

version 0.24

=head1 SYNOPSIS

Build.PL

 use Alien::bz2;
 use Module::Build;
 
 my $alien = Alien::bz2->new;
 my $build = Module::Build->new(
   ...
   extra_compiler_flags => [$alien->cflags],
   extra_linker_flags   => [$alien->libs],
   ...
 );
 
 $build->create_build_script;

Makefile.PL

 use Alien::bz2;
 use ExtUtils::MakeMaker;
 
 my $alien = Alien::bz2;
 WriteMakefile(
   ...
   CCFLAGS => scalar $alien->cflags,
   LIBS   => [$alien->libs],
 );

FFI::Platypus

 use Alien::bz2;
 use FFI::Platypus;
 
 my $ffi = FFI::Platypus->new(lib => [Alien::bz2->new->dlls]);
 $ffi->attach( BZ2_bzlibVersion => [] => 'string' );

=head1 DESCRIPTION

B<Note>: This class exists only for backwards compatibility only!
I recommend that you use L<Alien::Libbz2> instead!

If you just want to compress or decompress bzip2 data in Perl you
probably want one of L<Compress::Bzip2>, L<Compress::Raw::Bzip2>
or L<IO::Compress::Bzip2>.

This distribution installs bz2 so that it can be used by other Perl
distributions.  If already installed for your operating system, and it can
be found, this distribution will use the bz2 that comes with your
operating system, otherwise it will download it from the Internet, build
and install it.

If you set the environment variable C<ALIEN_BZ2> to 'share', this
distribution will ignore any system bz2 found, and build from
source instead.  This may be desirable if your operating system comes
with a very old version of bz2 and an upgrade path for the 
system bz2 is not possible.

This distribution also honors the C<ALIEN_FORCE> environment variable used
by L<Alien::Base>.  Setting C<ALIEN_FORCE> has the same effect as setting
C<ALIEN_BZ2> to 'share'.

=head1 CONSTRUCTOR

=head2 new

 my $alien = Alien::bz2->new;

Although not necessary, you may create an instance of L<Alien::bz2>.

=head1 METHODS

=head2 cflags

 my $cflags = Alien::bz2->cflags;
 my @cflags = Alien::bz2->cflags;

Returns the C compiler flags necessary to build against bz2.

Returns flags as a list in list context and combined into a string in
scalar context.

=head2 libs

 my $libs = Alien::bz2->libs;
 my @libs = Alien::bz2->libs;

Returns the library flags necessary to build against bz2.

Returns flags as a list in list context and combined into a string in
scalar context.

=head2 dlls

 my @dlls = Alien::bz2->dlls;

Returns a list of dynamic libraries (usually a list of just one library)
that make up bz2.  This can be used for L<FFI::Platypus>.

Returns just the first dynamic library found in scalar context.

=head2 version

 my $version = Alien::bz2->version;

Returns the version of bz2.

=head2 install_type

 my $type = Alien::bz2->install_type;

Returns the install type, one of either C<system> or C<share>.

=head1 SEE ALSO

=over 4

=item L<Alien::Libbz2>

=item L<Alien::Build>

=item L<Compress::Bzip2>

=item L<Compress::Raw::Bzip2>

=item L<IO::Compress::Bzip2>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
