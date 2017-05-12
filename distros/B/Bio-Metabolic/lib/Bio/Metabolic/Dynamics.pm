
=head1 NAME

Bio::Metabolic::Dynamics - Dynamical features for biochemical reaction networks

=head1 SYNOPSIS

  use Bio::Metabolic::Dynamics;


=head1 DESCRIPTION

This module contains all methods and features that depend on Math::Symbolic.
This way the user can decide whether he wishes to have support of Symbolic::Math 
and wants to make use of the reaction rates.

=head1 AUTHOR

Oliver Ebenhoeh, oliver.ebenhoeh@rz.hu-berlin.de

=head1 SEE ALSO

Bio::Metabolic 
Bio::Metabolic::Substrate 
Bio::Metabolic::Substrate::Cluster 
Bio::Metabolic::Reaction
Bio::Metabolic::Network

=cut

package Bio::Metabolic::Dynamics;

require 5.005_62;
use strict;
use warnings;

require Exporter;

use Bio::Metabolic;

use Math::Symbolic;

use Bio::Metabolic::Dynamics::Substrate;
use Bio::Metabolic::Dynamics::Reaction;
use Bio::Metabolic::Dynamics::Network;

our $VERSION = '0.06';
