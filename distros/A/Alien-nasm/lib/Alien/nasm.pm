package Alien::nasm;

use strict;
use warnings;
use base qw( Alien::Base );
use Env qw( @PATH );
use File::Spec;

# ABSTRACT: Find or build nasm, the netwide assembler
our $VERSION = '0.22'; # VERSION


sub alien_helper
{
  return {
    nasm => sub {
      'nasm';
    },
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::nasm - Find or build nasm, the netwide assembler

=head1 VERSION

version 0.22

=head1 SYNOPSIS

From your Perl script:

 use Alien::nasm ();
 use Env qw( @PATH );
 
 unshift @ENV, Alien::nasm->bin_dir;
 system 'nasm', ...;

From L<alienfile>:

 use alienfile;
 
 share {
   requires 'Alien::nasm';
   build [
     '%{nasm} ...',
   ];
 };

=head1 DESCRIPTION

This Alien module provides Netwide Assembler (NASM).

This class is a subclass of L<Alien::Base>, so all of the methods documented there
should work with this class.

=head1 HELPERS

=head2 nasm

 %{nasm}

Returns the name of the nasm executable.  As of this writing it is always
C<nasm>, but in the future it may have a different value.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
