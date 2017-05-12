package Alien::curl;

use strict;
use warnings;
use base qw( Alien::Base );

# ABSTRACT: Discover or download and install curl + libcurl
our $VERSION = '0.06'; # VERSION







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::curl - Discover or download and install curl + libcurl

=head1 VERSION

version 0.06

=head1 SYNOPSIS

In your script or module:

 use Alien::curl;
 use Env qw( @PATH );
 
 unshift @ENV, Alien::curl->bin_dir;

In your Build.PL:

 use Module::Build;
 use Alien::curl;
 my $builder = Module::Build->new(
   ...
   configure_requires => {
     'Alien::curl' => '0',
     ...
   },
   extra_compiler_flags => Alien::curl->cflags,
   extra_linker_flags   => Alien::curl->libs,
   ...
 );
 
 $build->create_build_script;

In your Makefile.PL:

 use ExtUtils::MakeMaker;
 use Config;
 use Alien::curl;
 
 WriteMakefile(
   ...
   CONFIGURE_REQUIRES => {
     'Alien::curl' => '0',
   },
   CCFLAGS => Alien::curl->cflags . " $Config{ccflags}",
   LIBS    => [ Alien::curl->libs ],
   ...
 );

In your L<FFI::Platypus> script or module:

 use FFI::Platypus;
 use Alien::curl;
 
 my $ffi = FFI::Platypus->new(
   lib => [ Alien::curl->dynamic_libs ],
 );

=head1 DESCRIPTION

This distribution provides curl so that it can be used by other 
Perl distributions that are on CPAN.  It does this by first trying to 
detect an existing install of curl on your system.  If found it 
will use that.  If it cannot be found, the source code will be downloaded
from the internet and it will be installed in a private share location
for the use of other modules.

=head1 SEE ALSO

L<Alien>, L<Alien::Base>, L<Alien::Build::Manual::AlienUser>

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
