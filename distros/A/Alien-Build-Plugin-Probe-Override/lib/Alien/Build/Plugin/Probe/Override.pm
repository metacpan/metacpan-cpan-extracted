package Alien::Build::Plugin::Probe::Override;

use strict;
use warnings;
use 5.008001;
use Alien::Build::Plugin;
use Path::Tiny qw( path );

# ABSTRACT: Override on a per-alien basis
our $VERSION = '0.03'; # VERSION


sub init
{
  my($self, $meta) = @_;
  
  $meta->register_hook(
    override => sub {
      my($build) = @_;

      if(Alien::Build::rc->can('override'))
      {
        foreach my $try (qw( stage prefix ))
        {
          my $class = path($build->install_prop->{$try})->basename;
          if($class =~ /^Alien-/)
          {
            my $override = Alien::Build::rc::override($class);
            if($override)
            {
              if($override =~ /^(system|share|default)$/)
              {
                $build->log("override for $class => $override");
                return $override;
              }
              else
              {
                $build->log("override for $class => $override is not valid");
              }
            }
          }
        }
      }
      
      $ENV{ALIEN_INSTALL_TYPE} || '';
    },
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Build::Plugin::Probe::Override - Override on a per-alien basis

=head1 VERSION

version 0.03

=head1 SYNOPSIS

in your C<~/.alienbuild/rc.pl>:

 preload 'Probe::Override';
 
 sub override {
   my($dist) = @_;
   return 'system'  if $dist eq 'Alien-gmake';
   return 'share'   if $dist eq 'Alien-FFI';
   return 'default' if $dist eq 'Alien-libuv';  # lets the alienfile choose
   return ''; # fall back on $ENV{ALIEN_INSTALL_TYPE}
 };

=head1 DESCRIPTION

This L<alienfile> plugin allows you to override the install type (either
C<share>, C<system> or C<default>) on a per-Alien basis.  All you have to
do is preload this plugin and then provide a subroutine override, which
takes a dist name (similar to a module name, but with dashes instead of
double colon).  It should return one of:

=over 4

=item system

For a system install

=item share

For a share install

=item default

Fallback on the L<alienfile> default.

=item C<''>

Fallback first on C<ALIEN_INSTALL_TYPE> and then on the L<alienfile> default.

=back

=head1 SEE ALSO

=over 4

=item L<alienfile>

=item L<Alien::Build>

=item L<Alien::Build::Plugin::Probe::OverrideCI>

=back

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Roy Storey (KIWIROY)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
