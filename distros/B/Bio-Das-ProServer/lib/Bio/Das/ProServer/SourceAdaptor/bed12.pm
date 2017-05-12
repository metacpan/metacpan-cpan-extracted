#########
# Author:        Andy Jenkinson
# Maintainer:    $Author: zerojinx $
# Created:       2008-09-19
# Last Modified: $Date: 2010-11-02 11:57:52 +0000 (Tue, 02 Nov 2010) $
# $Id: bed12.pm 688 2010-11-02 11:57:52Z zerojinx $
# $HeadURL: https://proserver.svn.sourceforge.net/svnroot/proserver/trunk/lib/Bio/Das/ProServer/SourceAdaptor/bed12.pm $
#
## no critic (ValuesAndExpressions::ProhibitImplicitNewlines)
#
package Bio::Das::ProServer::SourceAdaptor::bed12;

use strict;
use warnings;
use Carp;
use base qw(Bio::Das::ProServer::SourceAdaptor);

our $VERSION = do { my ($v) = (q$Revision: 688 $ =~ /\d+/mxsg); $v; };

sub init {
  my $self = shift;
  $self->config()->{'transport'} ||= 'bed12';
  return;
}

sub capabilities {
  my $caps = {
    'features'      => '1.0',
    'feature-by-id' => '1.0',
    'group-by-id'   => '1.0'
  };
  return $caps;
}

sub build_features {
  my ( $self, $args ) = @_;

  my $segmentid = $args->{'segment'};
  my $featureid = $args->{'feature_id'};
  my $groupid   = $args->{'group_id'};
  my $start     = $args->{'start'};
  my $end       = $args->{'end'};

  # Querying by feature ID and not segment ID
  if ( my $name = $featureid ) {
    $self->{'debug'} && carp $self->dsn.": querying by feature ID $featureid";
    # The 'name' field can either be the feature ID or the group ID, depending
    # on whether the BED line contains blocks. If the latter, the feature ID
    # is actually groupid:1 groupid:2 etc
    $name =~ s/:\d+$//mxs;
    my $query = sprintf
      'SELECT chrom, chromStart, chromEnd,
              name, score, strand,
              blockCount, blockSizes, blockStarts
       FROM   %s
       WHERE  name = ?', $self->transport()->tablename();
    my $rows = $self->transport()->query( $query, $name );
    return grep {
      $_->{feature_id} eq $featureid
    } @{ $self->_build_features_from_rows( $rows ) };
  }

  # Querying by group ID and not segment ID
  elsif ( $groupid ) {
    # Assume that the 'name' field refers to the group ID
    $self->{'debug'} && carp $self->dsn.": querying by group ID $groupid";
    my $query = sprintf
      'SELECT chrom, chromStart, chromEnd,
              name, score, strand,
              blockCount, blockSizes, blockStarts
       FROM   %s
       WHERE  name = ?', $self->transport()->tablename();
    my $rows = $self->transport()->query( $query, $groupid );
    # Still need to check that the name field doesn't actually refer to the feature ID
    return grep {
      $_->{group_id} eq $groupid
    } @{ $self->_build_features_from_rows( $rows ) };
  }

  # Querying by segment ID
  elsif ( $segmentid ) {
    $self->{'debug'} && carp $self->dsn.": querying by segment $segmentid:$start,$end";
    my $query = sprintf
      'SELECT chrom, chromStart, chromEnd,
              name, score, strand,
              blockCount, blockSizes, blockStarts
       FROM   %s
       WHERE  chrom = ?', $self->transport()->tablename();
    my @args = ("chr$segmentid");
    if ( defined $start && defined $end ) {
      $query .= ' AND chromEnd >= ? AND chromStart <= ?';
      push @args, $start-1, $end; # BED start position is zero-based
    }
    my $rows = $self->transport()->query( $query, @args );
    return @{ $self->_build_features_from_rows( $rows ) };
  }

  # Not specified... 
  carp $self->dsn.': no segment ID, group ID or feature ID given';
  return ();
}

sub _build_features_from_rows {
  my $self     = shift;
  my $rows     = shift;
  my @features = ();

  for my $row ( @{ $rows } ) {

    defined $row->{'chromStart'} || next;
    my $segment = $row->{'chrom'};
    $segment    =~ s/^chr//mxs;

    # One feature line can represent several features
    if ( my $block_count = $row->{'blockCount'} ) {
      my @block_sizes  = split m/,/mxs, $row->{'blockSizes'} , $block_count;
      my @block_starts = split m/,/mxs, $row->{'blockStarts'}, $block_count;

      my $i = 0;
      while ($i<$block_count) {
        push @features, {
          'segment'    => $segment,
          'start'      => $block_starts[$i] + $row->{'chromStart'} + 1,
          'end'        => $block_starts[$i] + $row->{'chromStart'} + $block_sizes[$i],
          'ori'        => $row->{'strand'},
          'score'      => $row->{'score'},
          'group_id'   => $row->{'name'},
          'feature_id' => $row->{'name'} . q[:] . ++$i,
          'type'       => $row->{'name'},
          'method'     => 'BED conversion',
        };
      }

    } else {
      push @features, {
        'segment'    => $segment,
        'start'      => $row->{'chromStart'} + 1,
        'end'        => $row->{'chromEnd'},
        'ori'        => $row->{'strand'},
        'score'      => $row->{'score'},
        'group_id'   => $row->{'name'},
        'feature_id' => $row->{'name'} . ':1',
        'type'       => $row->{'name'},
        'method'     => 'BED conversion',
      };
    }
  }

  $self->{'debug'} && printf "%s: returning %d features\n", $self->dsn, scalar @features;
  return \@features;
}

1;
__END__

=head1 NAME

Bio::Das::ProServer::SourceAdaptor::bed12

=head1 VERSION

$Revision: 688 $

=head1 SYNOPSIS

  Features by segment:
  <host>/das/<source>/features?segment=X:1,100
  
  Features by group ID:
  <host>/das/<source>/features?group_id=TRAN1
  
  Features by feature ID:
  <host>/das/<source>/features?feature_id=TRAN1:4

=head1 DESCRIPTION

Serves up features DAS responses from BED files.
See L<http://genome.ucsc.edu/goldenPath/help/customTrack.html#BED|http://genome.ucsc.edu/goldenPath/help/customTrack.html#BED>
http://genome.ucsc.edu/goldenPath/help/customTrack.html#BED
for details of the file format.

The BED and DAS formats contain an intersection of information. That is, not all
DAS fields are supported in BED, and vice versa. In order to be adapted to the
DAS protocol, some basic assumptions need to be made and some configurability is
lost. See the BUGS AND LIMITATIONS section for more details.

=head1 CONFIGURATION AND ENVIRONMENT

  [mybed]
  state       = on
  adaptor     = bed12
  path        = /data/
  filename    = example.bed
  ; coordinates -> test segment
  coordinates = NCBI_36,Chromosome,Homo sapiens -> X:1,100

=head1 DIAGNOSTICS

Run ProServer with the -debug flag.

=head1 SUBROUTINES/METHODS

=head2 build_features - Builds the DAS response

See documentation in superclass.

=head2 capabilities - Provides details of the adaptor's capabilities

This adaptor supports the 'features' command, including the 'feature-by-id' and
'group-by-id' variants.

=head2 init - Initialises the SourceAdaptor

Adds the 'bed12' transport to the source's configuration (if not already set).

=head1 SEE ALSO

=over

=item L<Bio::Das::ProServer::SourceAdaptor::Transport::bed12|Bio::Das::ProServer::SourceAdaptor::Transport::bed12>

=item L<http://genome.ucsc.edu/goldenPath/help/customTrack.html#BED|http://genome.ucsc.edu/goldenPath/help/customTrack.html#BED> BED format

=back

=head1 DEPENDENCIES

=over

=item L<Bio::Das::ProServer::SourceAdaptor|Bio::Das::ProServer::SourceAdaptor> 

=item L<Bio::Das::ProServer::SourceAdaptor::Transport::bed12|Bio::Das::ProServer::SourceAdaptor::Transport::bed12>

=item L<Carp|Carp>

=back

=head1 BUGS AND LIMITATIONS

See the BUGS AND LIMITATIONS section of
Bio::ProServer::SourceAdaptor::Transport::bed12 for details.

=head1 INCOMPATIBILITIES

None reported.

=head1 AUTHOR

Andy Jenkinson <andy.jenkinson@ebi.ac.uk>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 EMBL-EBI

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
