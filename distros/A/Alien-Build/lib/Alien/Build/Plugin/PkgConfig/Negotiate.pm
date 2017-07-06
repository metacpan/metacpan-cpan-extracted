package Alien::Build::Plugin::PkgConfig::Negotiate;

use strict;
use warnings;
use Alien::Build::Plugin;
use Carp ();

# ABSTRACT: Package configuration negotiation plugin
our $VERSION = '0.52'; # VERSION


has '+pkg_name' => sub {
  Carp::croak "pkg_name is a required property";
};


has minimum_version => undef;

sub _pick
{
  my($class) = @_;
  
  if(eval q{ use PkgConfig::LibPkgConf 0.04; 1 })
  {
    return 'PkgConfig::LibPkgConf';
  }
  
  require Alien::Build::Plugin::PkgConfig::CommandLine;
  if(Alien::Build::Plugin::PkgConfig::CommandLine->new(pkg_name => 'foo')->bin_name)
  {
    return 'PkgConfig::CommandLine';
  }
  
  return 'PkgConfig::PP';
}

sub init
{
  my($self, $meta) = @_;
    
  $self->subplugin($self->_pick,
    pkg_name        => $self->pkg_name,
    minimum_version => $self->minimum_version,
  )->init($meta);

  $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Build::Plugin::PkgConfig::Negotiate - Package configuration negotiation plugin

=head1 VERSION

version 0.52

=head1 SYNOPSIS

 use alienfile;
 plugin 'PkgConfig' => (
   pkg_name => 'libfoo',
 );

=head1 DESCRIPTION

This plugin provides Probe and Gather steps for pkg-config based packages.  It picks
the best C<PkgConfig> plugin depending your platform and environment.

=head1 PROPERTIES

=head2 pkg_name

The package name.

=head2 minimum_version

The minimum required version that is acceptable version as provided by the system.

=head1 SEE ALSO

L<Alien::Build>, L<alienfile>, L<Alien::Build::MM>, L<Alien>

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Diab Jerius (DJERIUS)

Roy Storey

Ilya Pavlov

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
