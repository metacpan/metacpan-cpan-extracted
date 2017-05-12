#!/usr/bin/perl -w

######################################################################
# nexplot.pl (was plottree.pl prior to 9/15/03; the complete revision 
#   log from plottree.pl is in the initial version of nexplot.pl)
######################################################################
#
# $Author: thladish $
# $Date: 2006/08/24 06:41:57 $
# $Revision: 1.36 $
# $Id: nexplot.pl,v 1.36 2006/08/24 06:41:57 thladish Exp $

use Data::Dumper;
use Bio::NEXUS;
use strict;
use Getopt::Std;
use Pod::Usage;

#
# GLOBAL VARS
#
my $DEBUG = 0; #get verbose messages on stdout if true.

#20040119 todo 1. do they all need to be global?

my %runtimeOptions;			# Contains hash of options defined by the user
my $inputFile;				# The NEXUS file to read from
my $verticalOtuSpacing;		# Vertical spacing between OTUs (in PostScript points, 72 pts = 1 inch)
my $defaultFont;			# The default font used for displaying OTU names and the title
my $titleFont;				# Font typically used for displaying titles (as of now, $defaultFont)
my $fontSize;				# Typical font size for displaying OTU names
my $lowerXbound;			# Lower X bound for tree
my $lowerYbound;			# Lower Y bound for tree (above scale)
my $blockWidth;				# Frequency of spaces between characters to display (thiss equen cefor examp le=5)
my $pageDimensionRatio;		# Ratio of page height to width
my $pageWidthInches;		# Page width in inches
my $pageHeightInches;		# Page height in inches
my $pageWidthPoints;		# Page width in points
my $pageHeightPoints;		# Page height in points
my $treeWidth;				# Width of tree in points
my $histogramHeight;		# Height of weight histogram in points
my $treeHeight;				# Height of tree in points
my %sequences;				# Character entries for each OTU (key'd by name)
my @trees;					# Trees in the NEXUS file
my %setsColors;				# User-specified set names with corresponding colors
my @setsColorsKeys;			# Keeps track of the order of sets specified by user
my $nodeColorMap;			# Colors of nodes as established by SPAN block in NEXUS
my @weights;				# Weights in the NEXUS file
my $treeName;				# The name of the tree being displayed
my @columnLabels;			# Array containing character labels
my %dataPresent;			# Indicates NEXUS data presence/absence (key'd by element)
my $amp;					# Conversion factor between x coordinates and PostScript x points
my $root;					# Root node of $tree
my @nodes;					# Holds list of nodes (OTUs and internal nodes)
my $tree;					# Tree selected to be displayed

######################################################################
#
# hard-coded values, including default parameter values 
#
######################################################################

my $defaultDefaultFont = 'Times-Roman'; # font to use for OTU labels 
my $defaultSpaceBetweenRows = 18;      # in POINTS, vertical space between rows (tree tips) 
my $defaultBlockWidth = 10;            # number of columns between space columns
my $defaultFontToSpaceRatio = 0.8;     # ratio of font height to space between rows
my $defaultPageHeightInches = 11;      # page height in inches for your default page size
my $defaultPageWidthInches = 8.5;      # page width in inches for your default page size
my $treeLineWidth = 2;                 # width of tree lines
my $boxLineWidth = 1;                  # width of bounding box line
my $referenceLineWidth = 1.8;          # width of reference lines between tree & matrix
my $treeNodeRadius = 2;                # radius of dot representing a node
my $characterFont = 'Courier';    # font to use for character matrix
my $RGBcolorHash = { 	red 	=> '1.0 0.0 0.0',
						green 	=> '0.0 0.5 0.0',
						forest 	=> '0.0 0.2 0.0',
						blue 	=> '0.0 0.0 1.0',
						aqua 	=> '0.0 0.5 0.5',
						orange 	=> '1.0 0.3 0.0',
						purple 	=> '0.4 0.0 0.6',
						grey 	=> '0.4 0.4 0.4',
						gray 	=> '0.4 0.4 0.4',
						brown 	=> '0.5 0.2 0.0',
						pink 	=> '0.9 0.0 0.4',
						black 	=> '0.0 0.0 0.0',
						};

&parseArgs();	# Parse arguments, validate them, and set them correctly.
&read_nexus();	# Read in the NEXUS file and extract relevant information.

&__prolog();	# Print prolog: Define some functions, print header info, etc.
&__psSetup();	# Set up the plot boundaries; perform plot rotation if necessary.

    # PRINT TREE AND OTHER ELEMENTS IF PRESENT
&__print_tree($root, $lowerXbound, $lowerYbound) if (!$runtimeOptions{'m'});
&__print_matrix($root, $lowerXbound, $lowerYbound) if ($runtimeOptions{'m'});

if (!($runtimeOptions{t})) {		# Character labels, weights
	&__print_char_labels(@columnLabels) if @columnLabels;
	&__plot_wts(@weights) if ($dataPresent{weights});
}

&__print_boot_strap() if ($runtimeOptions{b});
&__end_post_script();

close(OUTPUT) if ($runtimeOptions{f});

exit;


#################################################################### SUBROUTINES

sub parseArgs {
	warn("Setting up options...\n") if $DEBUG;
	getopts('hdc:vbgirtmosaf:C:BF:W:H:I:T:S:R:VU:', \%runtimeOptions) or die "ERROR: Unknown options and/or options requiring arguments do not have them.\n";
	$runtimeOptions{h} and pod2usage(VERBOSE => 1);
	$runtimeOptions{d} and pod2usage(VERBOSE => 2);

	if ( $runtimeOptions{ 'V' } ) { die '$Id: nexplot.pl,v 1.36 2006/08/24 06:41:57 thladish Exp $',"\n"; }
	
	$inputFile = shift @ARGV;
	$inputFile or pod2usage(VERBOSE => 0);
	$treeName = shift @ARGV;

	# die if options are selected that will conflict when enabled together.
	# cannot enable any mix of -s (multiple pages 1 page tall), -o (multiple pages), and -a (one page autofit).
	if(($runtimeOptions{'s'} && $runtimeOptions{o}) || ($runtimeOptions{'s'} && $runtimeOptions{a}) || ($runtimeOptions{o} && $runtimeOptions{a})) {
		die "ERROR: Only one page setup option may be enabled at once.\n";
	}
	# cannot specify invalid cladogram option
	if ($runtimeOptions{c}) {
		if (! ($runtimeOptions{c} =~ /(normal|accelerated)/i)) {
			die "ERROR: Cladogram option is invalid.\n";
		}
	}
	# cannot specify both tree-only and matrix-only options
	if ($runtimeOptions{t} && $runtimeOptions{'m'}) {
		die "ERROR: The tree-only and matrix-only options cannot be enabled at the same time.\n";
	}	
	# where we are going to print output to. only selected if 
	if($runtimeOptions{f}) {
		open (OUTPUT,">$runtimeOptions{f}") or die("You do not have the permissions to create this file.\n");
		select (OUTPUT);
	}
	# use nexus sets and user-specified colors
	if($runtimeOptions{U}) {
		my @keys = (split(/\s+/,$runtimeOptions{U}));
		%setsColors = (@keys);
		my $j = 0;
		for (my $i = 0; $i < scalar(@keys); $i++) {
			if ($j == 0) {
				push (@setsColorsKeys, $keys[$i]);
				$j = 1;
			} elsif ($j == 1) {
				$j = 0;
			}
		}
	};
	
	$defaultFont = ( exists($runtimeOptions{F}) ? $runtimeOptions{F} : $defaultDefaultFont );
	$titleFont = $defaultFont;
	$blockWidth = ( exists($runtimeOptions{C}) && &isNumber($runtimeOptions{C}) ? $runtimeOptions{C} : $defaultBlockWidth );
	$verticalOtuSpacing = ( exists($runtimeOptions{S}) && &isNumber($runtimeOptions{S},'S') ? $runtimeOptions{S} * 72 : $defaultSpaceBetweenRows );
	my $fontToSpacingRatio = ( $runtimeOptions{R} && isNumber($runtimeOptions{R},'R') ? $runtimeOptions{R} : $defaultFontToSpaceRatio ); # default ratio
	$pageWidthInches = ( exists($runtimeOptions{W}) && &isNumber($runtimeOptions{W},'W') ? $runtimeOptions{W} : $defaultPageWidthInches );
	$pageHeightInches = ( exists($runtimeOptions{H}) && &isNumber($runtimeOptions{H},'H') ? $runtimeOptions{H} : $defaultPageHeightInches );
	$pageDimensionRatio = $pageHeightInches / $pageWidthInches;	# Use to determine whether plot should be rotated
	
	$pageWidthPoints=$pageWidthInches*72;			# Convert to points (for PostScript)
	$pageHeightPoints=$pageHeightInches*72;
	$fontSize = $fontToSpacingRatio * $verticalOtuSpacing;
	$lowerXbound = 0;			# Relative to tree
	$lowerYbound = $fontSize + 20;		# Give space for scale
	$histogramHeight = 3 * $verticalOtuSpacing;		# height of histogram

	$treeWidth = ( exists($runtimeOptions{T}) && &isNumber($runtimeOptions{T},'T') ? $runtimeOptions{T} * 72 : 720 ); # max horizontal tree width	
}

sub isNumber {
	my $arg=$_[0];
	my $var=$_[1];
	$arg =~ /(\d+\.?\d*|\.\d+)/ or die "Execution failed: Incorrect number: $arg for option $var\n";
}

sub read_nexus {
	# Parse nexus file
	my $nexusObject;
	my $taxSets;
	if($runtimeOptions{v}) {
	    $DEBUG=1;
		$nexusObject = new Bio::NEXUS($inputFile,1);
	} else {
		$nexusObject = new Bio::NEXUS($inputFile);
	}
	# Read in NEXUS blocks from NEXUS object
	foreach my $block ( @{$nexusObject->get_blocks()} ) {
		if ($block->{'type'} =~ /characters/i && (! $runtimeOptions{I} || $block->{'title'} =~ /$runtimeOptions{I}/)) {
		    warn("Grabbing characters block from NEXUS file...\n") if $DEBUG;
		    my $characterLabels = $block->get_charlabels;
		    my $seqLength = $block->get_nchar;
		    %sequences = %{$block->get_otuset->get_seq_string_hash};
			warn("Setting column labels...\n") if ( $DEBUG );
			if ($characterLabels && @$characterLabels) { 
				@columnLabels = @$characterLabels; 
			} elsif ($seqLength) { # not labeled, e.g., typical dna or aa seq alignment
				@columnLabels = ();
				for (1 .. $seqLength) {push @columnLabels, $_;}
			}
		    $dataPresent{characters} = 1;
		    
			if ( $nexusObject->get_block('assumptions') ) {
				my @assumptions_blocks = @{ $nexusObject->get_blocks('assumptions') };
				for my $asmpt_block (@assumptions_blocks) {
					if ( (@assumptions_blocks == 1) || ($asmpt_block->get_link( 'characters' ) eq $block->get_title() )) {
						@weights = ();
						warn("Grabbing assumptions block from NEXUS file...\n") if $DEBUG;
						foreach my $assumption(@{$asmpt_block->get_assumptions()}) {
							if( $assumption->is_wt() ) {
								@weights=@{$assumption->get_weights()};
								$dataPresent{weights} = 1;
								$dataPresent{'CORE_column_scores'} = ( $assumption->get_name() eq 'CORE_column_scores' ) ? 1 : 0;
							}
							if ( $DEBUG ) {
								warn("No weights found in this file\n") unless $dataPresent{weights};
								warn("Weights have been found in this file\n") if $dataPresent{weights};
							}
						}
					}
				}
			}
		}
		if ($block->{'type'} =~ /trees/i) {
			warn("Grabbing trees block from NEXUS file...\n") if $DEBUG;
			$tree = $block->get_tree($treeName);
			# EXTRACT TREE DATA
			$treeName =  $tree->get_name() || "unnamed";
			$tree->_set_xcoord($treeWidth,$runtimeOptions{c});
			$tree->_set_ycoord($lowerYbound,$verticalOtuSpacing);
			@nodes = @{$tree->get_nodes()};
			$root = $tree->get_rootnode();
			warn("Getting names of OTUs in tree...\n") if ( $DEBUG );
            my @sorted;
			for my $node (@nodes) {
                push @sorted, $node->_get_xcoord();
			}
			@sorted = sort { $a <=> $b } @sorted;
		    $amp = $treeWidth / pop @sorted; # unit of branch length
		    for my $node (@nodes) {
                $node->_set_xcoord( $node->_get_xcoord() * $amp );
		    }
			$dataPresent{trees} = 1;
		}
		if ($block->{'type'} =~ /sets/i && $runtimeOptions{U}) {
			warn("Grabbing sets block from NEXUS file...\n") if $DEBUG;
			$taxSets = $block->get_taxsets();
		}	
	}
	if ($dataPresent{characters} != 1 && $runtimeOptions{I}) {
		die ("Specified Characters Block not found\n");
	}
	
	if ($runtimeOptions{U}) {
		my $taxlabels = $nexusObject->get_block('taxa')->get_taxlabels();
		for my $userSetName (@setsColorsKeys) {
			if ($nexusObject->get_block('sets')) {
				for my $taxSetName (keys %$taxSets) {
					if ($userSetName eq $taxSetName) {
						for my $taxon (@{$$taxSets{$taxSetName}}) {
							${$nodeColorMap}{$taxon} = $$RGBcolorHash{$setsColors{$userSetName}};
						}
					}
				}
			}
			for my $taxlabel (@$taxlabels) {
				if ($userSetName eq $taxlabel) {
					${$nodeColorMap}{$taxlabel} = $$RGBcolorHash{$setsColors{$userSetName}};
				}	
			}
		}
	}
	# propagating taxonomic coloring up the tree 
	if ( defined( $nodeColorMap ) ) { 
	    $root = $tree->get_rootnode(); 
	    &AssignStateToNode( $root, "0 0 0", $nodeColorMap );
	} 	
	die "No tree in file $inputFile\n" unless $tree;
}

sub AssignStateToNode { 
# AssignStateToNode -- propagate colors or other states up a tree
#
# Technically, what we are doing here is reconstructing ancestral states 
# based on a transition model of infinite cost (zero rate), so that no 
# transitions are allowed.  Thus, an ancestor is assigned to a state 
# _i_ if and only if all of its descendants are assigned to state _i_.  
#
# this function 
#    * probably should be put in a library and named something like 
#      "AssignAncestralStatesByConsensus"; 
#    * maps states to the *names* of nodes, not to their object refs;
#    * allows for polytomies; 
#    * does not assume all OTUs have defined states, but note that 
#       any undefined states of OTUs *will remain undefined*
    my $node = shift;          # node object
    my $unknownState = shift;  # state to assign when no other assignment can be made 
    my $map = shift;           # hash with any available states

    my $name = $node->{'name'}; 
    my $lastState = undef; 
    my $assignable = 1; 

    # return if state already exists OR if the node is an OTU
    return if (defined($map->{$name}) || $node->is_otu() ); 

    # Go through children and make sure all children are the same state
    foreach my $child (@{$node->children()}) {
		my $childname = $child->{'name'};
		&AssignStateToNode($child, $unknownState, $map) unless $map->{$childname};
		if ( defined($lastState) && $$map{$childname} ne $lastState ) { 
		    $assignable = 0; 
		}
		$lastState = $map->{$childname}; 
    }
    return( $map->{ $name } = ( $assignable ? $lastState : $unknownState ) ); 
} 

sub __prolog {
	print "%!PS-Adobe-3.0\n";
	print "%%Pages: 1\n";
	print "%%Title: ", $treeName, "\n";
	print "%%Creator: Weigang Qiu / Peter Yang, CARB, UMBI, Rockville, MD\n";
	print "%%CreationDate: ", `date`; # backtick for unix shell command "date"
	print "%%BoundingBox: 0 0 $pageWidthPoints $pageHeightPoints\n" unless $runtimeOptions{o};
	print "%%Orientation: Portrait\n";
	print "%%EndComments\n\n";
	print "%%BeginProlog\n";
	# Hard copy: use BigPrint program from "Postscript cookbook"
	# Current margins: 1/2" inch margins all around
	# Substituted clipping path for this command:
	#	leftmargin botmargin pagewidth pageheight rectclip
	if ($runtimeOptions{o} || $runtimeOptions{'s'}) {
		print<<END_OF_BIGPRINT;

		/inch {72 mul} def
		/leftmargin .5 inch def
		/botmargin .5 inch def
		/pagewidth $pageWidthInches 1 sub inch def
		/pageheight $pageHeightInches 1 sub inch def

		/BigPrint
		{
			/rows exch def
			/columns exch def
			/bigpictureproc exch def
			leftmargin botmargin pagewidth pageheight rectclip
			leftmargin botmargin translate
			0 1 rows 1 sub
		  	{ 	/rowcount exch def
				0 1 columns 1 sub
				{ 	/colcount exch def
					gsave

					pagewidth colcount mul neg
					pageheight rowcount mul neg
					translate

					bigpictureproc

					gsave showpage grestore
					grestore
				} for
			} for
  		} def

END_OF_BIGPRINT

	}

	# "vshow" from cookbook: vertical text (for char labels)
	# Modifications:
	# Move up. Original: "0 lineskip neg rmoveto", moving down
	# No centering.  Original: "thechar stringwidth pop 2 div neg 0 rmoveto "
	print <<END_OF_VSHOW;
	/vshowdict 4 dict def
	/vshow
	{ 	vshowdict begin
		/thestring exch def
		/lineskip exch def
		thestring
		{ 	/charcode exch def
			/thechar ( ) dup
			0 charcode put def
			0 lineskip rmoveto
			gsave
			thechar stringwidth pop neg 0 rmoveto
			thechar show
			grestore
		} forall
		end
	} def
END_OF_VSHOW
	print <<END_OF_SHOWCHARLABELS;
	/showCharLabels {
		/letterwidth exch def
		/blockWidth exch def
		/size exch def
		/numLabels exch def
		/charLabels exch def
		/arrayPos 0 def
		/realPos 1 def
		{ 
			arrayPos numLabels gt {exit} if
			arrayPos 0 ne arrayPos blockWidth mod 0 eq and {/realPos realPos 1 add def} if
			letterwidth realPos mul 0 moveto 
			size charLabels arrayPos get vshow
			/arrayPos arrayPos 1 add def
			/realPos realPos 1 add def
		} loop
	} def
END_OF_SHOWCHARLABELS

	# Define quick function for line drawing
	print "\t/l {newpath moveto lineto stroke} def\n";
	printf "/defaultfont /$defaultFont findfont $fontSize scalefont def\n";

	printf "/titlefont /%s-Bold findfont %.f scalefont def\n", $titleFont, $fontSize*2;
	print "/characterfont /$characterFont findfont $fontSize scalefont def\n";
	print "%%EndProlog\n\n";
}

sub __psSetup {
	my $upperYbound;
	print "%%BeginSetup\n",
	      "\t1 setlinecap\n",
	      "\t1 setlinejoin\n",
	      "\t$treeLineWidth setlinewidth newpath\n",
	      "%%EndSetup\n",
	      "%%Page: 1\n%%BeginPageSetup\n";


    # DETERMINE PLOT BOUNDARIES
	$treeHeight = 0;

	# Find tree maximum (x and y directions)
	print "/treemax 0 def\n";
	printf "\t\tcharacterfont setfont\n";
	print "\t\t/letterwidth (a) stringwidth pop def\n";
	print "defaultfont setfont\n";
	&__find_treemax($root);
	print "/treemax treemax 36 add def\n";	# give space for printing character table

	# Find x boundary
	# If only the tree needs to be printed (either by choice or because there is
	# nothing else, treemax will be used as the x boundary.
	if($dataPresent{characters} && (! $runtimeOptions{t})) {
		&__find_xbound($root);
	} else {
		print "/xbound treemax def\n";
	}

	# Determine y boundary
	$upperYbound = $treeHeight;
	$upperYbound += 1/2 * $verticalOtuSpacing;
	if (! $runtimeOptions{t}) {
		$upperYbound += &__find_longest_label(@columnLabels) if @columnLabels;
		$upperYbound += 4 * $verticalOtuSpacing if $dataPresent{weights};
		$upperYbound += $verticalOtuSpacing unless $dataPresent{weights};
	} 
	else {
		$upperYbound += $fontSize * 2;
	}
	print "/ybound $upperYbound def\n";
	&__scale_rotate();
	print "%%EndPageSetup\n";
}

sub __find_treemax {
# Finds the maximum x and y ranges of the tree
	my $node = shift;
	my $name = $node->get_name();
	my $x1 = $node->_get_xcoord();
	my $y1 = $node->_get_ycoord();
	if ($node->is_otu() || $runtimeOptions{i}) {
		# For each item, computes branch length with name and compares to highest known value
		my ($x, $y) = ($x1 + 7.5, $y1 - 2.5);
		printf "/branchlength ($name) stringwidth pop $x add ceiling def\n";
		print "treemax branchlength le {/treemax branchlength def} if\n";
		$treeHeight=$y if ($y > $treeHeight);
	}
	if (not $node->is_otu() ) {
		foreach my $child (@{$node->get_children()} ) {
			&__find_treemax($child);
		}
	}
}

sub __find_xbound {
# Picks first OTU and finds treemax plus character length, that is,
# the x range of the entire plot
	my ($node) = @_;
	my $sequence = $sequences{ $node->get_name() };
	my $x1 = $node->_get_xcoord();
	my $y1 = $node->_get_ycoord();
	if (not $node->is_otu()) {
		foreach my $child (@{$node->get_children()} ) {
			return 1 if &__find_xbound($child, $x1, $y1);
		}
		return 0;
	}
	my ($x, $y) = ($x1 + 7.5, $y1 - 2.5);
	if (defined $sequence) {
		my $display_seq = &__seqForDisplay($sequence);
		print "characterfont setfont\n";
		print "/xbound treemax (",$display_seq, ") stringwidth pop add def \n";
		return 1;
	}
	return 0;
}

sub __find_longest_label {
	my @array = @_;
	my $str = $array[$#array];
	$str =~ s/-/\|/;
	my $len=(length($str))*$fontSize;
	return $len;
}

sub __scale_rotate {
    # DETERMINE EFFECTS OF PAGE FORMATTING OPTIONS
	if ($runtimeOptions{a}) {
		print "/pagehp ybound def /pagewp xbound def\n";
	} else {
		print "/pagehp $pageHeightPoints def /pagewp $pageWidthPoints def\n";
	}
	print "<< /PageSize [ pagewp pagehp ] >> setpagedevice\n";
	print "gsave\n";
	# If BigPrint is enabled, then convert the actual code into a function that BigPrint
	# can use to split up into multiple sheets of paper. If not, then this function definition
	# is not needed.
	if ($runtimeOptions{o}) {
		# Determine number of pages needed to print if page is kept the same and if page is rotated.
		# Then choose the option with the lesser number of pages. (Only used with BigPrint option.)
		# If plot is landscape, move origin to the right and rotate 90 degrees
		print "/xcolr ybound 40 add pagewp 72 sub div ceiling def\n";
		print "/ycolr xbound 40 add pagehp 72 sub div ceiling def\n";
		print "/nprotate xcolr ycolr mul def\n";
		print "/ycols ybound 40 add pagehp 72 sub div ceiling def\n";
		print "/xcols xbound 40 add pagewp 72 sub div ceiling def\n";
		print "/npsame xcols ycols mul def\n";
#		print "nprotate = npsame = \n";
		print "/pageratio pagehp pagewp div def\n";
		print "npsame 1 eq nprotate 1 eq and \n";
		print "{/rotatepage ybound xbound div 1 le pageratio 1 le ne def}\n";
		print "{npsame nprotate ge {/rotatepage false def /xcol xcols def /ycol ycols def}\n";
		print "                    {/rotatepage true def /xcol xcolr def /ycol ycolr def} ifelse}\n";
		print "ifelse \n";
		print "/printposter { gsave \n";
		print "\trotatepage\n";
		print "\t\{ybound 40 add ", $pageWidthPoints - 72, " div ceiling ", $pageWidthPoints-72, " mul \n";
		print "\t0 translate 90 rotate 20 20 translate\}\n";
		print "\t{20 20 translate} ifelse\n";
#		print "\t0 translate \n";	# Used for debugging purposes
#		__print_circle(0,0,5,1,1,0);
#		print "90 rotate 36 36 translate\}\n";
#		print "\t{\n";
#		__print_circle(0,0,5,1,1,0);
#		print "36 36 translate} ifelse\n";
	}
	elsif ($runtimeOptions{'s'}) {
		print "/sca pagehp 72 sub ybound 45 add div def\n";
		print "/xcol xbound sca mul pagewp 72 sub div ceiling def \n";
		print "/ycol 1 def\n";
		print "/pageratio pagehp pagewp div def\n";
		print "/printposter { gsave \n";
		print "20 sca mul 20 sca mul translate sca sca scale\n";
#		__print_circle(0,0,5,1,0,0); # Used for debugging purposes
	}
	else {
		print "/pageratio pagehp pagewp div def\n";
		print "/rotatepage ybound xbound div 1 le pageratio 1 le ne def\n";
		print "/ysca pagehp 72 sub ybound div def\n";
		print "/xsca pagewp 72 sub xbound div def\n";
		print "rotatepage\n";
		print "\t{pagewp 36 sub 36 translate 90 rotate\n";
		print "\t/xsca pagehp 72 sub xbound div def\n";
		print "\t/ysca pagewp 72 sub ybound div def\} {36 36 translate} ifelse\n";
		print "\tysca xsca le {ysca ysca scale} {xsca xsca scale} ifelse \n";
	}
}

sub __print_tree {
	my ($node, $x0, $y0) = @_;
	my $name = $node->get_name();
	my $x1 = $node->_get_xcoord();
	my $y1 = $node->_get_ycoord();
	my $color = $nodeColorMap->{$name};
#	print "\%START TREE\n";
	print "$treeLineWidth setlinewidth\n"; 
	&__print_line($x0, $y1, $x1, $y1, $color );
	&__print_line($x0, $y0, $x0, $y1, $color) unless $node eq $root;
	&__print_label($node, $x1 + 7.5, $y1 - 2.5, $color ) if $node->is_otu() || $runtimeOptions{i};
	if (not $node->is_otu) {
		foreach my $child (@{$node->get_children()} ) {
			&__print_tree($child, $x1, $y1);
		}
		&__print_circle($x1, $y1, $treeNodeRadius, $color );
	}
#	print "\%END TREE\n";
}

sub __print_matrix {
    my ($node, $x0, $y0) = @_;
    my $name = $node->get_name();
	my $x = $node->_get_xcoord();
	my $y = $node->_get_ycoord();
    if ( ! $node->is_otu() ) {
    	foreach my $child (@{$node->get_children()} ) {
    	    &__print_matrix($child,$x,$y);
    	}
    } else {
    	my $color = $nodeColorMap->{$name};
    	printf "\t\t0 %.2f moveto ",$y;
    	print  "(",$name,") show\n";
    	print "\t\t8 2.5 rmoveto\n";
    	printf "\t\t0.8 setgray $referenceLineWidth setlinewidth treemax 8 sub %.2f lineto stroke 0 setgray\n", $y+2.5;
    	printf "\t\ttreemax %.2f moveto ", $y;
    	&__print_sequence($sequences{$name}, $color);
    }
}

sub __print_label {
#	print "\%START LABEL\n";
	my ($node, $x, $y, $color) = @_;
	$color = ( defined($color) ? $color : "0 0 0" );
	print  "\t\t$color setrgbcolor\n";
	
	# Print either left justified or right justified names
	print "\t\tdefaultfont setfont\n";
	if ($runtimeOptions{r} && $node->is_otu()) {
		printf "\t\ttreemax 8 sub ($node->{'name'}) stringwidth pop sub %.2f moveto ", $y;
	} else {
		printf "\t\t%.2f %.2f moveto ", $x, $y;
	}
	print "(", $node->{'name'}, ") show\n";
	if ($node->is_otu()) {
		if ($runtimeOptions{g} || !$runtimeOptions{t}) {
			if ($runtimeOptions{r}) {
				printf "\t\ttreemax 15.5 sub ($node->{'name'}) stringwidth pop sub %.2f moveto\n", $y+2.5;
				printf "\t\t0.8 setgray $referenceLineWidth setlinewidth %.2f 8 add %.2f lineto stroke 0 setgray\n", $x, $y+2.5;
			} else {
				print "\t\t8 2.5 rmoveto\n";
				printf "\t\t0.8 setgray $referenceLineWidth setlinewidth treemax 8 sub %.2f lineto stroke 0 setgray\n", $y+2.5;
			}
			# restore tree line width
			print "\t\t$treeLineWidth setlinewidth \n";
		}
		if (defined $sequences{$node->{'name'}} && (! $runtimeOptions{t})) {
		   printf "\t\tcharacterfont setfont\n";
		   printf "\t\ttreemax %.2f moveto ", $y;
		   &__print_sequence($sequences{$node->{'name'}}, $color)
		}
	}
#	print "\%END LABEL\n";
}

sub __print_sequence() {
    my $sequence = shift;
    my $color = shift; 
    $color = ( defined($color) ? $color : "0 0 0" );
    $sequence = uc(&__seqForDisplay($sequence));
	# Print character table
	print  "\t\t$color setrgbcolor\n";
#	for (my $i=0; $i<((length $sequence)/10) ; $i++) {
#		print "(", substr($sequence, $i*10, 10), ") show\n";
#	}
	print "(", uc $sequence, ") show\n";
}

sub __seqForDisplay() {
	my $string = shift;
    $string =~ tr/01/.+/;
	my @tmp = split (//, $string);
	my $tmp_string = "";
	for (my $i = 0; $i <= $#tmp; $i++) {
		if ($i && (($i % $blockWidth) == 0) ) { $tmp_string .= " " . $tmp[$i] }
		else { $tmp_string .= $tmp[$i]; }
	}
	return $tmp_string;
}

sub __print_circle {
	my ($x, $y, $r, $color ) = @_;
	$color = ( defined($color) ? $color : "0 0 0" );
	print "\t$color setrgbcolor\n";
	printf "\tnewpath %.2f %.2f %.2f %.2f %.2f arc fill stroke\n", $x, $y, $r, 0, 360;
}


sub __print_line {
	my ($x0, $y0, $x1, $y1,$color) = @_;
	$color = ( defined($color) ? $color : "0 0 0" );
	print  "\t",$color," setrgbcolor\n";
	printf "\t%.2f %.2f %.2f %.2f l\n", $x0, $y0, $x1, $y1;
}

sub __print_char_labels {
	my @array = @_;
	warn "WARNING: No labels\n" unless @array;
	print "\n%%Character labels\n";
	print "\tgsave\n";
	printf "\t\tcharacterfont setfont\n";
#	print "\t\t/letterwidth (a) stringwidth pop def\n";
	if ($dataPresent{weights}) {
		printf "\t\ttreemax %.2f translate\n", $treeHeight + 4 * $verticalOtuSpacing;
	} else {
		printf "\t\ttreemax %.2f translate\n", $treeHeight + $verticalOtuSpacing;
	}
	print "/charLabels ";
	foreach my $label (@array) {
		$label =~ s/-/\|/;
		$label = reverse $label;
		print "($label) ";
	}
	print $#array + 1, " packedarray def\n";
	print "charLabels $#array $fontSize $blockWidth letterwidth showCharLabels\n";
	print "\tgrestore\n\n";
}

sub __plot_wts {
	my @array = @_;
	warn "WARNING: No weights\n" unless @array;
	print "\n%%Histogram of character weights\n";
	print "\tgsave\n";
	printf "\t\tcharacterfont setfont\n";
	printf "\t\t%.2f setlinewidth 0 setlinecap\n", $fontSize/3;
	printf "\t\ttreemax (a) stringwidth pop 2 div sub %.2f translate\n", $treeHeight + $verticalOtuSpacing;
	print "\t\tnewpath\n";
	my $blank = 1;
	my $max = $dataPresent{'CORE_column_scores'} ? 9 : __max(@array);
	for (my $i = 0; $i <=$#array; $i++) {
	    my $value = ($array[$i] =~ /^[\d\.]+$/) ? $array[$i] : 0;
		my $height = $value * $histogramHeight/$max;
		if ( $i && ($i % $blockWidth) == 0 ) { # char #11, #21, etc.
			$blank ++;
		}
		printf "\t\t\tletterwidth %d mul 0 moveto ", $i+$blank;
		printf "letterwidth %d mul %.2f lineto\n", $i+$blank, $height;
	}
	print "\t\t0 setgray stroke\n";
	print "\tgrestore\n";
}

sub __print_boot_strap()
{
	print "\tgsave\n";
	printf "\t\tdefaultfont setfont 0.4 0.2 0 setrgbcolor\n"; # brown
	print "\t\t/numwidth (99.99) stringwidth pop def\n";
	foreach my $node (@nodes) {
		next unless $node->get_support_value(); # print only non-zero values and only if defined in the tree
		printf "\t\t%.2f (%.2f ) stringwidth pop sub %.2f moveto ", $node->_get_xcoord(), $node->get_support_value(), $node->_get_ycoord() + 7.2;
		printf "(%.2f) show\n", $node->get_support_value();
	}
	print "\tgrestore\n";
}

sub __end_post_script()
{
	# PRINT SCALE
	if ( (! $runtimeOptions{'m'}) && $dataPresent{trees} && (!($tree->is_cladogram())) ) {
		print "\tgsave\n";
		print "\t\tdefaultfont setfont\n";
		printf "\t\t%.2f %.2f moveto\n", $lowerXbound, $fontSize*.45;
		print "\t\t(0.1 substitution/site) show\n";
		print "\tgrestore\n";
		&__print_line($lowerXbound, $fontSize + 5, $lowerXbound + $amp / 10, $fontSize + 5);
		&__print_line($lowerXbound, $fontSize + 10, $lowerXbound, $fontSize + 5);
		&__print_line($lowerXbound + $amp / 10, $fontSize + 10, $lowerXbound + $amp / 10, $fontSize + 5);
	}

	# PRINT END OF FILE
	if ($runtimeOptions{B}) { # draw a box around what Postscript has determined is the plot
	    print "newpath 0 0 moveto xbound 0 lineto xbound ybound lineto 0 ybound lineto 0 0 lineto closepath\n";
	    print "$boxLineWidth setlinewidth stroke\n";
	}
	# print tree name
	print "\ttitlefont setfont\n";
	print "\ttreemax 2 div (", $treeName, ") stringwidth pop 2 div sub ybound $treeHeight sub 2 div $treeHeight add moveto\n";
	print "\t(", $treeName, ") show\n";

	if ($runtimeOptions{o} || $runtimeOptions{'s'} ) {
		# Draw bounding box
		print "\tnewpath\n";
		print "\t\t-20 ybound 20 add moveto\n";
		print "\t\txbound 20 add ybound 20 add lineto\n";
		print "\t\txbound 20 add -20 lineto\n";
		print "\t\t-20 -20 lineto\n";
		print "\t  closepath\n";
		print "\t\t\.05 inch setlinewidth 0.8 setgray stroke\n\n";
		# End function definition
		print "grestore \n";
		print "\} def\n";
		# Use BigPrint to convert to multiple sheets
		print "\{printposter\} xcol ycol BigPrint\n";
		print "grestore\n";
	} else {
		print "grestore\n";
	}

	print "%%PageTrailer\n";
	print "showpage\n" unless ($runtimeOptions{o} || $runtimeOptions{'s'});
	print "%%Trailer\n";
	print "%%EOF\n";
}

sub __max {
    my @array = @_;
    my $max = 1;
    for my $element (@array) {
        next unless $element =~ /^[\d\.]+$/;
        $max = ($max < $element) ? $element : $max;
    }
    return $max;
}

################# POD Documentation ##################


__END__

=head1 NAME

nexplot.pl - PostScript plot of tree + data table (from NEXUS infile)

=head1 SYNOPSIS

nexplot.pl [options] foo.nex [tree_name] > foo.ps 

=head1 OPTIONS

    -h		Brief help message
    -d		Full documentation
    -v		Verbose mode
    -V		Print version information and quit

    -f		Specify output file (default: STDOUT)

    INFORMATION TO DISPLAY
    -b		Turn on bootstrap values, if any
    -i		Turn on internal node labeling
    -t		Tree only (ignore any characters)
    -I		Specify Characters Block (by "Title") to be used in matrix 
    		(e.g. "dna", "protein", "intron")
    -m		Matrix only (ignore any trees)
    -c		Cladogram mode:
      		(auto if no branch lengths present in tree)
      		normal: all branch lengths equal
      		accelerated: same as normal except OTUs are aligned at end
    -U		Display taxa sets in color (-U "set1 color1 [set2 color2 ...]")
			Color options are red, orange, green, forest, aqua, blue, 
			purple, pink, brown, gray, black 

    PLOT FORMATTING
    -r		Right-justify labels (default: left-justified)
    -C		Columns of characters per block (default = 10)
    -T		Specify tree width (longest branch; default: 10")
    -S		Spacing (vertically) between OTUs (default: .25")
    -R		Ratio of font height to Spacing (default: 0.8; rec: 0.5-1)
    -F		Font to use for labels and titles
    -B		Draw a box indicating postscript\'s bounds of the plot area
    -g		Include gray lines after OTU labels, 
    		even if -t (tree only) option is used

    PAGE SETUP
    -s		Print on multiple pages, but shrink to page height
    -o		Print on multiple pages at actual size
    -W		Specify output page width (default: 8.5")
    -H		Specify output page height (default: 11")
    -a		Change page dimensions to fit plot

=head1 DESCRIPTION

B<This program> will read a NEXUS file and output a PostScript display of trees (one file for each tree
in the Trees Block), as well as any character matrix (e.g. sequences) if present in the file.

=head1 FILES

=over 4

=back
=head1 VERSION

$Id: nexplot.pl,v 1.36 2006/08/24 06:41:57 thladish Exp $

=head1 REQUIRES

Perl 5.004, Getopt::Std, Pod::Usage, NEXUS.pm

=head1 SEE ALSO

perl(1)

=head1 AUTHOR

Weigang Qiu (with Peter Yang, Brendan O'Brien, and Arlin Stoltzfus)

=cut

##################### End ##########################




