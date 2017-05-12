package Bio::GMOD::Blast::Graph::MapDefs;
BEGIN {
  $Bio::GMOD::Blast::Graph::MapDefs::AUTHORITY = 'cpan:RBUELS';
}
BEGIN {
  $Bio::GMOD::Blast::Graph::MapDefs::VERSION = '0.06';
}
#####################################################################
#
# Cared for by Shuai Weng <shuai@genome.stanford.edu>
#
# Originally created by John Slenk <jces@genome.stanford.edu>
#
# You may distribute this module under the same terms as perl itself
#-----------------------------------------------------------------

require Exporter;
@ISA = qw( Exporter );
@EXPORT_OK =
    qw( $imgWidth $imgHeight $fontWidth $fontHeight $imgTopBorder
       $imgBottomBorder $imgLeftBorder $imgRightBorder $namesHorizBorder
       $imgHorizBorder $imgVertBorder $arrowHeight $halfArrowHeight
       $arrowWidth $halfArrowWidth $hspPosInit $hspArrowPad $hspHeight
       $formFieldWidth $tickHeight $bottomDataOffset $topDataOffset
       $kNumberOfPartitions $bucketBest $bucketZeroMax $bucketOneMax
       $bucketTwoMax $bucketThreeMax $bucketFourMax );

$imgWidth = 600;
$imgHeight = 300;

# [[ if GD changes it's small font these are screwed. ]]
$fontWidth = 6;
$fontHeight = 10;

$imgTopBorder = 25; # will be blank.
$imgBottomBorder = $fontHeight*2; # room for key.
$imgLeftBorder = 15; # will be blank.
$imgRightBorder = 40; # will contain "counts shown / counts in box".
$namesHorizBorder = 150; # for extra annotations.

# aliases.
$imgHorizBorder = $imgLeftBorder + $imgRightBorder;
$imgVertBorder = $imgTopBorder + $imgBottomBorder;

# to position the query within the top border.
$topDataOffset = 18;

# make room between hits and key at bottom.
$bottomDataOffset = 2;

$tickHeight = 2;

# graphical arrow height is actually +1;
# we take a central point and draw the
# arrow +/- $arrowHeight/2 around it.
$arrowHeight = 6;

$halfArrowHeight = int($arrowHeight/2);
# the arrowWidth is for the arrow's end bevels.
$arrowWidth = $halfArrowHeight;
$halfArrowWidth = int($arrowWidth/2);

# where we draw the first hit.
$hspPosInit = $imgTopBorder;

# space between hsp rows.
$hspArrowPad = 2;

# how many pixels per hsp row.
# +1 because of notes above re: arrow height.
$hspHeight = ($arrowHeight+1) + ($hspArrowPad*2);

# fixed ranges for the buckets.
# bucket zero has the best hits.
# bucket five has the worst hits.
$kNumberOfPartitions = 5;

$bucketBest = 0;
$bucketZeroMax = 1.0e-200;
$bucketOneMax = 1e-100;
$bucketTwoMax = 1e-50;
$bucketThreeMax = 1e-10;
$bucketFourMax = 1.0;

__END__
=pod

=encoding utf-8

=head1 NAME

Bio::GMOD::Blast::Graph::MapDefs

=head1 AUTHORS

=over 4

=item *

Shuai Weng <shuai@genome.stanford.edu>

=item *

John Slenk <jces@genome.stanford.edu>

=item *

Robert Buels <rmb32@cornell.edu>

=item *

Jonathan "Duke" Leto <jonathan@leto.net>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by The Board of Trustees of Leland Stanford Junior University.

This is free software, licensed under:

  The Artistic License 1.0

=cut

