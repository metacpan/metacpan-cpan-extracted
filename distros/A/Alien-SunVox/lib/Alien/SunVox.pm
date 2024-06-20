use strict;
use warnings;
package Alien::SunVox;

# ABSTRACT: Install The SunVox Library - Alexander Zolotov's SunVox modular synthesizer and sequencer

our $VERSION = '0.01';

use parent qw/ Alien::Base /;









1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::SunVox - Install The SunVox Library - Alexander Zolotov's SunVox modular synthesizer and sequencer

=head1 VERSION

version 0.01

=head1 SYNOPSIS

In your Makefile.PL:

 use ExtUtils::MakeMaker;
 use Alien::Base::Wrapper ();

 WriteMakefile(
   Alien::Base::Wrapper->new('Alien::SunVox')->mm_args2(
     # MakeMaker args
     NAME => 'My::XS',
     ...
   ),
 );

In your Build.PL:

 use Module::Build;
 use Alien::Base::Wrapper qw( Alien::SunVox !export );

 my $builder = Module::Build->new(
   ...
   configure_requires => {
     'Alien::SunVox' => '0',
     ...
   },
   Alien::Base::Wrapper->mb_args,
   ...
 );

 $build->create_build_script;

In your L<FFI::Platypus> script or module:

 use FFI::Platypus;
 use Alien::SunVox;

 my $ffi = FFI::Platypus->new(
   lib => [ Alien::SunVox->dynamic_libs ],
 );

=head1 DESCRIPTION

This distribution provides SunVox so that it can be used by other
Perl distributions that are on CPAN.  It does this by first trying to
detect an existing install of SunVox on your system.  If found it
will use that.  If it cannot be found, the source code will be downloaded
from the internet and it will be installed in a private share location
for the use of other modules.

=head1 SEE ALSO

L<Alien>, L<Alien::Base>, L<Alien::Build::Manual::AlienUser>

=head1 ACKNOWLEDGEMENT

Powered by SunVox (modular synth & tracker)
Copyright (c) 2008 - 2024, Alexander Zolotov <nightradio@gmail.com>, WarmPlace.ru

=head1 AUTHOR

John Barrett <john@jbrt.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by John Barrett.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
