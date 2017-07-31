use strict;
use warnings;
package Alien::Google::GRPC;
$Alien::Google::GRPC::VERSION = '0.07';
use base qw( Alien::Base );

=head1 NAME

Alien::Google::GRPC - Locates installed gRPC library. If not, downloads from Github and does a local install.

=cut

=head1 SYNOPSIS

In your Build.PL:

 use Module::Build;
 use Alien::Google::GRPC;
 my $builder = Module::Build->new(
   ...
   configure_requires => {
     'Alien::Google::GRPC' => '0',
     ...
   },
   extra_compiler_flags => Alien::Google::GRPC->cflags,
   extra_linker_flags   => Alien::Google::GRPC->libs,
   ...
 );
 
 $build->create_build_script;

In your Makefile.PL:

 use ExtUtils::MakeMaker;
 use Config;
 use Alien::Google::GRPC;
 
 WriteMakefile(
   ...
   CONFIGURE_REQUIRES => {
     'Alien::Google::GRPC' => '0',
   },
   CCFLAGS => Alien::Google::GRPC->cflags . " $Config{ccflags}",
   LIBS    => [ Alien::Google::GRPC->libs ],
   ...
 );

In your script or module:

 use Alien::Google::GRPC;
 use Env qw( @PATH );
 
 unshift @PATH, Alien::Google::GRPC->bin_dir;

=cut


=head1 DESCRIPTION

This distribution provides gRPC so that it can be used by other 
Perl distributions that are on CPAN.  It does this by first trying to 
detect an existing install of gRPC on your system.  If found it 
will use that.  If it cannot be found, the source code will be downloaded
from the internet and it will be installed in a private share location
for the use of other modules.

=cut


=head2  Notes

This module is still in an early development stage. 
I have some additional modules I'll be releasing soon that depend on this module. 
It is possible some changes will be made to this module as the 
integration process proceeds.


If a build is needed, it can be lengthy. A half hour or more to compile is not uncommon. 

=cut

=head1  DEPENDENCIES

The following dependencies need to be installed in order for gRPC to build.

 $ [sudo] apt-get install build-essential
 $ [sudo] apt-get install curl
 $ [sudo] apt-get install git

The install information that this module is based on is available here:
https://github.com/grpc/grpc/blob/master/INSTALL.md

At this time only Linux builds are supported.

=cut

=head1 AUTHOR

Tom Stall <stall@cpan.org>

=cut

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Tom Stall.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

=head1 SEE ALSO

L<Alien>, L<Alien::Base>, L<Alien::Build::Manual::AlienUser>

=cut

1;
