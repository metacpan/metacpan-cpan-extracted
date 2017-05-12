#######################################################################
# HistoryBlock.pm
#######################################################################
# Author: Chengzhi Liang, Justin Reese, Thomas Hladish
# $Id: HistoryBlock.pm,v 1.28 2007/09/21 23:09:09 rvos Exp $

#################### START POD DOCUMENTATION ##########################

=head1 NAME

Bio::NEXUS::HistoryBlock - Represents a HISTORY block of a NEXUS file

=head1 SYNOPSIS

$block_object = new Bio::NEXUS::HistoryBlock('history', $block, $verbose);

=head1 DESCRIPTION

This is a class representing a history block in NEXUS file

=head1 FEEDBACK

All feedback (bugs, feature enhancements, etc.) are greatly appreciated. 

=head1 AUTHORS

 Chengzhi Liang (liangc@umbi.umd.edu)
 Justin Reese
 Tom Hladish (tjhladish at yahoo)

=head1 VERSION

$Revision: 1.28 $

=head1 METHODS

=cut

package Bio::NEXUS::HistoryBlock;

use strict;
#use Data::Dumper; # XXX this is not used, might as well not import it!
#use Carp; # XXX this is not used, might as well not import it!
use Bio::NEXUS::Functions;
use Bio::NEXUS::TaxUnitSet;
use Bio::NEXUS::Block;
use Bio::NEXUS::Node;
use Bio::NEXUS::Tree;
use Bio::NEXUS::Util::Logger;
use Bio::NEXUS::Util::Exceptions;
use vars qw(@ISA $VERSION $AUTOLOAD);
use Bio::NEXUS; $VERSION = $Bio::NEXUS::VERSION;

@ISA = qw(Bio::NEXUS::CharactersBlock Bio::NEXUS::TreesBlock);
my $logger = Bio::NEXUS::Util::Logger->new();

=head2 new

 Title   : new
 Usage   : block_object = new Bio::NEXUS::HistoryBlock($block_type, $commands, $verbose);
 Function: Creates a new Bio::NEXUS::HistoryBlock object
 Returns : Bio::NEXUS::HistoryBlock object
 Args    : type (string), the commands/comments to parse (array ref), and a verbose flag (0 or 1; optional)
 Comments: 

=cut

sub new {
    my ( $class, $type, $commands, $verbose ) = @_;
    if ( not $type ) { 
    	( $type = lc $class ) =~ s/Bio::NEXUS::(.+)Block/$1/i; 
    }
    my $self = { 
    	'type' => $type 
    };
    bless $self, $class;
    $self->{'otuset'} = new Bio::NEXUS::TaxUnitSet();
    if ( ( defined $commands ) and @$commands ) {
    	$self->_parse_block( $commands, $verbose )
    }
    return $self;
}

=begin comment

 Name    :_parse_nodelabels
 Usage   : $block->nodelabels($label_text);
 Function: Parse node labels like taxlabels in taxa block
 Returns : Labels as the array reference
 Args    : $labels_text as string

=end comment 

=cut

sub _parse_nodelabels {
    my ( $self, $labeltext ) = @_;
    my @labels = split( /\s+/, $labeltext );
    return \@labels;
}

=head2 equals

 Name    : equals
 Usage   : $block->equals($another);
 Function: compare if two Block objects are equal
 Returns : boolean 
 Args    : a Block object

=cut

sub equals {
    my ( $self, $block ) = @_;
    if ( !Bio::NEXUS::Block::equals( $self, $block ) ) {
        $logger->warn("First equals failed");
        return 0;
    }
    my $historytree1 = $self->get_tree();
    my $historytree2 = $block->get_tree();
    if ( !$historytree1->equals($historytree2) ) {
        $logger->warn("Trees do not appear to be the same, failing equals");
        return 0;
    }

    # check otus

    if ( !$self->get_otuset()->equals( $block->get_otuset() ) ) {
        $logger->warn("otusets do not appear to be the same, failing equals");
        return 0;
    }

    return 1;
}

=head2 rename_otus

 Name    : rename_otus
 Usage   : $nexus->rename_otus(\%translation);
 Function: rename all OTUs 
 Returns : a new nexus object with new OTU names
 Args    : a ref to hash based on OTU name pairs

=cut

sub rename_otus {
    my ( $self, $translation ) = @_;
    for my $parent (@ISA) {
        if ( my $coderef = $self->can( $parent . "::rename_otus" ) ) {
            $self->$coderef($translation);
        }
    }
}

=head2 add_otu_clone

 Title   : add_otu_clone
 Usage   : ...
 Function: ...
 Returns : ...
 Args    : ...

=cut

sub add_otu_clone {
	my ( $self, $original_otu_name, $copy_otu_name ) = @_;
	# print "Warning: Bio::NEXUS::HistoryBlock::add_otu_clone() method not fully implemented\n";
	# add the clone to the taxlabels list
	$self->add_taxlabel($copy_otu_name);

	# add the clone to the list
	my @otus = @{ $self->{'otuset'}->get_otus() };
	for my $otu (@otus) {
		if (defined $otu) {
			if ($otu->get_name() eq $original_otu_name) {
				my $otu_clone = $otu->clone();
				$otu_clone->set_name($copy_otu_name);
				$self->{'otuset'}->add_otu($otu_clone);
			}
		}
	}
	
	# . iterate through all trees:
	for my $tree ( @{ $self->{'blockTrees'} }) {
		# . find the original node
		# if not found, something must be done !
		my $original_node = $tree->find($original_otu_name);
		if (! defined $original_node) {
			$logger->info("TreesBlock::add_otu_clone(): original otu [$original_otu_name] was not found");
		}
		# . clone the node
		my $cloned_node = $original_node->clone();
		# . rename the new node
		$cloned_node->set_name($copy_otu_name);
		
		# find the parent of the original node, add to it a new
		# child that will be parent of both original and
		# clone nodes. Remove the original node from the 
		# list of children of its original parent
		my $original_parent = $original_node->get_parent();
		
		for my $child ( @{ $original_parent->get_children() }) {
			# print "Child name: ", $child->get_name(), "\n";
			if ($child->get_name() eq $original_otu_name) {
				my $new_parent = new Bio::NEXUS::Node();

				$new_parent->set_length($original_node->get_length());
						
				$cloned_node->set_length(0);
				$original_node->set_length(0);
				
				$new_parent->add_child($cloned_node);
				$cloned_node->set_parent_node($new_parent);
				$new_parent->add_child($original_node);
				$original_node->set_parent_node($new_parent);

				$child = $new_parent;
				$new_parent->set_parent_node($original_parent);
				last;
			}
		}
	}
}

=begin comment

 Name    : _write
 Usage   : $block->_write();
 Function: Writes NEXUS block containing history data
 Returns : none
 Args    : file name (string)

=end comment

=cut

sub _write {
    my ( $self, $fh, $verbose ) = @_;
    $fh ||= \*STDOUT;

    Bio::NEXUS::Block::_write( $self, $fh );
    $self->_write_dimensions( $fh, $verbose );
    $self->_write_format( $fh, $verbose );
    $self->_write_labels( $fh, $verbose );
    print $fh "\tNODELABELS ";
    for my $label ( @{ $self->get_otuset->get_otu_names } ) {
        print $fh _nexus_formatted($label) . ' ';
    }
    print $fh ";\n";
    $self->_write_matrix( $fh, $verbose );
    $self->_write_trees( $fh, $verbose );
    print $fh "END;\n";
}

sub AUTOLOAD {
    return if $AUTOLOAD =~ /DESTROY$/;
    my $package_name = __PACKAGE__ . '::';

    # The following methods are deprecated and are temporarily supported
    # via a warning and a redirection
    my %synonym_for = (

#        "${package_name}parse"      => "${package_name}_parse_tree",  # example
    );

    if ( defined $synonym_for{$AUTOLOAD} ) {
        $logger->warn("$AUTOLOAD() is deprecated; use $synonym_for{$AUTOLOAD}() instead");
        goto &{ $synonym_for{$AUTOLOAD} };
    }
    else {
        Bio::NEXUS::Util::Exceptions::UnknownMethod->throw(
        	'error' => "ERROR: Unknown method $AUTOLOAD called"
        );
    }
}

1;
