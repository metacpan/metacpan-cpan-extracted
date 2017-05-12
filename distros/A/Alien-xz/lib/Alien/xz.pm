package Alien::xz;

use strict;
use warnings;
use base qw( Alien::Base );

# ABSTRACT: Find or build xz
our $VERSION = '0.04'; # VERSION


sub alien_helper
{
  return {
    xz => sub { 'xz' },
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::xz - Find or build xz

=head1 VERSION

version 0.04

=head1 SYNOPSIS

From a Perl script

 use Alien::xz;
 use Env qw( @PATH );
 unshift @PATH, Alien::xz->bin_dir;  # xz is now in your path

From Alien::Base Build.PL

 use Alien:Base::ModuleBuild;
 my $builder = Module::Build->new(
   ...
   alien_bin_requires => {
     'Alien::xz' => '0.02',
   }
   ...
 );
 $builder->create_build_script;

=head1 DESCRIPTION

This package can be used by other CPAN modules that require xz,
the compression utility.

=head1 HELPERS

=head2 xz

 %{xz}

Returns the name of the xz command.  Usually just C<xz>.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
