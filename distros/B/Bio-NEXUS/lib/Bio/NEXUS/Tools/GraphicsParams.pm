#######################################################################
# Grahics.pm
#######################################################################
# Author: Chengzhi Liang, Weigang Qiu, Eugene Melamud, Peter Yang
# $Id: GraphicsParams.pm,v 1.2 2008/06/16 19:53:41 astoltzfus Exp $

#################### START POD DOCUMENTATION ##########################

=head1 NAME

Graphics - represents a character block (Data or Characters) of a NEXUS file

=head1 SYNOPSIS


=head1 DESCRIPTION

This is a class representing a character block or data block in NEXUS file

=head1 FEEDBACK

All feedbacks (bugs, feature enhancements, etc.) are greatly appreciated. 

=head1 AUTHORS
 Vivek Gopalan (gopalan@umbi.umd.edu)
 Chengzhi Liang (liangc@umbi.umd.edu)
 Weigang Qiu (weigang@genectr.hunter.cuny.edu)
 Eugene Melamud (melamud@carb.nist.gov)
 Peter Yang (pyang@rice.edu)

=head1 VERSION

$Revision: 1.2 $

=head1 METHODS

=cut

package Bio::NEXUS::Tools::GraphicsParams;

use strict;
use Data::Dumper;
use Carp;

use Bio::NEXUS; our $VERSION = $Bio::NEXUS::VERSION;

### Class Variables

our $DefaultTreeWidth 		=  5;
our $DefaultCharLabelBlockWidth =  5;
our $DefaultVerticalOtuSpacing  =  1.2;

=head2 new

 Title   : new
 Usage   : block_object = new NEXUS::CharacterBlock($block_type, $block, $verbose, $wasdata);
 Function: Creates a new NEXUS::CharacterBlock object
 Returns : NEXUS::CharacterBlock object
 Args    : verbose flag (0 or 1), type (string) and the block to parse (string)

=cut

sub new {
	my $class = shift;
	my $data ={
	     'Font'			 => 'Times-Roman',# font to use for OTU labels 
	     'isVerbose'  		 => 0,
	     'fontWidth' 		 => 1,
	     'maximumWtvalue' 		 => 10,
	     'fontHeight' 		 => 1,
	     'PageHeightInches'  	 => 11,		 # page height in inches for your default page size
	     'PageWidthInches' 		 => 8.5,	 # page width in inches for your default page size
	     'SpacingToFontRatio' 	 => 1,		 # ratio of space b/t rows to font height
	     'histoScale' 		 => 3,		 # max histogram weight
	     'treeLineWidth' 	         => 2,           # width of tree lines
             'boxLineWidth'              => 1,           # width of bounding box line
	     'labelMatrixGapWidth'       => 10,          # width of reference lines between tree & matrix
	     'charLabelMatrixGapWidth'   => 10,          # width of reference lines between tree & matrix
	     'treeNodeRadius'            => 5,           # radius of dot representing a node
	     'pieChartRadius'            => 10,		 # radius of pie chart for intron history
	     'characterFont'             => 'Courier',   # font to use for character matrix
	     'lowerXMargin'              => 15,          # size of left margin 
	     'upperXMargin'              => 15,          # size of right margin
	     'lowerYMargin'              => 15,          # size of upper margin
	     'upperYMargin'              => 15,          # size of bottom margin
	     'xsize'                     => 0,	
             'ysize'                     => 0,
	     'upperXbound'               => 0,
	     'lowerXbound'               => 0,		
	     'lowerYbound'               => 0,		
	     'upperYbound'               => 0,
	     'longestCharLabelLength'    => 0,
	     'histogramHeight'           => 0,
	     'charactersXwidth'          => 0,
	     'characterStartXPos'        => 0,
	     'maxTaxLabelwidth'          => 0,
	     'paneHeight'                => 0,
	     'TreeWidth'                 => 0,           # width in inches of longest branch of tree
	     'verticalOtuSpacing'        => 0,           # in POINTS, vertical space between rows (tree tips) 
	     'charLabelBlockWidth'       => 0,           # number of columns between space columns
	};
	bless ($data,$class);
	return $data;
}

=head2 AUTOLOAD

 Title   : AUTOLOAD
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut

sub AUTOLOAD {
	my $self    = shift;
	my $value   = shift;
	my $attrib  = shift;
	my $command = our $AUTOLOAD;

	$command    =~ s/.*://;
	$command    = lc $command;
	(my $parsed_var = $command) =~s/^.*_//;
	foreach my $var (keys (%{$self})) {
		next if ($parsed_var ne (lc  $var));
		if ($command =~/get_/) {
			return $self->{$var}	
		} elsif ($command =~/set_/) {
			$self->{$var} = $value;	
			return ;	
		}
	}
	die "$! :Undefined subroutine &$AUTOLOAD called\n";
       
}

=head2 set_upperXbound

 Title   : set_upperXbound
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut

sub set_upperXbound {
	my $self = shift;
	my $upperXbound   = $self->get_lowerXbound + $self->get_TreeWidth +  $self->get_maxTaxLabelwidth+ $self->get_labelMatrixGapWidth+ $self->get_charactersXwidth;
	$self->{'upperXbound'} = $upperXbound;
	$self->set_characterStartXpos;

}

=head2 set_lowerXbound

 Title   : set_lowerXbound
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut

sub set_lowerXbound {
	my $self = shift;
	my $args = shift;
	$self->{'lowerXbound'} = $self->get_lowerXMargin;
}

=head2 set_upperYbound

 Title   : set_upperYbound
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut

sub set_upperYbound {
	my $self = shift;
	#$self->{'upperYbound'} = $self->get_lowerYbound + $self->get_TreeHeight;
	$self->{'upperYbound'} = $self->get_lowerYbound + $self->get_paneHeight;

}

=head2 set_lowerYbound

 Title   : set_lowerYbound
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut

sub set_lowerYbound {
	my $self = shift;
	$self->{'lowerYbound'} = $self->get_lowerYMargin + $self->get_longestCharLabelLength + $self->get_histogramHeight + $self->get_charLabelMatrixGapWidth;
}

=head2 set_charactersXwidth

 Title   : set_charactersXwidth
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut

sub set_charactersXwidth {
use POSIX qw(ceil);

	my $self  = shift;
        my $block = shift;
	$self->{'charactersXwidth'} = $block->get_nchar * $self->get_fontWidth + ceil($block->get_nchar /  $self->get_charLabelBlockWidth) * $self->get_fontWidth ;
}

=head2 set_maxTaxLabelwidth

 Title   : set_maxTaxLabelwidth
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut

sub set_maxTaxLabelwidth {
	my $self  = shift;
	my $taxlabels = shift;
	my $max = 0;
	foreach my $tax_labels (@$taxlabels) {
		$max = length($tax_labels) if (length($tax_labels) > $max);
	}
	$self->{'maxTaxLabelwidth'} = $max * $self->get_fontWidth;
}

=head2 set_paneHeight

 Title   : set_paneHeight
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut

sub set_paneHeight {
	my $self  = shift;
	my $ntax = shift;
	$self->{'paneHeight'} = $ntax * ($self->get_verticalOtuSpacing);
}

=head2 set_ysize

 Title   : set_ysize
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut

sub set_ysize {
	my $self = shift;
	$self->{'ysize'} = $self->get_upperYbound + $self->get_upperYMargin;

}

=head2 set_xsize

 Title   : set_xsize
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut

sub set_xsize {
	my $self = shift;
	$self->{'xsize'} = $self->get_upperXbound + $self->get_upperXMargin;

}

=head2 set_histogramHeight

 Title   : set_histogramHeight
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut

sub set_histogramHeight {
	my $self = shift;
	$self->{'histogramHeight'} = $self->get_histoScale * $self->get_fontHeight;		# height of histogram
}

=head2 set_longestCharLabelLength

 Title   : set_longestCharLabelLength
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut

sub set_longestCharLabelLength {
	my $self = shift;
	my @array = @_;
	my $max = 0;
	foreach my $element (@array) {
		$max = length($element) if (length($element) > $max);
	}
	$self->{'longestCharLabelLength'} = $max * $self->get_fontHeight ;
}

=head2 set_verticalOtuSpacing

 Title   : set_verticalOtuSpacing
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut

sub set_verticalOtuSpacing {
	my $self = shift;
	my $arg  = shift || 1.0 ;
	$self->{'verticalOtuSpacing'} = $arg * $self->get_fontHeight ; 
}

=head2 get_charLabelBlockWidth

 Title   : get_charLabelBlockWidth
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut

sub get_charLabelBlockWidth {
	my $self = shift;
	return $self->{'charLabelBlockWidth'}; 
}

=head2 set_charLabelBlockWidth

 Title   : set_charLabelBlockWidth
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut

sub set_charLabelBlockWidth {
	my $self = shift;
	my $arg = shift;
	$self->{'charLabelBlockWidth'} = $arg; 
}

=head2 set_TreeHeight (obsolete)

 Title   : set_TreeHeight
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut
##### Obsolete ####
sub set_TreeHeight {
	my $self = shift;
	my $tree = shift;
	my $tree_height = 0.0; 
	foreach my $node (@{$tree->node_list}) {
		$tree_height = $node->ycoord if ($node->ycoord > $tree_height);
	}
	$self->{'TreeHeight'} = $tree_height;
}

=head2 set_maxNodeWidth (obsolete)

 Title   : set_maxNodeWidth
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut

##### Obsolete ####
sub set_maxNodeWidth {
	my $self = shift;
	my $tree = shift;
	my $maxNodeWidth = 0; 
	foreach my $otu (@{$tree->otu_list}){
		$maxNodeWidth = length($otu) if ($maxNodeWidth < length($otu));
	}
	$self->{'maxNodeWidth'} = ($maxNodeWidth* $self->get_fontWidth) + $self->get_fontWidth;
}

=head2 set_characterStartXpos

 Title   : set_characterStartXpos
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut

sub set_characterStartXpos {
	my $self = shift;
	$self->{'characterStartXPos'} = $self->get_upperXbound - $self->get_charactersXwidth;
}

=head2 is_number

 Title   : is_number
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut

sub is_number {
	my $self = shift;
	my $arg=$_[0];
	my $var=$_[1];
	if ($arg =~ /(\d+\.?\d*|\.\d+)/) {
		return 1;
	} else {
		return 0;
		#die "Execution failed: Incorrect number: $arg for option $var\n";
	}
}
1;
