package Alien::Build::Plugin::Gather::Dino;

use strict;
use warnings;
use 5.008001;
use Alien::Build::Plugin;
use FFI::CheckLib qw( find_lib );
use Path::Tiny qw( path );

# ABSTRACT: Experimental support for dynamic share Alien install
our $VERSION = '0.05'; # VERSION


sub init
{
  my($self, $meta) = @_;
  
  $meta->after_hook(
    gather_share => sub {
      my($build) = @_;
      
      foreach my $path (map { path('.')->absolute->child($_) } qw( bin lib dynamic ))
      {
        next unless -d $path;
        if(find_lib(lib => '*', libpath => $path->stringify, systempath => []))
        {
          push @{ $build->runtime_prop->{rpath} }, $path->basename;
        }
      }
    },
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Build::Plugin::Gather::Dino - Experimental support for dynamic share Alien install

=head1 VERSION

version 0.05

=head1 SYNOPSIS

 use alienfile;
 plugin 'Gather::Dino';

=head1 DESCRIPTION

This L<alienfile> plugins find directories inside the share directory with dynamic libraries in them
for C<share> type installs.  This information is necessary at either build or run-time by XS modules.
For various reasons you are probably better off building static libraries instead.  For more detail
and rational see the runtime documentation L<Alien::Role::Dino>.

=head1 SEE ALSO

=over 4

=item L<Alien::Role::Dino>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
