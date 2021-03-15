package Alien::Hunspell;

use strict;
use warnings;
use base 'Alien::Base';

# ABSTRACT: Install hunspell
our $VERSION = '0.17'; # VERSION




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Hunspell - Install hunspell

=head1 VERSION

version 0.17

=head1 SYNOPSIS

In your Makefile.PL:

 use ExtUtils::MakeMaker;
 use Alien::Base::Wrapper ();

 WriteMakefile(
   Alien::Base::Wrapper->new('Alien::Hunspell')->mm_args2(
     # MakeMaker args
     NAME => 'My::XS',
     ...
   ),
 );

In your Build.PL:

 use Module::Build;
 use Alien::Base::Wrapper qw( Alien::Hunspell !export );

 my $builder = Module::Build->new(
   ...
   configure_requires => {
     'Alien::Hunspell' => '0',
     ...
   },
   Alien::Base::Wrapper->mb_args,
   ...
 );

 $build->create_build_script;

In your L<FFI::Platypus> script or module:

 use FFI::Platypus;
 use Alien::Hunspell;

 my $ffi = FFI::Platypus->new(
   lib => [ Alien::Hunspell->dynamic_libs ],
 );

=head1 DESCRIPTION

This module provides the spelling library Hunspell.  It will either
detect it as provided by the operating system, or download the source
from the Internet and install it for you.  It uses L<Alien::Base>.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
