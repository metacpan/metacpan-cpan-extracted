package Alien::AntTweakBar;

use 5.008;
use strict;
use warnings;

use Carp;
use Alien::AntTweakBar::ConfigData;
use File::ShareDir qw(dist_dir);
use File::Spec::Functions qw(catdir);

=head1 NAME

Alien::AntTweakBar - perl5 alien library for AntTweakBar

=head1 DESCRIPTION

=for HTML <p>
<img src="http://anttweakbar.sourceforge.net/doc/data/media/tools/anttweakbar/twsimpledx11-128.jpg" style="max-width:100%;">
</p>

Alien::AntTweakbar is a Perl module that provides dependencies (libraries, platform-dependent build-scripts) of AntTweakBar. Install this module to be able to install and use L<AntTweakBar> for your Perl.

AntTweakBar (see L<http://anttweakbar.sourceforge.net/>) is nice tiny
GUI library for OpenGL/SDL/DirectX applications.

Alien::AntTweakbar is not perl bindings for AntTweakBar but the (static) library itself.

=head1 TODO

DirectX build is broken. Patches are very welcome.

=head1 AUTHOR

Ivan Baidakou E<lt>dmol@(gmx.com)E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Ivan Baidakou

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<AntTweakBar>, L<SDL>, L<OpenGL>, L<http://anttweakbar.sourceforge.net/>

=cut

our $VERSION = '0.03';

sub config
{
  my ($package, $param) = @_;
  return unless ($param =~ /[a-z0-9_]*/i);
  my $subdir = Alien::AntTweakBar::ConfigData->config('share_subdir');
  unless ($subdir) {
      # we are using tidyp already installed librarry on your system not compiled one
      # therefore no additinal magic needed
      return Alien::AntTweakBar::ConfigData->config('config')->{$param};
  }
  my $share_dir = dist_dir('Alien-AntTweakBar');
  my $real_prefix = catdir($share_dir, $subdir);
  my $val = Alien::AntTweakBar::ConfigData->config('config')->{$param};
  return unless $val;
  $val =~ s/\@PrEfIx\@/$real_prefix/g; # handle @PrEfIx@ replacement
  return $val;
}

1;
