package Clang::CastXML::Find;

use strict;
use warnings;
use 5.022;
use experimental qw( signatures );
use File::Which ();
use Carp ();
use Env qw( @PATH );

# ABSTRACT: Find the CastXML executable, if available.
our $VERSION = '0.02'; # VERSION


sub where ($)
{
  return $ENV{PERL_CLANG_CASTXML_PATH} if defined $ENV{PERL_CLANG_CASTXML_PATH};

  local $ENV{PATH} = $ENV{PATH};

  if(eval { require Alien::castxml; 1 })
  {
    unshift @PATH, Alien::castxml->bin_dir;
  }

  my $exe = File::Which::which('castxml');
  return $exe if defined $exe;

  Carp::croak("Unable to find castxml");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clang::CastXML::Find - Find the CastXML executable, if available.

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 use Clang::CastXML::Find;
 my $exe = Clang::CastXML::Find->where;

=head1 DESCRIPTION

This is a module for finding the location of the CastXML executables.

=head1 METHODS

=head2 where

 my $exe = Clang::CastXML::Find->where;

Returns the location of CastXML, if installed and found.  This method will throw an exception
if it cannot be found.

=head1 SEE ALSO

L<Clang::CastXML>

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
