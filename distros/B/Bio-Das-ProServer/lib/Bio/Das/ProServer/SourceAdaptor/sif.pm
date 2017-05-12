#########
# Author:        Andy Jenkinson
# Created:       2008-02-01
# Last Modified: $Date: 2010-11-02 11:57:52 +0000 (Tue, 02 Nov 2010) $ $Author: zerojinx $
# Id:            $Id: sif.pm 688 2010-11-02 11:57:52Z zerojinx $
# Source:        $Source$
# $HeadURL: https://proserver.svn.sourceforge.net/svnroot/proserver/trunk/lib/Bio/Das/ProServer/SourceAdaptor/sif.pm $
#
# SourceAdaptor implementation for Simple Interaction Format files.
#
package Bio::Das::ProServer::SourceAdaptor::sif;
use strict;
use warnings;
use Carp;
use base qw(Bio::Das::ProServer::SourceAdaptor);

our $VERSION = do { my ($v) = (q$LastChangedRevision: 688 $ =~ /\d+/mxsg); $v; };

sub capabilities {
  return { 'interaction' => '1.0' };
}

sub build_interaction {
  my ($self, $args) = @_;
  my $struct = $self->transport->query($args);

  my $coord_sys = $self->coordinates_full()->[0]->{description};
  my @params = qw(dbSource dbSourceCvId dbVersion);

  my @interactions = @{ $struct->{'interactions'} };
  my @interactors  = @{ $struct->{'interactors'}  };

  $self->{debug} && carp sprintf q(Found %d interactions with %d interactors),
                    scalar @interactions,
                    scalar @interactors;

  for my $param (@params) {
    for my $interaction (@interactions) {
      $interaction->{$param} = $self->config()->{"interaction.$param"};
    }
    for my $participant (@interactors) {
      $participant->{$param} = $self->config()->{"interactor.$param"};
      $participant->{'dbCoordSys'} = $coord_sys;
    }
  }

  return $struct;
}

1;
__END__

=head1 NAME

Bio::Das::ProServer::SourceAdaptor::sif

=head1 VERSION

$LastChangedRevision: 688 $

=head1 SYNOPSIS

  Interactions involving 001:
  <host>/das/<source>/interaction?interactor=001
  
  Interactions between 001 and 002
  <host>/das/<source>/interaction?interactor=001;interactor=002

=head1 DESCRIPTION

Serves up interaction DAS responses from 'Simple Interaction Format' (SIF) files.
See L<http://www.cytoscape.org/cgi-bin/moin.cgi/Cytoscape_User_Manual/Network_Formats|http://www.cytoscape.org/cgi-bin/moin.cgi/Cytoscape_User_Manual/Network_Formats>
http://www.cytoscape.org/cgi-bin/moin.cgi/Cytoscape_User_Manual/Network_Formats
for details of the file format.

=head1 CONFIGURATION AND ENVIRONMENT

  [mysif]
  adaptor                  = sif
  state                    = on
  transport                = sif
  ; the main SIF file:
  filename                 = /data/interactions.sif
  ; zero or more attribute files:
  attributes               = /data/node-attribute.noa ; /data/edge-attributes.eda
  ; coordinates will be used as 'dbCoordSys':
  coordinates              = MyCoordSys -> 001
  ; static parameters:
  interaction.dbSource     = MyInteractionDB
  interaction.dbSourceCvId = MIDB
  interaction.dbVersion    = 12
  interactor.dbSource      = MyProteinDB
  interactor.dbSourceCvId  = MPDB
  interactor.dbVersion     = 23

=head1 DIAGNOSTICS

Run ProServer with the -debug flag.

=head1 SUBROUTINES/METHODS

=head2 build_interaction - Builds the DAS response

See documentation in superclass.

=head2 capabilities - Provides details of the adaptor's capabilities

This adaptor supports the 'interaction' command only.

=head1 SEE ALSO

=over

=item L<Bio::Das::ProServer::SourceAdaptor::Transport::sif|Bio::Das::ProServer::SourceAdaptor::Transport::sif>

=item L<http://www.cytoscape.org/cgi-bin/moin.cgi/Cytoscape_User_Manual/Network_Formats|http://www.cytoscape.org/cgi-bin/moin.cgi/Cytoscape_User_Manual/Network_Formats> Cytoscape - SIF

=item L<http://www.cytoscape.org/cgi-bin/moin.cgi/Cytoscape_User_Manual/Attributes|http://www.cytoscape.org/cgi-bin/moin.cgi/Cytoscape_User_Manual/Attributes> Cytoscape - Attributes

=back

=head1 DEPENDENCIES

=over

=item L<Carp|Carp> 

=item L<Bio::Das::ProServer::SourceAdaptor|Bio::Das::ProServer::SourceAdaptor> 

=item L<Bio::Das::ProServer::SourceAdaptor::Transport::sif|Bio::Das::ProServer::SourceAdaptor::Transport::sif>

=back

=head1 BUGS AND LIMITATIONS

The Simple Interaction Format is very simple, and therefore only supports a
limited range of DAS annotation details. It also only handles binary
interactions (i.e. those with exactly two interactors).

=head1 INCOMPATIBILITIES

None reported.

=head1 AUTHOR

Andy Jenkinson <andy.jenkinson@ebi.ac.uk>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 EMBL-EBI

=cut