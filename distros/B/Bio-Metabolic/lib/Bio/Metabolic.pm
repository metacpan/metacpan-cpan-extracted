package Bio::Metabolic;

require 5.005_62;
use strict;
use warnings;

require Exporter;

use Bio::Metabolic::Substrate;
use Bio::Metabolic::Substrate::Cluster;
use Bio::Metabolic::Reaction;
use Bio::Metabolic::Network;

#use Bio::Metabolic::Network::Graph;
#use Bio::Metabolic::NetworkDB;
#use Bio::Metabolic::ConservationRule;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Bio::Metabolic ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
    'all' => [
        qw(

          )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);
our $VERSION = '0.07';

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Bio::Metabolic - Perl extension for representing and simulating metabolic networks

=head1 SYNOPSIS

  use Bio::Metabolic;

  This is equivalent to

  use Bio::Metabolic::Substrate;
  use Bio::Metabolic::Substrate::Cluster;
  use Bio::Metabolic::Reaction;
  use Bio::Metabolic::Network;


=head1 AUTHOR

Oliver Ebenhöh, oliver.ebenhoeh@rz.hu-berlin.de

=head1 SEE ALSO

Bio::Metabolic::Substrate 
Bio::Metabolic::Substrate::Cluster 
Bio::Metabolic::Reaction 
Bio::Metabolic::Network
perl(1).

=cut
