package Alien::bison;

use strict;
use warnings;
use base qw( Alien::Base );

# ABSTRACT: Find or build bison, the parser generator
our $VERSION = '0.21'; # VERSION


sub alien_helper
{
  return {
    bison => sub { 'bison' },
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::bison - Find or build bison, the parser generator

=head1 VERSION

version 0.21

=head1 SYNOPSIS

From a Perl script

 use Alien::bison;
 use Env qw( @PATH );
 unshift @PATH, Alien::bison->bin_dir;
 system 'bison', ...;

From Alien::Base Build.PL

 use Alien:Base::ModuleBuild;
 my $builder = Module::Build->new(
   ...
   alien_bin_requires => [ 'Alien::bison' ],
   ...
 );
 $builder->create_build_script;

=head1 DESCRIPTION

This package can be used by other CPAN modules that require bison,
the GNU Parser generator based on YACC.

=head1 HELPERS

=head2 bison

 %{bison}

Returns the name of the bison command.  Usually just C<bison>.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
