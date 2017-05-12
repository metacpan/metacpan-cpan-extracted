package Alien::nasm;

use strict;
use warnings;
use base qw( Alien::Base );
use Env qw( @PATH );
use File::Spec;

# ABSTRACT: Find or build nasm, the netwide assembler
our $VERSION = '0.18'; # VERSION


my $in_path;

sub import
{
  require Carp;
  Carp::carp "Alien::nasm with implicit path modification is deprecated ( see https://metacpan.org/pod/Alien::nasm#CAVEATS )";
  return if Alien::nasm->install_type('system');
  return if $in_path;
  my $dir = File::Spec->catdir(Alien::nasm->dist_dir, 'bin');
  Carp::carp "adding $dir to PATH";
  unshift @PATH, $dir;
  # only do it once.
  $in_path = 1;
}


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

version 0.18

=head1 SYNOPSIS

 use Alien::nasm ();
 use Env qw( @PATH );
 
 unshift @ENV, Alien::nasm->bin_dir;
 system 'nasm', ...;

Or with L<Alien::Build::ModuleBuild>:

 use Alien::Base::ModuleBuild;
 Alien::Base::ModuleBuild->new(
   ...
   alien_bin_requires => {
     'Alien::nasm' => '0.11',
   },
   alien_build_commands => {
     "%{nasm} ...",
   },
   ...
 )->create_build_script;

=head1 DESCRIPTION

This Alien module provides Netwide Assembler (NASM).

This class is a subclass of L<Alien::Base>, so all of the methods documented there
should work with this class.

=head1 HELPERS

=head2 nasm

 %{nasm}

Returns the name of the nasm executable.  As of this writing it is always
C<nasm>, but in the future it may have a different value.

=head1 CAVEATS

This version of L<Alien::nasm> adds nasm to your path, if it isn't
already there when you use it, like this:

 use Alien::nasm;  # deprecated, issues a warning

This was a design mistake, and now B<deprecated>.  When L<Alien::nasm> was
originally written, it was one of the first Alien tool style modules on
CPAN.  As such, the author and the L<Alien::Base> team hadn't yet come up
with the best practices for this sort of module.  The author, and the
L<Alien::Base> team feel that for consistency and for readability it is
better use L<Alien::nasm> without the automatic import:

 use Alien::nasm ();

and explicitly modify the C<PATH> yourself (examples are above in the
synopsis).  The old style will issue a warning.  The old behavior will be
removed, but not before 31 January 2018.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
