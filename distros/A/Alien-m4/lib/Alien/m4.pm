package Alien::m4;

use strict;
use warnings;
use base qw( Alien::Base );

# ABSTRACT: Find or build GNU m4
our $VERSION = '0.21'; # VERSION


sub alien_helper
{
  my($class) = @_;
  return {
    m4 => sub { $class->exe },
  };
}

sub exe
{
  my($class) = @_;
  $class->runtime_prop->{command} || 'm4';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::m4 - Find or build GNU m4

=head1 VERSION

version 0.21

=head1 SYNOPSIS

From a Perl script

 use Alien::m4;
 use Env qw( @PATH );
 unshift @PATH, Alien::m4->bin_dir;  # m4 is now in your path

From Alien::Base Build.PL

 use Alien:Base::ModuleBuild;
 my $builder = Module::Build->new(
   ...
   alien_bin_requires => {
     'Alien::m4' => '0.07',
   },
   ...
 );
 $builder->create_build_script;

=head1 DESCRIPTION

This package can be used by other CPAN modules that require GNU m4.

=head1 METHODS

=head2 exe

 my $m4 = Alien::m4->exe;

Returns the "name" of m4.  Normally this is C<m4>, but on some platforms
it may be gm4 or gnum4, or whatever is specified by C<$ENV{M4}>.

=head1 HELPERS

=head2 m4

 %{m4}

Returns the name of the m4 command.  Usually just C<m4>.

=head1 CAVEATS

Why GNU m4?  Many Unixen come with BSD or other variants of m4 which are
perfectly good.  Unfortunately, the main use case for this module is
L<Alien::Autotools> and friends.  Autoconf requires the GNU m4, probably
for political reasons, possibly for technical reasons.  If you are using
one of these Unixen, don't despair, you can usually install the GNU
version of m4 either by building from source or by installing a binary
package, with either the name C<gm4> or C<gnum4>, and this module will
find it, and L<Alien::Autotools> will be able to use it.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
