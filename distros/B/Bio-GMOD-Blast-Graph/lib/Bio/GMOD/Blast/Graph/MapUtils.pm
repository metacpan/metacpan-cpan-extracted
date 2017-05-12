package Bio::GMOD::Blast::Graph::MapUtils;
BEGIN {
  $Bio::GMOD::Blast::Graph::MapUtils::AUTHORITY = 'cpan:RBUELS';
}
BEGIN {
  $Bio::GMOD::Blast::Graph::MapUtils::VERSION = '0.06';
}
#####################################################################
#
# Cared for by Shuai Weng <shuai@genome.stanford.edu>
#
# Originally created by John Slenk <jces@genome.stanford.edu>
#
# You may distribute this module under the same terms as perl itself
#-----------------------------------------------------------------

use Bio::GMOD::Blast::Graph::BaseObj;
use Bio::GMOD::Blast::Graph::MyUtils;
use Bio::GMOD::Blast::Graph::MyDebug qw( assert dmsg );
use Bio::GMOD::Blast::Graph::MapDefs
    qw( $imgWidth $imgHeight $fontWidth $fontHeight $imgTopBorder
       $imgBottomBorder $imgLeftBorder $imgRightBorder $namesHorizBorder
       $imgHorizBorder $imgVertBorder $arrowHeight $halfArrowHeight
       $arrowWidth $halfArrowWidth $hspPosInit $hspArrowPad $hspHeight
       $formFieldWidth $tickHeight $bottomDataOffset $topDataOffset
       $kNumberOfPartitions $bucketZeroMax $bucketOneMax $bucketTwoMax
       $bucketThreeMax $bucketFourMax );

@ISA = qw( Bio::GMOD::Blast::Graph::BaseObj );

my $kNamesP =
  Bio::GMOD::Blast::Graph::MyUtils::makeVariableName( "names", "predicate" );
my $kNamesHorizBorder =
  Bio::GMOD::Blast::Graph::MyUtils::makeVariableName( "names", "horiz", "border" );
my $kImgWidth =
  Bio::GMOD::Blast::Graph::MyUtils::makeVariableName( "img", "width" );
my $kQueryLeft =
  Bio::GMOD::Blast::Graph::MyUtils::makeVariableName( "query", "left" );
my $kQuerySpace =
  Bio::GMOD::Blast::Graph::MyUtils::makeVariableName( "query", "space" );

###################################################################
sub init {
###################################################################
    my( $self, $pP ) = @_;

    $self->putNamesP( $pP );
    $self->putNamesHorizBorder( $namesHorizBorder );
    $self->recalc();
}

###################################################################
sub recalc {
###################################################################
    my( $self ) = shift;
    my( $pP ) = $self->getNamesP();
    my( $namesHorizBorder ) = $self->getNamesHorizBorder();
    my( $tmp );

    $tmp = $imgWidth;
    if( $pP ) { $tmp += $namesHorizBorder; }
    $self->{ $kImgWidth } = $tmp;

    $tmp = $self->getImgWidth() - $imgHorizBorder;
    if( $pP ) { $tmp -= $namesHorizBorder; }
    $self->{ $kQuerySpace } = $tmp;

    $tmp = $imgLeftBorder;
    if( $pP ) { $tmp += $namesHorizBorder; }
    $self->{ $kQueryLeft } = $tmp;
}

###################################################################
sub putNamesP {
###################################################################
    my( $self, $pP ) = @_;
    $self->{ $kNamesP } = $pP;
}

###################################################################
sub getNamesP {
###################################################################
    my( $self ) = shift;
    return( $self->{ $kNamesP } );
}

###################################################################
sub putNamesHorizBorder {
###################################################################
    my( $self ) = shift;
    my( $phb ) = shift;
    $self->{ $kNamesHorizBorder } = $phb;
    $self->recalc();
}

###################################################################
sub getNamesHorizBorder {
###################################################################
    my( $self ) = shift;
    return( $self->{ $kNamesHorizBorder } );
}

###################################################################
sub getImgWidth {
###################################################################
    my( $self ) = shift;
    return( $self->{ $kImgWidth } );
}

###################################################################
sub getNoteLeft {
###################################################################
    my( $self ) = shift;
    return( $imgLeftBorder );
}

###################################################################
sub getQueryLeft {
###################################################################
    my( $self ) = shift;
    return( $self->{ $kQueryLeft } );
}

###################################################################
sub getQueryWidth {
###################################################################
    my( $self ) = shift;
    return( $self->{ $kQuerySpace } );
}

###################################################################
sub getStringDimensions {
###################################################################
    my( $self, $str ) = @_;
    my( $w, $h );

    $w = length( $str ) * $fontWidth;
    $h = $fontHeight;

    return( $w, $h );
}
###################################################################
1;
###################################################################

__END__
=pod

=encoding utf-8

=head1 NAME

Bio::GMOD::Blast::Graph::MapUtils

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

