package Alien::libuuid;

use strict;
use warnings;
use 5.008001;
use base qw( Alien::Base );

# ABSTRACT: Find or download and install libuuid
our $VERSION = '0.01'; # VERSION








1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::libuuid - Find or download and install libuuid

=head1 VERSION

version 0.01

=head1 SYNOPSIS

In your Build.PL:

 use Module::Build;
 use Alien::libuuid;
 my $builder = Module::Build->new(
   ...
   configure_requires => {
     'Alien::libuuid' => '0',
     ...
   },
   extra_compiler_flags => Alien::libuuid->cflags,
   extra_linker_flags   => Alien::libuuid->libs,
   ...
 );
 
 $build->create_build_script;

In your Makefile.PL:

 use ExtUtils::MakeMaker;
 use Config;
 use Alien::libuuid;
 
 WriteMakefile(
   ...
   CONFIGURE_REQUIRES => {
     'Alien::libuuid' => '0',
   },
   CCFLAGS => Alien::libuuid->cflags . " $Config{ccflags}",
   LIBS    => [ Alien::libuuid->libs ],
   ...
 );

In your L<FFI::Platypus> script or module:

 use FFI::Platypus;
 use Alien::libuuid;
 
 my $ffi = FFI::Platypus->new(
   lib => [ Alien::libuuid->dynamic_libs ],
 );

=head1 DESCRIPTION

This distribution provides libuuid so that it can be used by other 
Perl distributions that are on CPAN.  It does this by first trying to 
detect an existing install of libuuid on your system.  If found it 
will use that.  If it cannot be found, the source code will be downloaded
from the internet and it will be installed in a private share location
for the use of other modules.

=head1 SEE ALSO

L<Alien>, L<Alien::Base>, L<Alien::Build::Manual::AlienUser>

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
