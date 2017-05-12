#!/usr/bin/perl -w
#######################################################################
# p3treeplot.pl
#######################################################################
# Author: Tom Hladish
my $RCSId = '$Id: p3treeplot.pl,v 1.6 2006/08/24 22:04:55 arlin Exp $';
my $shortname = join (" v", $RCSId =~ m/(\w+.?\w+,)v (\d+\.\d+)/);
#################### START POD DOCUMENTATION ##########################

=head1 NAME

p3treeplot.pl - uses R to create PPP trees from a NEXUS file

=head1 SYNOPSIS

p3treeplot.pl NEXUSFileName [charlabel1 charlabel2 ... ]

=head1 DESCRIPTION

This is a command-line script that draws all (default) or some (if 
charlabels are listed) of the posterior probability of presence trees
represented in the history block in a NEXUS file.

=head1 FEEDBACK

All feedback (bugs, feature enhancements, etc.) are greatly appreciated. 

=head1 AUTHOR

Tom Hladish

=head1 VERSION

$Revision: 1.6 $

=head1 SUBROUTINES

=cut

use strict;
use Bio::NEXUS;
use Bio::NEXUS::HistoryBlock;
use Data::Dumper;
use POSIX;
$Data::Dumper::Maxdepth=3;

my $pagesetup = {
					"h" => 11, 								## paper height
					"w" => 8.5, 							## paper width
					"margin" => 0.25, 						## paper margins
					"max_plots_with_axes_labels" => 12, 	## max number of plots to still use axes labels
					"axes_labels" => "xlab=\"Distance from Root\", ylab = \"Probability of Presence\",",  ## default labels
					"cex_val" => "",  						## cex is set in &optimal_layout
					"pages" => 1,							## number of pages to fit plots onto
					"version" => "$shortname",				## executable name and version
				 };

my ($inputfile, $outputfile, $intron_subset) = &parse_ARGV (@ARGV);  ## Read in command-line arguments
my ($charlabels, $otus, $root) = &read_nexus ($inputfile);
my $presencedata = &read_pres_prob ($otus, $charlabels);
my ($nexmatrix, $maxlength) = &matrix_builder ($root);
my $sortedintrons = &intron_sorter (keys %$presencedata);

if (scalar (@$intron_subset) > 0) {$sortedintrons = $intron_subset};
$nexmatrix = &include_pres_probs ($nexmatrix, $sortedintrons);

my $plotcount = scalar (@$sortedintrons);
(my $layout, $pagesetup) = &optimal_layout ($plotcount, $pagesetup);
my @Rcommands = &write_R ($nexmatrix, $presencedata, $maxlength, $layout, $pagesetup);

open (ROUT, "| R --no-save"); ## Named pipe to R ##
print ROUT "@Rcommands";
close (ROUT);

#system("open $outputfile"); ## Opens just-created pdf file in default pdf viewer ##

=head2 parse_ARGV

 Title   : parse_ARGV
 Usage   : (input_filename, output_filename, charlabel_subset) = &parse_ARGV (@ARGV);
 Function: assigns certain variables based on command-line arguments
 Returns : (1) NEXUS source filename, (2) output filename to be created, 
 	   (3) reference to array of subset of introns to be plotted
 Args    : array of command-line arguments
 Comments: 

=cut

sub parse_ARGV() {
	my $inputfile = shift;
	my $intron_subset = [@_];
	unless (defined($inputfile)) {die ("Proper use is 'p3treeplot.pl nexusfilename.nex [charlabel1 charlabel2 ...]'; exclude 'charlabels' to print all introns\n");}
	my ($outputfile) = $inputfile =~ m/^(.+?)(\.nex)?$/;
	$outputfile = join (".", $outputfile, @$intron_subset, "p3", "pdf");
	return ($inputfile, $outputfile, $intron_subset);
}

=head2 read_nexus

 Title   : read_nexus
 Usage   : (character_labels, otu_objects, root_object) = &read_nexus ($NEXUSfile)
 Function: reads the relevant information from a NEXUS History Block
 Returns : references to (1) array of character labels, (2) array of otu objects, 
 	   (3) root object
 Args    : name of source NEXUS file with History Block, with path if necessary
 Comments: 

=cut

sub read_nexus() {
	my $file = shift;
	-e "$file" || die"NEXUS file: <$file> does not exist in this directory.\n";
	my $nexus = Bio::NEXUS->new($file);
	my $historyBlock = $nexus->get_block("history");
	my $otuSet = $historyBlock->get_otuset();
	my $charlabels = $otuSet->get_charlabels();
	my $otus = $otuSet->get_otus();
	my $tree = $historyBlock->get_tree();
	my $root = $tree->get_rootnode();
	return ($charlabels, $otus, $root);
}

=head2 read_pres_prob

 Title   : read_pres_prob
 Usage   : probability_of_presence_data_structure = &read_pres_prob (otu_objects, 
 	   character_labels);
 Function: reads the relevant information from a NEXUS History Block
 Returns : reference to hash (keys = intron names) of hashes (keys = node names) of 
 	   probability data for all nodes
 Args    : references to (1) otu objects and (2) character labels (i.e. intron names)
 Comments: 

=cut

sub read_pres_prob () {
	my ($otus, $charlabels) = @_;
	my $presencedata;
	my @nodenames;
	for my $otu ( @$otus ) {
	    my $nodename = $otu->get_name();
    	push (@nodenames, $nodename);
	    my $seqs = $otu->get_seq();
    	my $i = 0;
        for my $seq ( @$seqs ) {
           	my $prob;
           	if (ref $seq) {$prob = $seq->[1]} else {$prob = $seq};
           	$$presencedata{@$charlabels[$i]}{$nodename} = $prob;
           	$i++;
       	}
	}
	return $presencedata;
}

=head2 matrix_builder

 Title   : matrix_builder
 Usage   : (nexus_data_matrix, max_branch_length) = &matrix_builder (root_object);
 Function: constructs preliminary nexmatrix, determines maximum branch length
 Returns : reference to array (each element corresponds to one line drawn in R) of arrays 
 	   (of structure [parentnode, childnode, branchlength]); also returns scalar of 
 	   maximum distance from root to leaf
 Args    : reference to root object
 Comments: Should be possible to condense the top-level loops into just one 'for' loop (TH)

=cut

sub matrix_builder () {
	my $root = shift;
	my $j = 0;
	my $i=1;
	my $nexmatrix;
	my @generations;
	$generations[0] = $root->children();
	my $rootname = $root->name();
	my $maxlength = 0;
	for my $child (@{$generations[0]}) {
	    my $childlength = $root->distance($child);
	    $$nexmatrix[$j] = [$rootname,$child->name(),$childlength];
	    if ($maxlength < $childlength) {$maxlength = $childlength}
	    $j++;
	}
	for my $generation (@generations) {
	    for my $parent (@$generation) {
	        $generations[$i] = $parent->children();
	        my $parentname = $parent->name();
	        for my $child (@{$generations[$i]}){
	            my $childlength = $root->distance($child);
	            $$nexmatrix[$j] = [$parentname,$child->name(),$childlength];
			    if ($maxlength < $childlength) {$maxlength = $childlength}
	            $j++;
	        }
	        $i++;
	    }
	}
	return ($nexmatrix,$maxlength);
}

=head2 intron_sorter

 Title   : intron_sorter
 Usage   : sorted_introns = &intron_sorter (intron_names_list);
 Function: sorts intron names numerically rather than as strings (as with the 'sort' 
 	   function)
 Returns : reference to array of sorted names
 Args    : list or array of intron names
 Comments: Works for introns that match pattern /\d+-\d/.  May not work for other names. (TH)

=cut

sub intron_sorter () {
	my @introns = @_;
	for (my $i = 0; $i < scalar (@introns); $i++) {$introns[$i] =~ s/-/./}
	@introns = sort numerically @introns;
	for (my $i = 0; $i < scalar (@introns); $i++) {$introns[$i] =~ s/\./-/}
	return \@introns;
}

=head2 numerically

 Title   : numerically
 Usage   : array_of_numbers = sort numerically array_of_numbers;
 Function: tells 'sort' function how to sort numbers
 Returns : 0 if $a and $b are equal, 1 if $a is greater, -1 if $b is greater
 Args    : None; or rather, 'sort' idiomatically passes special variables $a and $b
 Comments: 

=cut

sub numerically () {
	$a <=> $b;
}

=head2 include_pres_probs

 Title   : include_pres_probs
 Usage   : nexus_data_matrix = &include_pres_probs (nexus_data_matrix, sorted_introns);
 Function: adds probability of presence data to nexus_data_matrix; also unshifts column names 
 	   into first row of matrix
 Returns : reference to array of arrays (i.e., the updated nexus_data_matrix)
 Args    : reference to array of arrays (preliminary nexus_data_matrix), reference to array 
 	   of sorted intron names
 Comments: Columns (corresponding to each intron) with probability data for at each node are 
 	   added to the matrix in the order provided in sorted_introns. 

=cut

sub include_pres_probs () {
	my ($nexmatrix, $sortedintrons) = @_;
	unshift (@$nexmatrix, ["Parent","Child","Distance"]);
	for my $intron (@$sortedintrons) {
		unless (defined($$presencedata{$intron})) {die("charlabel: $intron is not defined in this NEXUS history block!\n")}
	    push(@{${$nexmatrix}[0]},$intron);
	    for (my $k = 1; $k < scalar(@$nexmatrix); $k++) {
			push(@{$$nexmatrix[$k]},"$$presencedata{$intron}{${$$nexmatrix[$k]}[1]}");
	    }
	}
	return $nexmatrix;
}

=head2 optimal_layout

 Title   : optimal_layout
 Usage   : (layout, $pagesetup) = &optimal_layout (number_of_plots, $pagesetup);
 Function: determines best way to place N plots on one page; also removes axes labels and 
 	   shrinks fonts if many plots are on one page
 Returns : reference to [rows_per_page, cols_per_page] array, reference to updated global 
 	   %pagesetup
 Args    : number of introns to plot, reference to pagesetup hash
 Comments: fits number of introns to number of pages specified by $$pagesetup{'pages'})

=cut

sub optimal_layout () {
	my ($plotcount, $pagesetup) = @_;
	$plotcount = POSIX::ceil($plotcount/$$pagesetup{'pages'});
	if ($plotcount > $$pagesetup{"max_plots_with_axes_labels"}) {$$pagesetup{"axes_labels"} = "xlab=\"\", ylab = \"\","}
	if ($plotcount > 6) {$$pagesetup{"cex_val"} = " cex = 2/$plotcount**0.5,"}
	my ($row_fp, $col_fp) = (($plotcount*$$pagesetup{h}/$$pagesetup{w})**0.5,($plotcount*$$pagesetup{w}/$$pagesetup{h})**0.5);
	my ($row_fl, $row_cl, $col_fl, $col_cl) = (POSIX::floor($row_fp),POSIX::ceil($row_fp),POSIX::floor($col_fp),POSIX::ceil($col_fp));
	my ($row_ct, $col_ct);
	if ($row_fl*$col_fl >= $plotcount) {
		($row_ct, $col_ct) = ($row_fl, $col_fl);
	} elsif ($row_cl*$col_fl >= $plotcount) {
		if ($row_fl*$col_cl >= $plotcount) {
			if (($row_cl*$col_fl-$plotcount) < ($row_fl*$col_cl-$plotcount)) {
				($row_ct, $col_ct) = ($row_cl, $col_fl);
			} elsif (($row_cl*$col_fl-$plotcount) > ($row_fl*$col_cl-$plotcount)) {
				($row_ct, $col_ct) = ($row_fl, $col_cl);
			} else {
				($row_ct, $col_ct) = ($row_cl, $col_fl) if $$pagesetup{h}>$$pagesetup{w};
				($row_ct, $col_ct) = ($row_fl, $col_cl) if $$pagesetup{h}<$$pagesetup{w};
			}
		} else {
			($row_ct, $col_ct) = ($row_cl, $col_fl);
		}
	} elsif ($row_fl*$col_cl >= $plotcount) {
		($row_ct, $col_ct) = ($row_fl, $col_cl);
	} else {
		($row_ct, $col_ct) = ($row_cl, $col_cl);
	}
	return ([$row_ct, $col_ct], $pagesetup);
}

=head2 write_R

 Title   : write_R
 Usage   : R_commands = &write_R (nexus_data_matrix, probability_of_presence_data_structure, 
 	   max_branch_length, layout, page_setup_data);
 Function: translates various data structures into R language commands
 Returns : array of R commands
 Args    : references to nexmatrix, presencedata, layout, and pagesetup data structures; 
 	   maximum distance from root to leaf
 Comments: this subroutine determines all R settings not explicitly laid out in $pagesetup

=cut

sub write_R () {
	my ($nexmatrix, $presencedata, $maxlength, $layout, $pagesetup) = @_;
	my %nodecoords;
	my @Rcommands;
	my ($col1, $col2, $col3, @introns) = @{$$nexmatrix[0]};
	my $papersize = join ("", "width=", $$pagesetup{'w'}-2*$$pagesetup{'margin'},", height=",$$pagesetup{'h'}-2*$$pagesetup{'margin'},",");
	push (@Rcommands, "pdf(\"$outputfile\", $papersize)\n","par(mfrow=c($$layout[0],$$layout[1]),omi=c(.1,.1,.6,.1),mgp=c(1.5,.5,0),mar=c(3,3,2,0.1),$$pagesetup{'cex_val'} pty=\"m\")\n");
	for (my $i = 0; $i < scalar(@introns); $i++) {
		$nodecoords{'root'} = [0,$$presencedata{$introns[$i]}{'root'}];
		push (@Rcommands, "plot(0,0, type=\"n\", main = \"$introns[$i]\", $$pagesetup{'axes_labels'} xlim =c(0,1), ylim=c(0,1))\n");
	    for (my $ii = 1; $ii < scalar(@$nexmatrix); $ii++) {
	        my ($parent, $child, $dist, @probs) = @{$$nexmatrix[$ii]};
	        $nodecoords{$child} = [$dist/$maxlength, $probs[$i]];
			push (@Rcommands, "lines(c($nodecoords{$parent}[0],$nodecoords{$child}[0]),c($nodecoords{$parent}[1],$nodecoords{$child}[1]))\n");
	    }
	}
	push (@Rcommands, "mtext(\"$outputfile     ($$pagesetup{'version'})\", 3, outer=TRUE, cex=1, line=1)\n");#, "mtext(\"$version\", 3, outer=TRUE, cex=0.8, line=.6)\n");
	push (@Rcommands, "dev.off()\n","q()\n");
	return @Rcommands;
}


exit;