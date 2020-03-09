package Alien::Libxml2;

use strict;
use warnings;
use base qw( Alien::Base );

# ABSTRACT: Install the C libxml2 library on your system
our $VERSION = '0.14'; # VERSION




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Libxml2 - Install the C libxml2 library on your system

=head1 VERSION

version 0.14

=head1 SYNOPSIS

In your Build.PL:

 use Module::Build;
 use Alien::Libxml2;
 my $builder = Module::Build->new(
   ...
   configure_requires => {
     'Alien::Libxml2' => '0',
     ...
   },
   extra_compiler_flags => Alien::Libxml2->cflags,
   extra_linker_flags   => Alien::Libxml2->libs,
   ...
 );
 
 $build->create_build_script;

In your Makefile.PL:

 use ExtUtils::MakeMaker;
 use Config;
 use Alien::Libxml2;
 
 WriteMakefile(
   ...
   CONFIGURE_REQUIRES => {
     'Alien::Libxml2' => '0',
   },
   CCFLAGS => Alien::Libxml2->cflags . " $Config{ccflags}",
   LIBS    => [ Alien::Libxml2->libs ],
   ...
 );

In your L<FFI::Platypus> script or module:

 use FFI::Platypus;
 use Alien::Libxml2;
 
 my $ffi = FFI::Platypus->new(
   lib => [ Alien::Libxml2->dynamic_libs ],
 );

=head1 DESCRIPTION

This module provides libxml2 for other modules to use.  There was an
already existing L<Alien::LibXML>, but it uses the older
L<Alien::Build::ModuleBuild> and has not been actively maintained for a
while.

=head1 CAVEATS

C<libxml2> has some optional prereqs, including C<zlib> and C<iconv>.
For a C<share> install you will want to make sure that these are installed
prior to installing L<Alien::Libxml2> if you want to make use of features
relying on them.

For a system install, you want to make sure the development packages for
C<libxml2>, C<zlib> and C<iconv> are installed if C<libxml2> has been
configured to use them, otherwise L<XML::LibXML> will not install as
expected.  If the tests for this module fail with a missing C<iconv.h>
or C<zlib.h>, then this is likely the reason.

=head1 SEE ALSO

=over 4

=item L<Alien::LibXML>

Unmaintained Alien for the same library.

=back

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Shlomi Fish (shlomif)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
