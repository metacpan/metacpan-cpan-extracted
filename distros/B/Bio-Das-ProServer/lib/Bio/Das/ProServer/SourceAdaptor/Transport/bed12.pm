########
# Author:        Andy Jenkinson
# Maintainer:    $Author: zerojinx $
# Created:       2008-09-19
# Last Modified: $Date: 2010-11-02 11:57:52 +0000 (Tue, 02 Nov 2010) $
# $Id: bed12.pm 688 2010-11-02 11:57:52Z zerojinx $
# $HeadURL: https://proserver.svn.sourceforge.net/svnroot/proserver/trunk/lib/Bio/Das/ProServer/SourceAdaptor/Transport/bed12.pm $
#
package Bio::Das::ProServer::SourceAdaptor::Transport::bed12;

use strict;
use warnings;
use Carp;
use base qw(Bio::Das::ProServer::SourceAdaptor::Transport::csv);

our $VERSION = do { my ($v) = (q$Revision: 688 $ =~ /\d+/mxsg); $v; };

sub init {
  my $self = shift;

  $self->config()->{col_names} ||= join q[:], qw(chrom chromStart chromEnd
                                                 name score strand
                                                 thickStart thickEnd itemRgb
                                                 blockCount blockSizes blockStarts);

  # Now work out how many header lines are in the file (we need to skip these)
  my ($fh, $headerlines);
  open $fh, q[<], $self->filename or croak 'Unable to open '.$self->filename;
  while ( <$fh> =~ m/^(\#|browser|track)/mxs ) {
    $headerlines++;
  }
  close $fh or carp 'Unable to close '.$self->filename;

  $self->{'debug'} && carp "Found $headerlines header lines to skip";
  $self->config()->{'skip_rows'} ||= $headerlines;

  return;
}

1;
__END__

=head1 NAME

Bio::Das::ProServer::SourceAdaptor::Transport::bed12 - DBI-like access to a BED file

=head1 VERSION

$Revision: 688 $

=head1 SYNOPSIS

  my $rows = $oTransport->query('select * from example.bed where chrom = chr1');

=head1 DESCRIPTION

Transport helper class for BED file access, implemented as an extension to
Bio::Das::ProServer::SourceAdaptor::Transport::csv.

This transport is used by the Bio::Das::ProServer::SourceAdaptor::bed12 adaptor.

=head1 SUBROUTINES/METHODS

=head2 init - Initialises the CSV file with BED-specific functions

  1. Sets the appropriate BED column names.
  2. Sets the number of header lines to be skipped.

  $bedtransport->init();

=head1 DIAGNOSTICS

Run ProServer with the -debug flag.

=head1 CONFIGURATION AND ENVIRONMENT

  [mysource]
  state      = on
  transport  = bed12
  path       = /data/
  filename   = example.bed

=head1 DEPENDENCIES

=over

=item L<Bio::Das::ProServer::SourceAdaptor::Transport::csv|Bio::Das::ProServer::SourceAdaptor::Transport::csv>

=item L<DBI|DBI>

=item L<Carp|Carp>

=back

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

BED is mapped to DAS in the following manner:

1. The BED format allows for "blocks" within each line. Where these are present
   it is assumed that the line represents a group of features, with each block
   representing a single feature within the group. Lines without blocks are
   treated as if they contain a single full-length block.

2. DAS fields are mapped from BED fields as follows:
   
   segment    = <chrom> (minus the "chr" prefix)
   start      = <chromStart> + 1
   end        = <chromEnd>
   ori        = <strand>
   score      = <score>
   group_id   = <name>
   feature_id = <name>:blocknum
   type       = <name>
   method     = string "BED conversion"

3. Browser and track configurations are not parsed because DAS has different
   ways of defining many of these attributes - namely coordinate systems and
   stylesheets. If you wish to define a stylesheet, set the 'stylesheetfile'
   INI property to the path of a suitable DAS stylesheet XML document.

=head1 SEE ALSO

=over

=item L<Bio::Das::ProServer::SourceAdaptor::bed12|Bio::Das::ProServer::SourceAdaptor::bed12>

=item L<http://genome.ucsc.edu/goldenPath/help/customTrack.html#BED|http://genome.ucsc.edu/goldenPath/help/customTrack.html#BED> BED format

=back

=head1 AUTHOR

Andy Jenkinson <andy.jenkinson@ebi.ac.uk>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 EMBL-EBI

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
