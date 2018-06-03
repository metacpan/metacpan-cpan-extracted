package Alien::Build::Plugin::PkgConfig::Negotiate;

use strict;
use warnings;
use Alien::Build::Plugin;
use Alien::Build::Plugin::PkgConfig::PP;
use Alien::Build::Plugin::PkgConfig::LibPkgConf;
use Alien::Build::Plugin::PkgConfig::CommandLine;
use Alien::Build::Util qw( _perl_config );
use Carp ();

# ABSTRACT: Package configuration negotiation plugin
our $VERSION = '1.43'; # VERSION


has '+pkg_name' => sub {
  Carp::croak "pkg_name is a required property";
};


has minimum_version => undef;


sub pick
{
  my($class) = @_;

  return $ENV{ALIEN_BUILD_PKG_CONFIG} if $ENV{ALIEN_BUILD_PKG_CONFIG};
  
  if(Alien::Build::Plugin::PkgConfig::LibPkgConf->available)
  {
    return 'PkgConfig::LibPkgConf';
  }
  
  if(Alien::Build::Plugin::PkgConfig::CommandLine->available)
  {
    # TODO: determine environment or flags necessary for using pkg-config
    # on solaris 64 bit.
    # Some advice on pkg-config and 64 bit Solaris
    # https://docs.oracle.com/cd/E53394_01/html/E61689/gplhi.html
    if(! (_perl_config('osname') eq 'solaris' && _perl_config('ptrsize') == 8))
    {
      return 'PkgConfig::CommandLine';
    }
  }
  
  if(Alien::Build::Plugin::PkgConfig::PP->available)
  {
    return 'PkgConfig::PP';
  }
  else
  {
    # this is a fata error.  because we check for a pkg-config implementation
    # at configure time, we expect at least one of these to work.  (and we
    # fallback on installing PkgConfig.pm as a prereq if nothing else is avail).
    # we therefore expect at least one of these to work, if not, then the configuration
    # of the system has shifted from underneath us.
    Carp::croak("Could not find an appropriate pkg-config or pkgconf implementation, please install PkgConfig.pm, PkgConfig::LibPkgConf, pkg-config or pkgconf");
  }
}

sub init
{
  my($self, $meta) = @_;

  my $plugin = $self->pick;
  Alien::Build->log("Using PkgConfig plugin: $plugin");
  
  if(ref($self->pkg_name) eq 'ARRAY')
  {
    $meta->add_requires('configure', 'Alien::Build::Plugin::PkgConfig::Negotiate' => '0.79');
  }
  
  my @args;
  push @args, pkg_name         => $self->pkg_name;
  push @args, register_prereqs => 0;
  push @args, minimum_version  => $self->minimum_version if defined $self->minimum_version;
  
  $meta->apply_plugin($plugin, @args);

  $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Build::Plugin::PkgConfig::Negotiate - Package configuration negotiation plugin

=head1 VERSION

version 1.43

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

=head1 METHODS

=head2 pick

 my $name = Alien::Build::Plugijn::PkgConfig::Negotiate->pick;

Returns the name of the negotiated plugin.

=head1 ENVIRONMENT

=over 4

=item ALIEN_BUILD_PKG_CONFIG

If set, this plugin will be used instead of the build in logic
which attempts to automatically pick the best plugin.

=back

=head1 SEE ALSO

L<Alien::Build>, L<alienfile>, L<Alien::Build::MM>, L<Alien>

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Diab Jerius (DJERIUS)

Roy Storey

Ilya Pavlov

David Mertens (run4flat)

Mark Nunberg (mordy, mnunberg)

Christian Walde (Mithaldu)

Brian Wightman (MidLifeXis)

Zaki Mughal (zmughal)

mohawk (mohawk2, ETJ)

Vikas N Kumar (vikasnkumar)

Flavio Poletti (polettix)

Salvador Fandiño (salva)

Gianni Ceccarelli (dakkar)

Pavel Shaydo (zwon, trinitum)

Kang-min Liu (劉康民, gugod)

Nicholas Shipp (nshp)

Juan Julián Merelo Guervós (JJ)

Joel Berger (JBERGER)

Petr Pisar (ppisar)

Lance Wicks (LANCEW)

Ahmad Fatoum (a3f, ATHREEF)

José Joaquín Atria (JJATRIA)

Duke Leto (LETO)

Shoichi Kaji (SKAJI)

Shawn Laffan (SLAFFAN)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
