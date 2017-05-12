package Alien::flex;

use strict;
use warnings;
use base qw( Alien::Base );

# ABSTRACT: Find or build flex
our $VERSION = '0.12'; # VERSION


sub alien_helper
{
  return {
    flex => sub { 'flex' },
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::flex - Find or build flex

=head1 VERSION

version 0.12

=head1 SYNOPSIS

From a Perl script

 use Alien::flex;
 use Env qw( @PATH );
 unshift @PATH, Alien::flex->bin_dir;  # flex is now in your path

From Alien::Base Build.PL

 use Alien:Base::ModuleBuild;
 my $builder = Module::Build->new(
   ...
   alien_bin_requires => [ 'Alien::flex' ],
   ...
 );
 $builder->create_build_script;

=head1 DESCRIPTION

This package can be used by other CPAN modules that require flex.

=head1 HELPERS

=head2 flex

 %{flex}

Returns the name of the flex command.  Usually just C<flex>.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
