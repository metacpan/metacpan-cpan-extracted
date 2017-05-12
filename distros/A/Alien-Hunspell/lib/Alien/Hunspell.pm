package Alien::Hunspell;

use strict;
use warnings;
use parent 'Alien::Base';

# ABSTRACT: Install hunspell
our $VERSION = '0.08'; # VERSION


sub dynamic_libs
{
  my($self) = @_;
  $self->install_type ne 'system'
    ? $self->SUPER::dynamic_libs
    : do {
      require FFI::CheckLib;
      FFI::CheckLib::find_lib(
        lib => '*',
        verify => sub { $_[0] =~ /hunspell/ },
        symbol => 'Hunspell_create',
      );
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Hunspell - Install hunspell

=head1 VERSION

version 0.08

=head1 SYNOPSIS

Build.PL:

 use Alien::Hunspell;
 use Module::Build;
 
 Module::Build->new(
   ...
   extra_compiler_flags => Alien::Hunspell->cflags,
   extra_linker_flags   => Alien::HunSpell->libs,
   ...
 )->create_build_script;

Makefile.PL:

 use Alien:Hunspell;
 use ExtUtils::MakeMaker;
 
 WriteMakefile(
   ...
   CCFLAGS => $alien->cflags,
   LIBS    => $alien->libs,
   ...
 );

FFI::Platypus:

 use Alien::Hunspell;
 use FFI::Platypus;
 
 my $ffi = FFI::Platypus->new(
   lib => [Alien::Hunspell->new->dynamic_libs],
 );
 ...

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
