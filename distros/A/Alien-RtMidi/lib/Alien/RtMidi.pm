use strict;
use warnings;
package Alien::RtMidi;

# ABSTRACT: Install RtMidi

our $VERSION = '0.05';

use parent qw/ Alien::Base /;








1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::RtMidi - Install RtMidi

=head1 VERSION

version 0.05

=head1 SYNOPSIS

In your Makefile.PL:

 use ExtUtils::MakeMaker;
 use Alien::Base::Wrapper ();

 WriteMakefile(
   Alien::Base::Wrapper->new('Alien::RtMidi')->mm_args2(
     # MakeMaker args
     NAME => 'My::XS',
     ...
   ),
 );

In your Build.PL:

 use Module::Build;
 use Alien::Base::Wrapper qw( Alien::RtMidi !export );

 my $builder = Module::Build->new(
   ...
   configure_requires => {
     'Alien::RtMidi' => '0',
     ...
   },
   Alien::Base::Wrapper->mb_args,
   ...
 );

 $build->create_build_script;

In your L<FFI::Platypus> script or module:

 use FFI::Platypus;
 use Alien::RtMidi;

 my $ffi = FFI::Platypus->new(
   lib => [ Alien::RtMidi->dynamic_libs ],
 );

=head1 DESCRIPTION

This distribution provides RtMidi so that it can be used by other
Perl distributions that are on CPAN.  It does this by first trying to
detect an existing install of RtMidi on your system.  If found it
will use that.  If it cannot be found, the source code will be downloaded
from the internet and it will be installed in a private share location
for the use of other modules.

=head1 SEE ALSO

L<Alien>, L<Alien::Base>, L<Alien::Build::Manual::AlienUser>

=head1 AUTHOR

John Barrett <john@jbrt.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by John Barrett.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
