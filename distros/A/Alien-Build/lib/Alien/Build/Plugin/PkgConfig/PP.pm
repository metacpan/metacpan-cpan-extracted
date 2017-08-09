package Alien::Build::Plugin::PkgConfig::PP;

use strict;
use warnings;
use Alien::Build::Plugin;
use Carp ();
use Env qw( @PKG_CONFIG_PATH );

# ABSTRACT: Probe system and determine library or tool properties using PkgConfig.pm
our $VERSION = '0.91'; # VERSION


has '+pkg_name' => sub {
  Carp::croak "pkg_name is a required property";
};


has minimum_version => undef;

sub _cleanup
{
  my($value) = @_;
  $value =~ s{\s*$}{ };
  $value;
}

sub init
{
  my($self, $meta) = @_;
  
  my $caller = caller;
  
  if($caller ne 'Alien::Build::Plugin::PkgConfig::Negotiate')
  {
    $meta->add_requires('configure' => 'PkgConfig' => '0.14026');
  }
  
  my($pkg_name, @alt_names) = (ref $self->pkg_name) ? (@{ $self->pkg_name }) : ($self->pkg_name);

  $meta->register_hook(
    probe => sub {
      my($build) = @_;
      $build->runtime_prop->{legacy}->{name} ||= $pkg_name;

      my $pkg = PkgConfig->find($pkg_name);
      die "package @{[ $pkg_name ]} not found" if $pkg->errmsg;
      if(defined $self->minimum_version)
      {
        my $version = PkgConfig::Version->new($pkg->pkg_version);
        my $need    = PkgConfig::Version->new($self->minimum_version);
        if($version < $need)
        {
          die "package @{[ $pkg_name ]} is not recent enough";
        }
      }
      
      foreach my $alt (@alt_names)
      {
        my $pkg = PkgConfig->find($alt);
        die "package $alt not found" if $pkg->errmsg;
      }
      
      'system';
    },
  );

  my $gather = sub {
    my($build) = @_;
    require PkgConfig;

    foreach my $name ($pkg_name, @alt_names)
    {
      my $pkg = PkgConfig->find($name, search_path => [@PKG_CONFIG_PATH]);
      if($pkg->errmsg)
      {
        $build->log("Trying to load the pkg-config information from the source code build");
        $build->log("of your package failed");
        $build->log("You are currently using the pure-perl implementation of pkg-config");
        $build->log("(AB Plugin is named PkgConfig::PP, which uses PkgConfig.pm");
        $build->log("It may work better with the real pkg-config.");
        $build->log("Try installing your OS' version of pkg-config or unset ALIEN_BUILD_PKG_CONFIG");
        die "second load of PkgConfig.pm @{[ $name ]} failed: @{[ $pkg->errmsg ]}"
      }
      my %prop;
      $prop{cflags}  = _cleanup scalar $pkg->get_cflags;
      $prop{libs}    = _cleanup scalar $pkg->get_ldflags;
      $prop{version} = $pkg->pkg_version;
      $pkg = PkgConfig->find($name, static => 1, search_path => [@PKG_CONFIG_PATH]);
      $prop{cflags_static} = _cleanup scalar $pkg->get_cflags;
      $prop{libs_static}   = _cleanup scalar $pkg->get_ldflags;
      $build->runtime_prop->{alt}->{$name} = \%prop;
    }
    foreach my $key (keys %{ $build->runtime_prop->{alt}->{$pkg_name} })
    {
      $build->runtime_prop->{$key} = $build->runtime_prop->{alt}->{$pkg_name}->{$key};
    }
    if(keys %{ $build->runtime_prop->{alt} } == 1)
    {
      delete $build->runtime_prop->{alt};
    }
  };
  
  $meta->register_hook(
    gather_system => $gather,
  );

  $meta->register_hook(
    gather_share => $gather,
  );
  
  $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Build::Plugin::PkgConfig::PP - Probe system and determine library or tool properties using PkgConfig.pm

=head1 VERSION

version 0.91

=head1 SYNOPSIS

 use alienfile;
 plugin 'PkgConfig::PP' => (
   pkg_name => 'libfoo',
 );

=head1 DESCRIPTION

Note: in most case you will want to use L<Alien::Build::Plugin::Download::Negotiate>
instead.  It picks the appropriate fetch plugin based on your platform and environment.
In some cases you may need to use this plugin directly instead.

This plugin provides Probe and Gather steps for pkg-config based packages.  It uses
L<PkgConfig> to accomplish this task.

=head1 PROPERTIES

=head2 pkg_name

The package name.  If this is a list reference then .pc files with all those package
names must be present.

=head2 minimum_version

The minimum required version that is acceptable version as provided by the system.

=head1 SEE ALSO

L<Alien::Build::Plugin::PkgConfig::Negotiate>, L<Alien::Build>, L<alienfile>, L<Alien::Build::MM>, L<Alien>

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

mohawk2

Vikas N Kumar (vikasnkumar)

Flavio Poletti (polettix)

Salvador Fandiño (salva)

Gianni Ceccarelli (dakkar)

Pavel Shaydo (zwon, trinitum)

Kang-min Liu (劉康民, gugod)

Nicholas Shipp (nshp)

Juan Julián Merelo Guervós (JJ)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
