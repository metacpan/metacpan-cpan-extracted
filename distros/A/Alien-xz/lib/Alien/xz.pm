package Alien::xz;

use strict;
use warnings;
use base qw( Alien::Base );

# ABSTRACT: Find or build xz
our $VERSION = '0.08'; # VERSION




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

version 0.08

=head1 SYNOPSIS

In your Makefile.PL:

 use ExtUtils::MakeMaker;
 use Alien::Base::Wrapper ();

 WriteMakefile(
   Alien::Base::Wrapper->new('Alien::xz')->mm_args2(
     # MakeMaker args
     NAME => 'My::XS',
     ...
   ),
 );

In your Build.PL:

 use Module::Build;
 use Alien::Base::Wrapper qw( Alien::xz !export );

 my $builder = Module::Build->new(
   ...
   configure_requires => {
     'Alien::xz' => '0',
     ...
   },
   Alien::Base::Wrapper->mb_args,
   ...
 );

 $build->create_build_script;

In your script or module:

 use Alien::xz;
 use Env qw( @PATH );

 unshift @PATH, Alien::xz->bin_dir;

=head1 DESCRIPTION

This package can be used by other CPAN modules that require xz,
the compression utility, or liblzma, which comes with it.

=head1 HELPERS

=head2 xz

 %{xz}

Returns the name of the xz command.  Usually just C<xz>.

=head1 SEE ALSO

L<Alien>, L<Alien::Base>, L<Alien::Build::Manual::AlienUser>

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Dylan William Hardison (dylanwh, DHARDISON)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
