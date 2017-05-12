#########
# Author: rmp
# Maintainer: rmp
# Created: 2003-06-03
# Last Modified: 2003-06-03
#
# Pro source/parser configuration
#
package Bio::Das::ProServer::Config;

=head1 AUTHOR

Roger Pettett <rmp@sanger.ac.uk>.

Based on AGPServer by

Tony Cox <avc@sanger.ac.uk>.

Copyright (c) 2003 The Sanger Institute

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut

use strict;
use Bio::Das::ProServer::SourceAdaptor;
use Bio::Das::ProServer::SourceHydra;
use Sys::Hostname;
use Config::IniFiles;

sub new {
  my ($class, $inifile) = @_;
  my $self   = {
		'hostname'   => &Sys::Hostname::hostname(),
		'prefork'    => '5',
		'maxclients' => '10',
		'port'       => '9000',
		'adaptors' => {},
	       };
  ($inifile) = $inifile =~ /([a-zA-Z0-9_\/\.\-]+)/;

  if($inifile && -f $inifile) {
    my $conf = Config::IniFiles->new(
				     -file => $inifile,
				    );
    #########
    # load general parameters
    #
    for my $f (qw(hostname interface prefork maxclients pidfile logfile port ensemblhome oraclehome bioperlhome http_proxy)) {
      $self->{$f} = $conf->val("general", $f) if($conf->val("general", $f));
	printf STDERR qq(**** %s => %s ****\n), $f, ($self->{$f}||"");
    }

    #########
    # build the adaptors substructure
    #
    for my $s ($conf->Sections()) {
      next if ($s eq "general");
      print STDERR qq(Configuring Adaptor $s );
      for my $p ($conf->Parameters($s)) {
	$self->{'adaptors'}->{$s}->{$p} = $conf->val($s, $p);
	print STDERR $self->{'adaptors'}->{$s}->{$p}, "\n" if($p eq "state");
      }
    }
  }

  bless $self,$class;
  return $self;
}

sub port {
  my $self = shift;
  ($self->{'port'}) = $self->{'port'} =~ /([0-9]+)/;
  return $self->{'port'};
}

sub prefork {
  my $self = shift;
  ($self->{'prefork'}) = $self->{'prefork'} =~ /([0-9]+)/;
  return $self->{'prefork'};
}

sub maxclients {
  my $self = shift;
  ($self->{'maxclients'}) = $self->{'maxclients'} =~ /([0-9]+)/;
  return $self->{'maxclients'};
}

sub pidfile {
  my $self = shift;
  ($self->{'pidfile'}) = ($self->{'pidfile'}||"") =~ /([a-zA-Z0-9\/\-_\.]+)/;
  return $self->{'pidfile'};
}

sub logfile {
  my $self = shift;
  ($self->{'logfile'}) = ($self->{'logfile'}||"") =~ /([a-zA-Z0-9\/\-_\.]+)/;
  return $self->{'logfile'};
}

sub host {
  my $self = shift;
  my $h    = $self->{'interface'} || $self->{'hostname'};
  ($self->{'hostname'}) = $h =~ /([a-zA-Z0-9\/\-_\.]+)/;
  return $self->{'hostname'};
}

#########
# build all known SourceAdaptors (including those Hydra-based)
#
sub adaptors {
  my $self     = shift;
  my @adaptors = ();

  for my $dsn (grep { ($self->{'adaptors'}->{$_}->{'state'} || "off") eq "on"; } keys %{$self->{'adaptors'}}) {
    if(substr($dsn, 0, 5) eq "hydra") {
      for my $managed_source ($self->hydra($dsn)->sources()) {
	my $adaptor = $self->_hydra_adaptor($dsn, $managed_source);
	push @adaptors, $adaptor if($adaptor);
      }

    } else {
      push @adaptors, $self->adaptor($dsn);
    }
  }
  return @adaptors;
}

#########
# build a SourceAdaptor given a dsn (may be a hydra-based adaptor)
#
sub adaptor {
  my ($self, $dsn) = @_;

  if($dsn && exists $self->{'adaptors'}->{$dsn} && $self->{'adaptors'}->{$dsn}->{'state'} eq "on") {
    #########
    # normal adaptor
    #
    my $adaptortype = "Bio::Das::ProServer::SourceAdaptor::".$self->{'adaptors'}->{$dsn}->{'adaptor'};
    eval "require $adaptortype";
    if($@) {
      warn $@;
      return;
    }

    $self->{'adaptors'}->{$dsn}->{'obj'} ||= $adaptortype->new({
								'dsn'      => $dsn,
								'config'   => $self->{'adaptors'}->{$dsn},
								'hostname' => $self->{'hostname'},
								'port'     => $self->{'port'},
							       });
    return $self->{'adaptors'}->{$dsn}->{'obj'};

  } elsif($dsn && substr($dsn, 0, 5) eq "hydra") {
    #########
    # hydra adaptor
    #
    return $self->hydra_adaptor($dsn);

  } else {
    #########
    # generic adaptor
    #
    $self->{'_genadaptor'} ||= Bio::Das::ProServer::SourceAdaptor->new({
									'hostname' => $self->{'hostname'},
									'port'     => $self->{'port'},
									'config'   => $self,
								       });
    return $self->{'_genadaptor'};
  }
}

#sub transport {
#  my ($self, $dsn) = @_;
#  return $self->{'adaptors'}->{$dsn}->{'transport'} || "unknown";
#}

#########
# is the requested dsn known about?
#
sub knows {
  my ($self, $dsn) = @_;

  #########
  # test plain sources
  #
  return 1 if(exists $self->{'adaptors'}->{$dsn} && $self->{'adaptors'}->{$dsn}->{'state'} eq "on");

  #########
  # test hydra sources (slower)
  #
  for my $hydraname (grep { substr($_, 0, 5) eq "hydra" } keys %{$self->{'adaptors'}}) {
    next unless($self->{'adaptors'}->{$hydraname}->{'state'} eq "on");
    my $hydra = $self->hydra($hydraname);
    next unless($hydra);
    return 1 if(grep { $_ eq $dsn } $hydra->sources());
  }
  return undef;
}

sub das_version {
  return "DAS/1.50";
}

#########
# build hydra-based SourceAdaptor given dsn and optional hydraname
#
sub hydra_adaptor {
  my ($self, $dsn, $hydraname) = @_;

  #########
  # sourceadaptor given known hydra
  #
  if($hydraname) {
    return $self->_hydra_adaptor($hydraname, $dsn);
  }

  #########
  # sourceadaptor search
  #
  for my $hydraname (grep { substr($_, 0, 5) eq "hydra" } keys %{$self->{'adaptors'}}) {
    my $adaptor = $self->_hydra_adaptor($hydraname, $dsn);
    $adaptor or next;
    return $adaptor;
  }
}

#########
# build hydra-based SourceAdaptor given dsn and hydraname
#
sub _hydra_adaptor {
  my ($self, $hydraname, $dsn) = @_;

  return unless($self->{'adaptors'}->{$hydraname}->{'state'} eq "on");
  my $config = $self->{'adaptors'}->{$hydraname};
  my $hydra  = $self->hydra($hydraname);

  return unless( grep { $_ eq $dsn } $hydra->sources());

  my $adaptortype = "Bio::Das::ProServer::SourceAdaptor::".$self->{'adaptors'}->{$hydraname}->{'adaptor'};
  eval "require $adaptortype";

  if($@) {
    warn $@;
    return;
  }

  #########
  # build a source adaptor using the dsn from the hydra-managed source and the config for the hydra
  #
  $config->{'hydraname'} = $hydraname;
  return $adaptortype->new({
			    'dsn'       => $dsn,
			    'config'    => $config,
			    'hostname'  => $self->{'hostname'},
			    'port'      => $self->{'port'},
			   });
}

#########
# build SourceHydra for a given dsn/hydraname
#
sub hydra {
  my ($self, $hydraname) = @_;

  unless($self->{'adaptors'}->{$hydraname}->{'_hydra'}) {
    my $hydraimpl = "Bio::Das::ProServer::SourceHydra::".$self->{'adaptors'}->{$hydraname}->{'hydra'};
    eval "require $hydraimpl";
    print STDERR qq(Loaded $hydraimpl\n);
    if($@) {
      warn $@;
      return;
    }

    $self->{'adaptors'}->{$hydraname}->{'_hydra'}  ||= $hydraimpl->new({
									'dsn'    => $hydraname,
									'config' => $self->{'adaptors'}->{$hydraname},
								       });
  }
  return $self->{'adaptors'}->{$hydraname}->{'_hydra'};
}


1;
