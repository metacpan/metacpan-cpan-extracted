#########
# Author:        rmp
# Maintainer:    rmp
# Created:       2003-12-12
# Last Modified: $Date: 2010-11-02 11:37:11 +0000 (Tue, 02 Nov 2010) $ $Author: zerojinx $
# Id:            $Id: SourceHydra.pm 687 2010-11-02 11:37:11Z zerojinx $
# Source:        $Source: /nfs/team117/rmp/tmp/Bio-Das-ProServer/Bio-Das-ProServer/lib/Bio/Das/ProServer/SourceHydra.pm,v $
# $HeadURL: https://proserver.svn.sourceforge.net/svnroot/proserver/trunk/lib/Bio/Das/ProServer/SourceHydra.pm $
#
# Dynamic SourceAdaptor broker
#
package Bio::Das::ProServer::SourceHydra;
use strict;
use warnings;
use Bio::Das::ProServer::SourceAdaptor;
use English qw(-no_match_vars);
use Carp;

our $VERSION = do { my ($v) = (q$Revision: 687 $ =~ /\d+/mxsg); $v; };

sub new {
  my ($class, $defs) = @_;
  my $self = {
	      'dsn'    => $defs->{'dsn'}    || q(),
              'config' => $defs->{'config'},
	      'debug'  => $defs->{'debug'}  || undef,
             };

  bless $self, $class;
  $self->init($defs);
  return $self;
}

sub init {return;}

sub transport {
  my $self = shift;

  if(!exists $self->{'_transport'} && $self->config->{'transport'}) {

    my $transport = 'Bio::Das::ProServer::SourceAdaptor::Transport::'.$self->config->{'transport'};
    eval "require $transport" or do { ## no critic (BuiltinFunctions::ProhibitStringyEval)
      carp $EVAL_ERROR;
      return;
    };

    $self->{'_transport'} = $transport->new({
					     config => $self->config(),
					    });
  }

  return $self->{'_transport'};
}

sub config {
  my ($self, $config) = @_;
  if($config) {
    $self->{'config'} = $config;
  }
  return $self->{'config'};
}

sub sources {return;}

1;

__END__

=head1 NAME

Bio::Das::ProServer::SourceHydra - A runtime factory for B::D::P::SourceAdaptors

=head1 VERSION

$Revision: 687 $

=head1 SYNOPSIS

  Inherit and extend this class to provide hydra implementations

=head1 AUTHOR

Roger Pettett <rmp@sanger.ac.uk>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007 The Sanger Institute

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=head1 DESCRIPTION

The SourceHydra's role is to clone a series of SourceAdaptors of the
same type but each configured in a (systematically) different way, but
with only one configuration file section.

For example the hydra is pivotal in the Ensembl upload service where
each data upload is of the same structure and loaded into a numbered
table in a database. In order to provide a valid DSN for each uploaded
source, the hydra then clones a series of dbi-based sources, pointing
them all at the upload database but each one at a different table.

The hydra can also be useful in situations such as the provision of
similar sources for different species where the data are in different
databases but have the same structure in each.

=head1 SUBROUTINES/METHODS

=head2 new : Constructor

  my $hydra = Bio::Das::ProServer::SourceHydra->new({
    'config' => $cfg, # The config section for this hydra
    'debug'  => $dbg, # Boolean debug flag
  });

=head2 init : Post-construction initialisation method

  Implemented in subclasses if necessary (not usually)

=head2 transport : Build the relevant transport configured for this adaptor

  my $transport = $hydra->transport();

=head2 config : Accessor for config section for this hydra (set at construction)

  my $cfg = $hydra->config();

=head2 sources : Implemented in subclasses - returns an of source names

  my @sources = $hydra->sources();

=head1 CONFIGURATION AND ENVIRONMENT

 Configure in proserver.ini using:
   hydra = <impl>

=head1 DIAGNOSTICS

Set $self->{'debug'} = 1;
Or B::D::P::SourceHydra::impl->new({'debug'=>1});

=head1 DEPENDENCIES

  Bio::Das::ProServer::SourceAdaptor

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=cut
