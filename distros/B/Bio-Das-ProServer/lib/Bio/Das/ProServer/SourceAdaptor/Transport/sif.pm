#########
# Author:        Andy Jenkinson
# Created:       2008-02-01
# Last Modified: $Date: 2010-11-02 11:57:52 +0000 (Tue, 02 Nov 2010) $ $xuthor$
# Id:            $Id: sif.pm 688 2010-11-02 11:57:52Z zerojinx $
# Source:        $Source$
# $HeadURL: https://proserver.svn.sourceforge.net/svnroot/proserver/trunk/lib/Bio/Das/ProServer/SourceAdaptor/Transport/sif.pm $
#
# Transport implementation for Simple Interaction Format files.
#
package Bio::Das::ProServer::SourceAdaptor::Transport::sif;

use strict;
use warnings;
use Carp;
use base qw(Bio::Das::ProServer::SourceAdaptor::Transport::file);

our $VERSION = do { my ($v) = (q$LastChangedRevision: 688 $ =~ /\d+/mxsg); $v; };

# Access to the transport is via this method (see POD)
sub query {
  my ($self, $args) = @_;
  my $operation =    $args->{'operation'} || 'intersection';
  my @queries   = @{ $args->{'interactors'} || [] };

  # Find interactions matching the query interactors
  my $interactions = $operation eq 'union' || @queries < 2
                     ? $self->_search_any(@queries)
                     : $self->_search_all(@queries);

  if(!scalar keys %{$interactions}) {
    return {
	    interactions => [],
	    interactors  => [],
	   };
  }

  # Add data from edge attribute files
  $self->_add_interaction_attributes($interactions);

  my @interactions = ();
  my $interactors = {};

  for my $interaction (values %{$interactions}) {

    #########
    # Check the interaction passes the filters...
    #
    if ($self->_filter_details( $interaction, $args->{'details'} )) {
      #########
      # If so, add it to the final list...
      #
      push @interactions, $interaction;

      #########
      # ...and add the participants to the list of interactors
      #
      for my $participant (@{ $interaction->{'participants'} }) {
        $interactors->{$participant->{'id'}} ||= {%{ $participant }}; # clone
      }
    }
  }

  #########
  # Add data from node attribute files
  #
  $self->_add_interactor_attributes($interactors);

  return {
          interactors  => [ values %{$interactors} ],
          interactions => \@interactions,
         };
}

sub _search_all {
  my ($self, $q1, $q2, $q3) = @_;
  $q1 || return {}; # No query
  $q3 && return {}; # SIF has only binary interactions
  my $fh    = $self->_fh();
  my $start = tell $fh;

  my $interactions = {};

  my $sep;
  while(<$fh>) {
    chomp;
    # if the file contains tabs, tab is separator
    $sep ||= /\t/mxs ? '\t' : '\s';  ## no critic (Perl::Critic::Policy::ValuesAndExpressions::RequireInterpolationOfMetachars)

    # If looking for 2 interactors, one -has- to be the source node
    if (/^$q1$sep+([^$sep]+$sep+)+$q2($sep|\Z)/mxs || /^$q2$sep+([^$sep]+$sep+)+$q1($sep|\Z)/mxs) {
      $self->_add_interaction($q1, $q2, $interactions);
      last;
    }
  }

  # Reset the filehandle to what it was previously (not necessarily the start..)
  seek $fh, $start, 0;
  return $interactions;
}

sub _search_any {
  my ($self, @queries) = @_;
  @queries || return {}; # No query
  my $fh    = $self->_fh();
  my $start = tell $fh;
  my $interactions = {};

  my $sep;
  while(<$fh>) {
    chomp;
    # if the file contains tabs, tab is separator
    $sep ||= /\t/mxs ? '\t' : '\s';  ## no critic (Perl::Critic::Policy::ValuesAndExpressions::RequireInterpolationOfMetachars)

    # Different result depending on whether the 'hit' is the first node
    my ($source, undef, @targets) = split /$sep+/mxs;

    if (scalar grep {$source eq $_} @queries ) {
      for my $t (@targets) {
	$self->_add_interaction($source, $t, $interactions);
      }

    } else {
      for my $t (@targets) {
	if (scalar grep {$t eq $_} @queries ) {
	  $self->_add_interaction($source, $t, $interactions);
	}
      }
    }
  }

  # Reset the filehandle to what it was previously (not necessarily the start..)
  seek $fh, $start, 0;
  return $interactions;
}

sub _add_interaction {
  my ($self, $x, $y, $interactions) = @_;
  # sort lexographically (interactions are unique)
  if (($x cmp $y) > 0) {
    ($x, $y) = ($y, $x);
  }
  $self->{'debug'} && carp "SIF transport found interaction $x-$y";
  #$interactors->{$x} ||= {'id'=>$x};
  #$interactors->{$y} ||= {'id'=>$y};
  $interactions->{"$x-$y"} ||= {
    'name'         => "$x-$y",
    'participants' => [{'id'=>$x},{'id'=>$y}],
  };
  return;
}

sub _add_interaction_attributes {
  my ($self, $interactions) = @_;

  my @interaction_files = grep {$_->{'type'} eq 'interaction'} $self->_att_fh();

  for my $interaction (values %{$interactions}) {
    for my $file (@interaction_files) {
      my $fh = $file->{'fh'};
      my $sep = $file->{'sep'};
      my $start = tell $fh;
      while (<$fh>) {
        chomp;
        my ($x, $y, $value) = /^([^$sep]+)$sep+[^$sep]+$sep+([^$sep]+)\s*=\s*(.+)/mxs;
        if (($x cmp $y) > 0) {
          ($x, $y) = ($y, $x);
        }
        if ($interaction->{'name'} eq "$x-$y") {
          $self->{'debug'} && carp "SIF transport found $file->{property} property for interaction $x-$y";
          push @{ $interaction->{'details'} }, {
            'property' => $file->{'property'},
            'value'    => $value,
          };
          last;
        }
      }
      seek $fh, $start, 0;
    }
  }

  return;
}

sub _add_interactor_attributes {
  my ($self, $interactors) = @_;

  my @interactor_files  = grep {$_->{'type'} eq 'interactor'}  $self->_att_fh();

  for my $interactor (values %{$interactors}) {
    for my $file (@interactor_files) {
      my $fh = $file->{'fh'};
      my $start = tell $fh;
      while (<$fh>) {
        chomp;
        my ($id, $value) = split /\s*=\s*/mxs;
        if ($id eq $interactor->{'id'}) {
          $self->{'debug'} && carp "SIF transport found $file->{property} property for interactor $id";
          push @{ $interactor->{'details'} }, {
            'property' =>$file->{'property'},
            'value'    =>$value,
          };
          last;
        }
      }
      seek $fh, $start, 0;
    }
  }

  return;
}

sub _att_fh {
  my $self = shift;

  if (!exists $self->{'fh_att'}) {
    $self->{'fh_att'} = [];
    for my $fn (split /\s*[;,]\s*/mxs, $self->config->{'attributes'}||q()) {
      my $fh;
      open $fh, '<', $fn or croak qq(Could not open $fn); ## no critic (Perl::Critic::Policy::InputOutput::RequireBriefOpen)
      my $property = <$fh>;
      chomp $property;
      my $start = tell $fh;
      my $line = <$fh>;
      my $sep = $line =~ m/\t/mxs ? '\t' : '\s'; ## no critic (Perl::Critic::Policy::ValuesAndExpressions::RequireInterpolationOfMetachars)
      my $type = $line =~ /^[^$sep]+$sep+[^$sep]+$sep+[^$sep]+\s*=/mxs ? 'interaction' : 'interactor';
      seek $fh, $start, 0;
      push @{ $self->{'fh_att'} }, {'fh'=>$fh,'type'=>$type,'property'=>$property,'sep'=>$sep};
    }
  }
  return wantarray ? @{ $self->{'fh_att'} } : $self->{'fh_att'};
}

sub _filter_details {
  my ($self, $test, $details) = @_;
  TEST: for my $key ( keys %{ $details || {} }) {
    for my $detail (@{ $test->{'details'} || [] }) {
      # The object does have this property...
      if ($detail->{'property'} eq $key) {
        my $val = $details->{$key};
        if (!defined $val || $detail->{'value'} eq $val) {
          # And it's the correct value
          next TEST;
        }
        return 0;
      }
    }
    return 0;
  }
  return 1;
}

sub DESTROY {
  my $self = shift;
  my @filehandles = ($self->{'fh'}, map {$_->{'fh'}} @{ $self->{'fh_att'}||[] });
  for my $fh (@filehandles) {
    $fh && close $fh;
  }
  return;
}

1;
__END__

=head1 NAME

Bio::Das::ProServer::SourceAdaptor::Transport::sif

=head1 VERSION

$LastChangedRevision: 688 $

=head1 SYNOPSIS

my $hInteractions = $oTransport->query('interactorA');
my $hInteractions = $oTransport->query('interactorA', 'interactorB');

=head1 DESCRIPTION

A data transport exposing interactions stored in a SIF file, along with
attributes stored in Cytoscape attribute files. Access is via the 'query' method.

=head1 FILE FORMAT

Each line of a Simple Interaction Format (SIF) file describes one or more binary
interactions, and takes the form:
  nodeA lineType nodeB [nodeC ...]

This example describes a protein-protein interaction between interactorA and interactorB:
  interactorA pp interactorB

This example describes three separate interactions, each involving interactorA:
  interactorA pp interactorB interactorC interactor D

Node attribute files may be used to add DAS 'detail' elements to interactors:
  description
  interactorA = An example interactor
  interactorB = Another example of an interactor
  ...

Edge attribute files may be used to add DAS 'detail' elements to interactions:
  score
  interactorA pp interactorB = 2.43
  interactorX pp interactorY = 5.1
  ...

=head1 CONFIGURATION AND ENVIRONMENT

Configured as part of each source's ProServer 2 INI file:

  [mysif]
  ... source configuration ...
  transport  = sif
  filename   = /data/interactions.sif
  attributes = /data/node-attribute.noa ; /data/edge-attributes.eda

=head1 SUBROUTINES/METHODS

=head2 query : Retrieves interactions for one or two interactors

  Retrieves interactions involving interactorA:
  $hInteractions = $oTransport->query('interactorA');
  
  Retrieves an interaction involving both interactorA and interactorB:
  $hInteractions = $oTransport->query('interactorA', 'interactorB');
  
  The returned hash is of the structure expected by ProServer.

=head2 DESTROY : object destructor - disconnect filehandles

  Generally not directly invoked, but if you really want to:

  $transport->DESTROY();

=head1 DIAGNOSTICS

Run ProServer with the -debug flag.

=head1 SEE ALSO

=over

=item L<Cytoscape - SIF|http://www.cytoscape.org/cgi-bin/moin.cgi/Cytoscape_User_Manual/Network_Formats>

=item L<Cytoscape - Attributes|http://www.cytoscape.org/cgi-bin/moin.cgi/Cytoscape_User_Manual/Attributes>

=back

=head1 DEPENDENCIES

=over

=item L<Carp|Carp>

=item L<Bio::Das::ProServer::SourceAdaptor::Transport::file|Bio::Das::ProServer::SourceAdaptor::Transport::file>

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
