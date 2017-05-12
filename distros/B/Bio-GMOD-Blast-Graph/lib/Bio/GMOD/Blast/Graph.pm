package Bio::GMOD::Blast::Graph;
BEGIN {
  $Bio::GMOD::Blast::Graph::AUTHORITY = 'cpan:RBUELS';
}
BEGIN {
  $Bio::GMOD::Blast::Graph::VERSION = '0.06';
}
# ABSTRACT: display a graphical summary of a BLAST report


use strict;

use base 'Bio::Root::IO';
use Bio::SearchIO;
use GD;

use File::Spec;

use Bio::GMOD::Blast::Graph::IntSpan;
use Bio::GMOD::Blast::Graph::MyDebug qw( dmsg dmsgs assert );
use Bio::GMOD::Blast::Graph::MyMath qw( round max );
use Bio::GMOD::Blast::Graph::MyUtils;
use Bio::GMOD::Blast::Graph::HitWrapper;
use Bio::GMOD::Blast::Graph::WrapPartitionsFixed;
use Bio::GMOD::Blast::Graph::WrapList;
use Bio::GMOD::Blast::Graph::MapSpace;
use Bio::GMOD::Blast::Graph::MapUtils;
use Bio::GMOD::Blast::Graph::MapDefs
    qw( $imgWidth $imgHeight $fontWidth $fontHeight $imgTopBorder
       $imgBottomBorder $imgLeftBorder $imgRightBorder $namesHorizBorder
       $imgHorizBorder $imgVertBorder $arrowHeight $halfArrowHeight
       $arrowWidth $halfArrowWidth $hspPosInit $hspArrowPad $hspHeight
       $formFieldWidth $tickHeight $bottomDataOffset $topDataOffset
       $kNumberOfPartitions $bucketBest $bucketZeroMax $bucketOneMax
       $bucketTwoMax $bucketThreeMax $bucketFourMax );

our $ID = __PACKAGE__;

################################################################
sub new {
################################################################


##################################################################
    my ($class, @args) = @_;

    my $self = $class->SUPER::new(@args);

    $self->_init(@args);

    $self->_parseFile;

    return $self;

}

##################################################################
sub showGraph {
##################################################################


##################################################################
    my ($self) = @_;

    $self->_createAndShowGraph;

}

##################################################################
sub getImageFile {
##################################################################


##################################################################
    my ($self) = @_;

    return $self->{'_dstDir'}.$self->{'_imgName'};

}

##################################################################
sub hitNameArrayRef {
##################################################################


##################################################################
    my ($self) = @_;

    return $self->{'_hitNameArrayRef'};

}

##################################################################
sub _init {
##################################################################
# This private method checks that all the required arguments
# have been provided and stores them within the object, and
# initializes variables for optional arguments if they are not
# provided.

    my ($self, @args) = @_;

    my ($outputFile, $format, $dstDir, $dstURL, $imgName,
    $showNamesP, $db) =
        $self->_rearrange([qw(OUTPUTFILE
                  FORMAT
                  DSTDIR
                  DSTURL
                  IMGNAME
                  SHOWNAMESP
                  DB)], @args);

    if (!$outputFile) {

    $self->throw("The search output file needs to be passed to '$ID' object.");

    }

    if (!$dstDir) {

    $self->throw("A tmp directory for storing the image file needs to be passed to '$ID' object.");

    }

    if (!$dstURL) {

    $self->throw("The root URL for the image file needs to be passed to '$ID' object.");

    }

    $self->{'_outputFile'} = $outputFile;

    $self->{'_format'} = $format || 'blast';

    # if ($format !~ /^(blast|fasta|HMMER)/i) {

    #    $self->throw("The format must be [blast|fasta|HMMER]");

    # }

    $self->{'_dstDir'} = $dstDir;

    $self->{'_dstURL'} = $dstURL;

    $self->{'_imgName'} = $imgName || "$$.50.png";

    $self->{'_showNamesP'} = $showNamesP;

    $self->{'_mapName'} = 'imap';

    $self->{'_formFieldWidth'} = 100;

    $self->{'_debugCount'} = 0;

    $self->{'_tickList'} = [];

    $self->{'_mapUtils'} = new Bio::GMOD::Blast::Graph::MapUtils($showNamesP);


}

###################################################################
sub _parseFile {
###################################################################
# This private method parses the search output file by simply
# calling the Bioperl SearchIO module and stores the hits in
# the hit list.

    my ($self) = @_;

    my $searchio = Bio::SearchIO->new(-file=>$self->{'_outputFile'},
                      -format=>$self->{'_format'});

    my $wrapList = new Bio::GMOD::Blast::Graph::WrapList();

    my @hitName;

    while (my $result = $searchio->next_result) {

    $self->{'_srcLength'} = $result->query_length;

    if (!scalar$result->hits()) {
        $self->_print( "<p>Sorry, no hits found for your query sequence.</p>" );
        return;
    }

    while (my $hit = $result->next_hit()) {


        push(@hitName, $hit->name);

        # if ($hit->name =~ /^ORF[NP]:(.+)$/) {

        #    push(@orf, $1);

        # }

        my $wrap = new Bio::GMOD::Blast::Graph::HitWrapper( $hit );

        # dmsg( "adding", $wrap->toString(), $wrap->getPExponent() );

        $wrapList->addElement( $wrap );

    }

    # we want to scale everything to fit in the Mapic.
    # convert from length to pixels. length * (pixels/length) = pixels.
    $self->{'_horizRatio'} =
        $self->{'_mapUtils'}->getQueryWidth()/$self->{'_srcLength'};

    }

    $self->{'_hitNameArrayRef'} = \@hitName;

    $wrapList->sortByPValue();

    undef $searchio;

    # remember how many hits we had
    # so that we can report how many
    # we don't show.
    $self->{'_hitCount'} = $wrapList->getCount();

    $self->{'_parts'} =
    new Bio::GMOD::Blast::Graph::WrapPartitionsFixed( $wrapList );

    $self->{'_parts'}->reduce();

    $self->{'_hitCountBefore'} = $self->{'_hitCount'};

    $self->{'_hitCountAfter'} =
    $self->{'_parts'}->getPartitionElementsCountAfter();

    if( $self->{'_hitCountAfter'} == $self->{'_hitCountBefore'} ) {

    $self->{'_allShowingP'} = 1;

    }
    else {

    $self->{'_allShowingP'} = 0;

    }

}

#######################################################################
sub _createAndShowGraph {
#######################################################################
# This is a wrapper method which simply calls each private method to
# do the job.

    my ($self) = @_;

    $self->_countHTML($self->{'_hitCountAfter'},
              $self->{'_hitCountBefore'});

    $self->_initGD;

    $self->_writeIMapStart;

    $self->_drawQuery;

    $self->_drawGraph;

    $self->_drawKey;

    $self->_drawStamp;

    $self->_writeImage;

    $self->_writeIMapEnd;

}

###################################################################
sub _initGD {
###################################################################
# This private method initializes the GD object and colors, and
# draws a frame around the map.

    my ($self) = @_;

    my $annotationWidth =
    $self->{'_parts'}->getMaxAnnotationWidthForFont($fontWidth);

    $self->{'_mapUtils'}->putNamesHorizBorder($annotationWidth+10);

    $self->{'_realWidth'} = $self->{'_mapUtils'}->getImgWidth();

    $self->{'_realHeight'} = $self->{'_parts'}->getHeight() + $imgVertBorder;

    my $img = new GD::Image($self->{'_realWidth'},
                $self->{'_realHeight'});

    $img->interlaced('true');

    $self->{'_white'} = $img->colorAllocate( 255, 255, 255 );
    $self->{'_black'} = $img->colorAllocate( 0, 0, 0 );
    $self->{'_grayLight'} = $img->colorAllocate( 204, 204, 204 );
    $self->{'_gray'} = $img->colorAllocate( 153, 153, 153 );
    $self->{'_grayDark'} = $img->colorAllocate( 102, 102, 102 );
    $self->{'_debugColor'} = $img->colorAllocate( 0, 204, 0 );
    $self->{'_bgColor2'} = $self->{'_white'};
    $self->{'_bgColor3'} = $self->{'_grayLight'};

    # range colors. things are hard-coded throughout to use these.
    # brighter blues because they are so dark to begin with.

    $self->{'_blue'} = $img->colorAllocate( 51, 51, 204 );
    $self->{'_blueDark'} = $img->colorAllocate( 51, 51, 153 );

    $self->{'_cyan'} = $img->colorAllocate( 0, 204, 204 );
    $self->{'_cyanDark'} = $img->colorAllocate( 0, 153, 153 );

    $self->{'_green'} = $img->colorAllocate( 0, 204, 0 );
    $self->{'_greenDark'} = $img->colorAllocate( 0, 153, 0 );

    $self->{'_magenta'} = $img->colorAllocate( 204, 0, 204 );
    $self->{'_magentaDark'} = $img->colorAllocate( 153, 0, 153 );

    $self->{'_red'} = $img->colorAllocate( 204, 0, 0 );
    $self->{'_redDark'} = $img->colorAllocate( 153, 0, 0 );

    # will have an alternating background
    # to help hilight hsps in the same hit.
    $self->{'_curBgColor'} = $self->{'_bgColor2'};

    # but everything else should have a white background
    # to distinguish where the hits start & end.

    # $img->filledRectangle(0, 0,
#              $self->{'_realWidth'},
#              $self->{'_imgHeight'},
#              $self->{'_white'});

    $img->rectangle(0, 0,
            $self->{'_realWidth'},
            $self->{'_realHeight'},
            $self->{'_blue'});


    $self->{'_img'} = $img;

}

#----------------------------------------
# spit image out to a file.
######################################################################
sub _writeImage {
######################################################################
# This private method writes the image into a tmp directory specified by
# the client interface.

    my ($self) = @_;

    my $img_path = File::Spec->catfile( $self->{'_dstDir'}, $self->{'_imgName'} );
    open my $img, '>', $img_path
        or die "$! writing $img_path";

    if ($self->{'_img'}->can('png')) {
        print $img $self->{'_img'}->png;
    }
    else {
        print $img $self->{'_img'}->gif;
    }

}

#----------------------------------------
# draw partitions in order.
# must come after drawQuery if
# you want the ticks everywhere.
#####################################################################
sub _drawGraph {
#####################################################################
# This private method loops through each hit from the list and calls
# different private methods to draw the different parts.

    my ($self) = @_;

    # dmsg( "drawGraph()..." );

    my( $hspBefore, $hspAfter, $hspMid );
    my( $countsRef );
    my( $countsStr );

    my( $totalCount, $shownCount );

    my $hspPos = $hspPosInit;

    for( my $pdex = 0; $pdex < $kNumberOfPartitions; $pdex++ ) {

    my $part = $self->{'_parts'}->getPartitionAt( $pdex );

    #dmsg( "drawGraph(): partition \#$pdex count =", $part->getCount() );

    # draw the hsps in the hits.
    # keep track of how much vertical space is used.

    $hspBefore = $hspPos;

    my $enum = $part->getEnumerator();

    my $wrap;

    while( defined( $wrap = $enum->getNextElement() ) ) {

        $hspPos = $self->_drawWrap( $wrap, $hspPos );

    }

    $hspAfter = $hspPos;

    # annotate with count of
    # shown/total per bucket.

    $countsRef =
        $self->{'_parts'}->getPartitionElementsCountsRefAt($pdex);

    #dmsgs( "drawGraph(): partition counts = ", @{$countsRef} );

    $totalCount = $$countsRef[ 0 ];

    $shownCount = $$countsRef[ 1 ];

    if( $totalCount != 0 ) {

        if( $shownCount == $totalCount ) {

        $countsStr = 'All';
        }
        else {

        $countsStr = $shownCount . '/' . $totalCount;

        }

        if( $self->{'_allShowingP'} == 0 ) {

        $hspMid = $self->_getHspMid( $hspBefore, $hspAfter );

        $self->_drawString( $countsStr, GD::gdSmallFont(),
                  $self->{'_realWidth'}-$imgRightBorder+3,
                  $hspMid,
                  $self->_pickColorN($pdex));

        }
    }
    }

    #dmsg( "...drawGraph()" );
}

##############################################################################
sub _getHspMid {
##############################################################################
# This private method is used to get the position for the given hsp.

    my($self, $hspBefore, $hspAfter) = @_;

    return ($hspBefore + ($hspAfter - $hspBefore)/2 - $fontHeight/2 - 2);


}

#############################################################################
sub _drawWrap {
#############################################################################
# This private method is used to the wrap background.

    my($self, $wrap, $hspPos ) = @_;

    my $fwdRef = $wrap->getForwardBucketSet();
    my $revRef = $wrap->getReverseBucketSet();

    my $fwdCount = $fwdRef->getCount(); # number of lines.
    my $revCount = $revRef->getCount();

    # alternating background color. serious fudge factors
    # because i'm way too confused by math. so if you change
    # values in MapDefs this will be all wrong. sorry.

    my $bgY1 = $hspPos;
    my $bgY2 = $hspPos + $hspHeight * $wrap->getHSPLineCount() - 1;

    $self->{'_curBgColor'} =
    ($self->{'_curBgColor'} == $self->{'_bgColor2'}) ?
        $self->{'_bgColor3'} : $self->{'_bgColor2'};

    $self->{'_img'}->filledRectangle($self->{'_mapUtils'}->getNoteLeft(),
                     $bgY1,
                     $self->{'_realWidth'}-$imgRightBorder,
                     $bgY2,
                     $self->{'_curBgColor'});

    $self->_annotateIMap($wrap,
             $self->{'_mapUtils'}->getNoteLeft(),
             $bgY1,
             $self->{'_realWidth'}-$imgRightBorder,
             $bgY2 );

    foreach my $tickX (@{$self->{'_tickList'}}) {

    $self->{'_img'}->line($self->{'_mapUtils'}->getQueryLeft()+$tickX,
                  $bgY1,
                  $self->{'_mapUtils'}->getQueryLeft()+$tickX,
                  $bgY2,
                  $self->{'_white'});

    }

    if($self->{'_showNamesP'}) {

    $self->{'_img'}->line($self->{'_mapUtils'}->getQueryLeft(),
                  $bgY1,
                  $self->{'_mapUtils'}->getQueryLeft(),
                  $bgY2,
                  $self->{'_white'});
    }

    my $colorN = $self->_getColorNFromP($wrap, 0);

    my $hspBefore = $hspPos;

    if( $fwdCount > 0 ) {

    $hspPos = $self->_drawDirection($fwdRef->getBucketList(),
                    $hspPos,
                    'plus',
                    $colorN );

    }

    if( $revCount > 0 ) {

    $hspPos = $self->_drawDirection($revRef->getBucketList(),
                    $hspPos,
                    'minus',
                    $colorN );
    }

    my $hspAfter = $hspPos;

    if( $self->{'_showNamesP'}) {

    my $mdefs = $self->{'_mapUtils'};

    my $buf = $mdefs->getNamesHorizBorder();
    my $note = $wrap->getGraphAnnotation();
    my ($w, $h) = $mdefs->getStringDimensions($note);

    # [[ assuming that the border is at least as wide as the string! ]]

    $buf -= $w;
    $buf /= 2;

    my $x = $mdefs->getNoteLeft() + $buf;

    my $hspMid = $self->_getHspMid($hspBefore, $hspAfter);

    $self->{'_img'}->string(GD::gdSmallFont(),
                $x,
                $hspMid,
                $note,
                $self->{'_black'});
    }

    return $hspPos;

}

##############################################################################
sub _drawDirection {
##############################################################################
# This private method is used to draw the arrow direction.

    my($self, $bucketList, $hspPos, $dir, $colorN) = @_;

    while (my $bucket = $bucketList->my_shift()) {

    my $regionList = $bucket->getRegions();

    while(my $region = $regionList->my_shift()) {

        my $start = round( $region->min() * $self->{'_horizRatio'} );
        my $end = round( $region->max() * $self->{'_horizRatio'} );
        my $scaledLength = $end - $start;
        my $x1 = $self->{'_mapUtils'}->getQueryLeft() + $start;
        my $y1 = $hspPos + $hspArrowPad;
        my $x2 = $x1 + $scaledLength;
        my $y2 = $y1 + $arrowHeight;

        $self->_drawArrowedOutlinedFromN($x1, $y1, $scaledLength, $dir, $colorN);

    }

    $hspPos += $hspHeight;

    }

    return $hspPos;

}

#----------------------------------------
# must come before drawGraph if
# you want the ticks everywhere.
##############################################################################
sub _drawQuery {
##############################################################################
# This private method is used to draw the query sequence bar.

    my($self) = @_;


    ### try to space the ticks out reasonably.

    my $rawStep;

    if( $self->{'_srcLength'} < 100 ) { $rawStep = 10; }
    elsif( $self->{'_srcLength'} < 500 ) { $rawStep = 50; }
    elsif( $self->{'_srcLength'} < 1000 ) { $rawStep = 100; }
    elsif( $self->{'_srcLength'} < 5000 ) { $rawStep = 200; }
    else { $rawStep = 500; }

    $self->{'_img'}->line($self->{'_mapUtils'}->getQueryLeft(),
              $topDataOffset,
              $self->{'_mapUtils'}->getQueryLeft()+$self->{'_srcLength'}*$self->{'_horizRatio'},
              $topDataOffset,
              $self->{'_black'});

    $self->{'_img'}->string(GD::gdSmallFont(),
                $self->{'_mapUtils'}->getQueryLeft(),
                $topDataOffset-15,
                "Query",
                $self->{'_black'});


    for(my $rawX=$rawStep; $rawX < $self->{'_srcLength'}; $rawX+=$rawStep) {

    my $str = "$rawX";

    $self->_drawTick( $str, $rawX);

    }

    my $pX = $self->{'_mapUtils'}->getQueryLeft();
    $self->{'_img'}->line($pX,
              $topDataOffset,
              $pX,
              $topDataOffset+2,
              $self->{'_black'});

    $pX = $self->{'_mapUtils'}->getQueryLeft()+int($self->{'_srcLength'}*$self->{'_horizRatio'});

    $self->{'_img'}->line($pX,
              $topDataOffset,
              $pX,
              $topDataOffset+2,
              $self->{'_black'});

}

################################################################################
sub _drawTick {
################################################################################
# This private method is used to draw the tick marks for the query sequence
# bar.

    my ($self, $str, $rawX) = @_;

    my $nudgeTextX = round(length($str)*5/2.0);

    my $pX = int($rawX * $self->{'_horizRatio'});

    push(@{$self->{'_tickList'}}, $pX);

    $self->{'_img'}->line($self->{'_mapUtils'}->getQueryLeft()+$pX,
              $topDataOffset,
              $self->{'_mapUtils'}->getQueryLeft()+$pX,
              $topDataOffset-$tickHeight,
              $self->{'_black'});

    $self->{'_img'}->string(GD::gdSmallFont(),
                $self->{'_mapUtils'}->getQueryLeft()+$pX-$nudgeTextX,
                $topDataOffset-15,
                $str,
                $self->{'_black'});
}

##################################################################################
sub _drawString {
################################################################################
# This private method is used to draw the text string.

    my ($self, $str, $font, $xpos, $ypos, $color) = @_;

    if( !defined( $color ) ) { $color = $self->{'_black'}; }

    my $end = length($str) * $fontWidth;

    $self->{'_img'}->string($font,
                $xpos,
                $ypos,
                $str,
                $color );

    return $end;

}

###################################################################################
sub _annotateIMap {
################################################################################
# This private method is used to initialize the mouseover function.

    my ($self, $wrap, $x1, $y1, $x2, $y2) = @_;

    my $cx1 = $x1 - $arrowWidth;
    my $cy1 = $y1;
    my $cx2 = $x2 + $arrowWidth;
    my $cy2 = $y2;

    my $href = $wrap->getName();

    my $name = $href;

    $self->_print( "<area shape='rect' coords='$cx1,$cy1,$cx2,$cy2' href=\"#" . $href . "_A\" " );

    my $scoreDesc = "p=" . $wrap->getP() . " s=" . $wrap->getScore();

    my $pos = $self->{'_formFieldWidth'} - length($scoreDesc);

    my $englishDesc = $wrap->getDescription();

    # The description can contain a *different* name!

    $name =~ s/([^_]*).*/$1/;

    if( $englishDesc !~ m/$name/i ) { $englishDesc = "$name|$englishDesc"; }

    $englishDesc = substr( $englishDesc, 0, $pos );

    # the description might contain 5' which then
    # confuses the hell out of javascript, so i
    # have to escape those.
    $englishDesc =~ s/\'/\&\#39/g;

    $self->_print( "ONMOUSEOVER='document.daform.notes.value=\"$scoreDesc $englishDesc\"'>\n" );

}

###################################################################################
sub _makeColorBarHelper {
###################################################################################
# This method is used to initialize some variables for color bar.

    my ($self, $min, $sep, $max, $colorN) = @_;

    if(Bio::GMOD::Blast::Graph::ScientificNotation::numberP($min)) {

    $min = abs( Bio::GMOD::Blast::Graph::ScientificNotation::getExponent( $min ) );

    }

    if(Bio::GMOD::Blast::Graph::ScientificNotation::numberP($max)) {

    $max = abs( Bio::GMOD::Blast::Graph::ScientificNotation::getExponent( $max ) );

    }

    return $min.$sep.$max;

}

####################################################################################
sub _makeColorBar {
####################################################################################
# This private method is used to populate the bar parts.

    my ($self) = @_;

    # going from worst to best.
    my @barParts;
    push( @barParts, $self->_makeColorBarHelper( '', '< ', $bucketThreeMax ), 4 );
    push( @barParts, $self->_makeColorBarHelper( $bucketThreeMax, '-', $bucketTwoMax ), 3 );
    push( @barParts, $self->_makeColorBarHelper( $bucketTwoMax, '-', $bucketOneMax ), 2 );
    push( @barParts, $self->_makeColorBarHelper( $bucketOneMax, '-', $bucketZeroMax ), 1 );
    push( @barParts, $self->_makeColorBarHelper( $bucketZeroMax, ' <', '' ), 0 );

    return( @barParts );

}


####################################################################################
sub _drawKey {
####################################################################################
# This private method is used to draw the map keys.

    my ($self) = @_;

    # draw the fixed parts, the arrows.

    my $strOffset = 22;

    my $ypos = $self->{'_realHeight'} - $imgBottomBorder + $bottomDataOffset;

    my $xpos = $self->{'_mapUtils'}->getQueryLeft();

    $strOffset = $self->_drawString("Fwd:",
                    GD::gdMediumBoldFont(),
                    $xpos,
                    $ypos+1,
                    $self->{'_grayDark'});

    $xpos += $strOffset + 4;

    $self->_drawArrowedOutlined($xpos,
                int($ypos+$fontHeight/2),
                9,
                'plus',
                $self->{'_grayDark'},
                $self->{'_grayDark'});


    $xpos += 18;

    $self->_drawString("Rev:",
               GD::gdMediumBoldFont(),
               $xpos,
               $ypos+1,
               $self->{'_grayDark'});

    $xpos += $strOffset + 4;

    $self->_drawArrowedOutlined($xpos,
                int($ypos+$fontHeight/2),
                9,
                'minus',
                $self->{'_grayDark'},
                $self->{'_grayDark'});


    my @barParts = $self->_makeColorBar();


    my $partPad = 10;

    my $scoreStr  = "Neg P Exponent: ";

    # figure out box spacing.

    my $strWidthPart = length($scoreStr) * $fontWidth + $partPad;

    my $strWidthFull = $strWidthPart || '0';

    my $strWidthPartMax;

    for( my $dex = 0; $dex < 5; $dex++ ) {

    my $str = $barParts[$dex*2];

    $strWidthPart = length($str) * $fontWidth + $partPad;

        Bio::GMOD::Blast::Graph::MyUtils::updateBoundRef(\$strWidthPartMax,
                           $strWidthPart,
                      \&Bio::GMOD::Blast::Graph::MyUtils::largerP);

    $strWidthFull += $strWidthPart;

    }

    # center key in image.
    $xpos = $self->{'_mapUtils'}->getQueryLeft() +
    int($self->{'_mapUtils'}->getQueryWidth()-$strWidthFull)/2;

    # nudge it to the left to be optically more balanced.
    $xpos -= 5;

    $self->{'_img'}->string(GD::gdMediumBoldFont(),
                $xpos,
                $ypos+1,
                $scoreStr,
                $self->{'_grayDark'});

    $xpos += length($scoreStr) * $fontWidth + $partPad;

    for( my $dex = 0; $dex < 5; $dex++ ) {

    my $str = $barParts[$dex*2];

    my $clr = $self->_pickColorN($barParts[$dex*2+1]);

    $self->{'_img'}->filledRectangle($xpos,
                     $ypos,
                     $xpos+$strWidthPartMax,
                     $ypos+$fontHeight+5,
                     $clr );

    $strWidthPart = length($str) * $fontWidth;

    $strOffset = ( $strWidthPartMax - $strWidthPart ) / 2;

    $self->{'_img'}->string(GD::gdSmallFont(),
                $xpos+$strOffset,
                $ypos+1,
                $str,
                $self->{'_white'});

    $xpos += $strWidthPartMax;

    }

}

#########################################################################
sub _getArrowedLinePoly {
#########################################################################
# This private method is used to get the coordinates for the arrow
# locations.

    my( $self, $x1, $y1, $scaledLength, $dir) = @_;

    # fudge-a-licious math to prevent the arrows from exploding if the
    # hit is smaller than an arrow width (since we normally draw the
    # arrows inside the bounding box of the hit).
    if( $scaledLength < ($arrowWidth*2) ) {

    my $fudge = (($arrowWidth * 2) - $scaledLength) / 2;

    $x1 -= $fudge;

    $scaledLength += ($fudge*2);

    }

    my $x2 = $x1 + $scaledLength;
    my $y2 = $y1 + $arrowHeight;
    my $ymid = $y1 + $halfArrowHeight;
    my $poly = new GD::Polygon;

    # drawing them with the arrows inside the bounding box.

    if( $self->_rightP($dir) ) {

    # top.
    $poly->addPt( $x1, $y1 );
    $poly->addPt( $x2-$arrowWidth, $y1 );

    # rhs.
    $poly->addPt( $x2, $ymid );
    $poly->addPt( $x2-$arrowWidth, $y2 );

    # bottom.
    $poly->addPt( $x1, $y2 );

    # lhs.
    $poly->addPt( $x1+$arrowWidth, $ymid );

    }
    elsif( $self->_leftP($dir) ) {

    # top.
    $poly->addPt( $x1+$arrowWidth, $y1 );
    $poly->addPt( $x2, $y1 );

    # rhs.
    $poly->addPt( $x2-$arrowWidth, $ymid );
    $poly->addPt( $x2, $y2 );

    # bottom.
    $poly->addPt( $x1+$arrowWidth, $y2 );

    # lhs.
    $poly->addPt( $x1, $ymid );

    }
    else {

    croak( "invalid direction $dir\n" );

    }

    return $poly;

}

#############################################################################
sub _drawArrowedOutlinedFromN {
#############################################################################
# This method is used to draw the arrow outlines

    my ($self, $x1, $y1, $scaledLength, $dir, $colorN) = @_;

    my $light = $self->_pickColorN($colorN, 0);
    my $dark = $self->_pickColorN($colorN, 1);

    $self->_drawArrowedOutlined($x1, $y1,
                $scaledLength,
                $dir, $light, $dark );

}

#############################################################################
sub _drawArrowedOutlined {
#############################################################################
# This method is used to draw the arrow outlines

    my ($self, $x1, $y1, $scaledLength, $dir, $light, $dark) = @_;

    my $poly = $self->_getArrowedLinePoly( $x1, $y1, $scaledLength, $dir );

    $self->{'_img'}->filledPolygon( $poly, $light );

    # put an arrow in the middle, to help distinguish direction.
    # (try to avoid rounding problems.)
    my $xmidLeft = $x1 + int($scaledLength/2) - $halfArrowWidth;
    my $xmidRight = $xmidLeft + $arrowWidth;
    my $ymid = $y1 + $halfArrowHeight;
    my $y2 = $y1 + $arrowHeight;

    # used to use curBgColor but i think all white is more clear.
    if($self->_rightP($dir)) {

    $self->{'_img'}->line($xmidLeft, $y1,
                  $xmidRight, $ymid,
                  $self->{'_white'});

    $self->{'_img'}->line($xmidRight, $ymid,
                  $xmidLeft, $y2,
                  $self->{'_white'});

    }
    else {

    $self->{'_img'}->line($xmidRight, $y1,
                  $xmidLeft, $ymid,
                  $self->{'_white'});

    $self->{'_img'}->line($xmidLeft, $ymid,
                  $xmidRight, $y2,
                  $self->{'_white'});

    }

    # now apply the outline.
    $self->{'_img'}->polygon( $poly, $dark );

}

#####################################################################
sub _getColorNFromP {
#####################################################################
# This private method is used to initialize the color based on the
# pvalue.

    my ($self, $wrap, $darkP) = @_;

    # [[ this assumes that we have 5 partitions,
    # since the number of colors is fixed. ]]

    my $value = $wrap->getP();

    return $self->{'_parts'}->getPartitionIndexFromExtendedValue($value);

}

#####################################################################
sub _pickColorN {
#####################################################################
# This private method is used to pick up a right color for the hit.

    my($self, $n, $darkP) = @_;


    if( !defined($darkP) ) { $darkP = 0; }

    my $color;

    if( $n == 4 ) {

    $color = ( $darkP == 1 ) ? $self->{'_blueDark'} : $self->{'_blue'};

    }
    elsif( $n == 3 ) {

    $color = ( $darkP == 1 ) ? $self->{'_cyanDark'} : $self->{'_cyan'};

    }
    elsif( $n == 2 ) {

    $color = ( $darkP == 1 ) ? $self->{'_greenDark'} : $self->{'_green'};

    }
    elsif( $n == 1 ) {

    $color = ( $darkP == 1 ) ? $self->{'_magentaDark'} : $self->{'_magenta'};

    }
    elsif( $n == 0 ) {

    $color = ( $darkP == 1 ) ? $self->{'_redDark'} : $self->{'_red'};

    }
    else {

    croak( "_pickColorN(): invalid index $n" );
    }

    return $color;

}


####################################################################################
sub _pickNextDebugColors {
####################################################################################
# This private method is used to pick up the debug colors.

    my ($self) = @_;

    my $dex = $self->{'_debugCount'};

    my ($color, $bgColor);

    if( $dex == 0 ) {

    $bgColor = $self->{'_blueDark'};
    $color = $self->{'_blue'};

    }
    elsif( $dex == 1 ) {

    $bgColor = $self->{'_greenDark'};
    $color = $self->{'_green'};

    }
    elsif( $dex == 2 ) {

    $bgColor = $self->{'_cyanDark'};
    $color = $self->{'_cyan'};

    }
    elsif( $dex == 3 ) {

    $bgColor = $self->{'_magentaDark'};
    $color = $self->{'_magenta'};

    }
    elsif( $dex == 4 ) {

    $bgColor = $self->{'_redDark'};
    $color = $self->{'_red'};

    }

    $self->{'_debugCount'} = ++$dex % 5;

    return( $color, $bgColor );

}

###################################################################################
sub _drawStamp {
###################################################################################
# This private method is used to print the date on the map.

    my ($self) = @_;

    my %tomonth = ('0'=>'Jan', '1'=>'Feb', '2'=>'Mar', '3'=>'Apr', '4'=>'May',
           '5'=>'Jun', '6'=>'Jul', '7'=>'Aug', '8'=>'Sep', '9'=>'Oct',
           '10'=>'Nov', '11'=>'Dec');

    my @date = localtime();
    my $year = $date[5] + 1900;
    my $month = $tomonth{$date[4]};
    my $day = $date[3];

    my $dstr = join( "/", $day, $month, $year );
    my $xpos = $self->{'_realWidth'} - (length( $dstr ) * $fontWidth) - $imgRightBorder;
    my $ypos = $self->{'_realHeight'} - $imgBottomBorder + $bottomDataOffset;

    $self->_drawString($dstr,
               GD::gdSmallFont(),
               $xpos,
               $ypos,
               $self->{'_grayDark'});

}

####################################################################################
sub _countHTML {
####################################################################################
# This private method is used to print a short message about how many hits displayed
# on the map.

    my ($self, $shown, $max) = @_;

    my $word;

    if( $max > 1 ) { $word = 'hits'; }
    else { $word = 'hit'; }

#    print( '<center><h1>Summary of BLAST Results</h1></center>' );

    $self->_print( '<p align=center>' );

    if( $shown < $max ) {

    $self->_print( 'The graph shows the highest hits per range.<br>' );
    $self->_print( '<b>Data has been omitted:</b> ' );
    $self->_print( "$shown/$max $word displayed." );

    }
    else {

    $self->_print( 'All hits shown.' );

    }

    $self->_print( "</p>\n" );

}

##################################################################################
sub _writeIMapStart {
##################################################################################
# This private method is used to print a start_form tag, a text field for
# displaying the mouseover message, and a start map tag.

    my ($self) = @_;

    $self->_print( '<center><form name="daform">' );

    $self->_print( '<input type="text" id="notes" value="" size="30">' );

    $self->_print( '<MAP NAME="' . $self->{'_mapName'} . '">' );


}

#################################################################################
sub _writeIMapEnd {
#################################################################################
# This private method is used to draw the end map tag and print the map to the
# stdout (browser).

    my ($self) = @_;

    $self->_print( "</MAP>\n" );

    my $img = sprintf '<img src="%s" usemap="#%s">', $self->{_dstURL} . $self->{_imgName}, $self->{_mapName};
    $self->_print( $img );

    $self->_print( '</form></center>' );

}

#################################################################################
sub _rightP {
#################################################################################
    my ($self, $dir) = @_;

    if( $dir =~ m/plus/i ) { # is plus == right?

    return 1;

    }
    else {

    return 0;

    }

}

#################################################################################
sub _leftP {
#################################################################################
    my ($self, $dir) = @_;

    if( $dir =~ m/minus/i ) { # is minus == left?

    return 1;

    }
    else {

    return 0;

    }

}

#################################################################################
1;
#################################################################################








__END__
=pod

=encoding utf-8

=head1 NAME

Bio::GMOD::Blast::Graph - display a graphical summary of a BLAST report

=head1 DESCRIPTION

This package provides methods for graphically displaying a BLAST
search report.

=head1 METHODS

=head2 new

This is the constructor. It expects to be passed named arguments for
the search outputfile, the file format (blast or fasta), the image
file path, and image url.  It can also accept an optional filehandle
argument, which is the filehandle to which it will print its HTML
output when L</showGraph> is called.  By default, prints to STDOUT.

Usage :

    my $graph = Bio::GMOD::Blast::Graph->new(
        -outputfile => $blastOutputFile,
        -format     => 'blast',
        -dstDir     => $imageDir,
        -dstURL     => $imageUrl
        -fh         => \*STDOUT,
        );

=head2 showGraph

This method prints the map to stdout (web browser).

Usage:

    $graph->showGraph;

=head2 getImageFile

This method returns the newly created image file name (with full path).

Usage:

    my $imageFile = $graph->getImageFile;

=head2 hitNameArrayRef

This method returns the array ref for the hit names.

Usage:

    my $hitArrayRef = $graph->hitNameArrayRef;

    foreach my $hitName (@$hitArrayRef) {

       # do something useful here

    }

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

