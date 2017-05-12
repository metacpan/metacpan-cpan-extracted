######################################################
# TreesBlock.pm
######################################################
# Author: Chengzhi Liang, Eugene Melamud, Weigang Qiu, Peter Yang, Thomas Hladish
# $Id: TreesBlock.pm,v 1.63 2007/09/24 04:52:14 rvos Exp $

#################### START POD DOCUMENTATION ##################

=head1 NAME

Bio::NEXUS::TreesBlock - Represents TREES block of a NEXUS file

=head1 SYNOPSIS

 if ( $type =~ /trees/i ) {
     $block_object = new Bio::NEXUS::TreesBlock( $block_type, $block, $verbose );
 }

=head1 DESCRIPTION

If a NEXUS block is a Trees Block, this module parses the block and stores the tree data.

=head1 FEEDBACK

All feedback (bugs, feature enhancements, etc.) are all greatly appreciated. 

=head1 AUTHORS

 Chengzhi Liang (liangc@umbi.umd.edu)
 Eugene Melamud (melamud@carb.nist.gov)
 Weigang Qiu (weigang@genectr.hunter.cuny.edu)
 Peter Yang (pyang@rice.edu)
 Thomas Hladish (tjhladish at yahoo)

=head1 VERSION

$Revision: 1.63 $

=head1 METHODS

=cut

package Bio::NEXUS::TreesBlock;

use strict;
#use Carp; # XXX this is not used, might as well not import it!
#use Data::Dumper; # XXX this is not used, might as well not import it!
use Bio::NEXUS::Functions;
#use Bio::NEXUS::Node; # XXX loaded dynamically
#use Bio::NEXUS::Tree; # XXX loaded dynamically
use Bio::NEXUS::Block;
use Bio::NEXUS::Util::Exceptions 'throw';
use Bio::NEXUS::Util::Logger;
use vars qw(@ISA $VERSION $AUTOLOAD);
use Bio::NEXUS; $VERSION = $Bio::NEXUS::VERSION;

@ISA = qw(Bio::NEXUS::Block);
my $logger = Bio::NEXUS::Util::Logger->new;

my %factories = (
	'treetype' => __PACKAGE__->_load_module('Bio::NEXUS::Tree'),
	'nodetype' => __PACKAGE__->_load_module('Bio::NEXUS::Node'),
);

sub import {
	my $class = shift;
	my %args;
	if ( @_ ) {
		%args = @_;
	}	
	for ( qw(treetype nodetype) ) {
		$factories{$_} = $class->_load_module( $args{$_} ) if $args{$_};
	}
}

=head2 new

 Title   : new
 Usage   : block_object = new Bio::NEXUS::TreesBlock($block_type, $commands, $verbose );
 Function: Creates a new Bio::NEXUS::TreesBlock object and automatically reads the file
 Returns : Bio::NEXUS::TreesBlock object
 Args    : type (string), the commands/comments to parse (array ref), and a verbose flag (0 or 1; optional)

=cut

sub new {
    my ( $class, $type, $commands, $verbose ) = @_;
    $logger->info("constructor called for $class");
    ( $type ||= lc $class ) =~ s/Bio::NEXUS::(.+)Block/$1/i;
    my $self = { 
    	'type'     => $type,
    	'treetype' => $factories{'treetype'},
    	'nodetype' => $factories{'nodetype'},
    };
    bless $self, $class;
    if ( defined $commands and @{ $commands } ) {
    	$self->_parse_block( $commands, $verbose );
    }
    return $self;
}

=begin comment

 Title   : _parse_translate
 Usage   : $self->_parse_translate($buffer); 
 Function: Process the 'translate' section of the Trees Block
 Returns : the translation hash ref
 Args    : the buffer to parse (string)

=end comment 

=cut

sub _parse_translate {
    my ( $self, $buffer ) = @_;
    $buffer =~ s/,//g;
    my $translate = { @{ _parse_nexus_words($buffer) } };
    $self->{'translation'} = $translate;
    return $translate;
}

=begin comment

 Title   : _parse_tree
 Usage   : $self->_parse_tree($buffer); 
 Function: Process the 'tree' section of the Trees Block
 Returns : none
 Args    : buffer (string)
 Method  : Separates the buffer by the equal sign (example:
           tree tree_name = tree_string)
           Creates a new Bio::NEXUS::Tree object, sets the name as the name
           and the tree as the tree. (duh)
           Retrieves list of nodes from the Bio::NEXUS::Tree object. For each node,
           checks to see if a translation is defined. If it is, then it
           performs the appropriate translation. If not, then it just leaves
           the name as it is. Then it adds itself to the list blockTrees.

=end comment 

=cut

sub _parse_tree {
    my ( $self, $buffer, $verbose ) = @_;

    $logger->info("Entering tree");;
    my $tree       = $self->treetype->new();
    my @tree_words = @{ _parse_nexus_words($buffer) };

    # If there's an asterisk, set the 'default' attribute, then get rid of the asterisk
    if ( $tree_words[0] eq '*' ) {
        shift @tree_words;
        $tree->set_as_default();
    }

    # separate out the name of the tree and the '=' symbol
    my ( $name, $equals_symb ) = splice @tree_words, 0, 2;
    $tree->set_name($name);

    # mark the tree as unrooted if it's prepended with [&U]
    if ( lc $tree_words[0] eq lc '[&U]' ) {
        $logger->info("setting tree as unrooted");
        $tree->set_as_unrooted();
        shift @tree_words;
    }

    # if it's prepended with the rooted flag, nothing needs to change
    elsif ( lc $tree_words[0] eq lc '[&R]' ) {
        $logger->info("tree is rooted");
        shift @tree_words;
    }

	$logger->info("going to parse newick string");
    $tree->_parse_newick( \@tree_words );
    $logger->info($tree->as_string);

    my $nodes = $tree->get_nodes();
    for my $node (@$nodes) {
        if ( $node->is_otu() ) {    #check for translation            
            $name = $node->get_name();
            $logger->info("node is terminal, setting translation '$name'");
            $node->set_name( $self->translate($name) );
        }
    }

    $self->add_tree($tree);
    return $tree;
}

=head2 treetype

 Title   : treetype
 Usage   : $block->treetype('Bio::NEXUS::Tree');
 Function: sets a tree type class to instantiate on parse
 Returns : none
 Args    : a tree class

=cut

sub treetype {
	my $self = shift;
	if ( @_ ) {
		$self->{'treetype'} = $self->_load_module(shift);
	}
	return $self->{'treetype'} || $self->_load_module('Bio::NEXUS::Tree');
}

=head2 nodetype

 Title   : nodetype
 Usage   : $block->nodetype('Bio::NEXUS::Node');
 Function: sets a node type class to instantiate on parse
 Returns : none
 Args    : a node class

=cut

sub nodetype {
	my $self = shift;
	if ( @_ ) {
		$self->{'nodetype'} = $self->_load_module(shift);
	}
	return $self->{'nodetype'} || $self->_load_module('Bio::NEXUS::Node');
}

=head2 clone

 Title   : clone
 Usage   : my $newblock = $block->clone();
 Function: clone a block object (shallow)
 Returns : Block object
 Args    : none

=cut

sub clone {
    my ($self) = @_;
    my $class = ref($self);
    my $TreesBlock = bless( { %{$self} }, $class );

    # clone trees
    my @trees = ();
    for my $tree ( @{ $self->get_trees() } ) {
        push @trees, $tree;
    }
    $TreesBlock->set_trees( \@trees );
    return $TreesBlock;
}

=head2 set_trees

 Title   : set_trees
 Usage   : $block->set_trees($trees);
 Function: Sets the list of trees (Bio::NEXUS::Tree objects) 
 Returns : none
 Args    : ref to array of Bio::NEXUS::Tree objects

=cut

sub set_trees {
    my ( $self, $trees ) = @_;
    $self->{'blockTrees'} = $trees;
}

=head2 add_tree

 Title   : add_tree
 Usage   : $block->add_tree($tree);
 Function: Add trees (Bio::NEXUS::Tree object) 
 Returns : none
 Args    : a Bio::NEXUS::Tree object

=cut

sub add_tree {
    my ( $self, $tree ) = @_;
    push @{ $self->{'blockTrees'} }, $tree;
}

=head2 add_tree_from_newick

 Title   : add_tree_from_newick
 Usage   : $block->add_tree_from_newick($newick_tree, $tree_name);
 Function: Add a tree (Bio::NEXUS::Tree object)
 Returns : none
 Args    : a tree string in newick format and a name for the tree (scalars)

=cut

sub add_tree_from_newick {
    my ( $self, $tree, $tree_name ) = @_;
    $tree = "$tree_name = $tree";
    $self->_parse_tree($tree);
    return;
}

=head2 get_trees

 Title   : get_trees
 Usage   : $block->get_trees();
 Function: Gets the list of trees (Bio::NEXUS::Tree objects) and returns it
 Returns : ref to array of Bio::NEXUS::Tree objects
 Args    : none

=cut

sub get_trees {
    my $self = shift;
    return $self->{'blockTrees'} || [];
}

=head2 get_tree

 Title   : get_tree
 Usage   : $block->get_tree($treename);
 Function: Gets the first tree (Bio::NEXUS::Tree object) that matches the name given or the first tree if $treename is not specified. If no tree matches, returns undef.
 Returns : a Bio::NEXUS::Tree object
 Args    : tree name or none

=cut

sub get_tree {
    my ( $self, $treename ) = @_;
    return $self->get_trees()->[0] unless $treename;
    for my $t ( @{ $self->get_trees() } ) {
        return $t if ( $t->get_name() =~ /^$treename/ );
    }
    return undef;
}

=head2 set_translate

 Title   : set_translate
 Usage   : $block->set_translate($translate);
 Function: Sets the hash of translates for nodes names 
 Returns : none
 Args    : hash of translates

=cut

sub set_translate {
    my ( $self, $translate ) = @_;
    $self->{'translation'} = $translate;
}

=head2 translate

 Title   : translate
 Usage   : $self->translate($num);
 Function: Translates a number with its associated name.
 Returns : integer or string
 Args    : integer
 Method  : Returns the name associated with that number's translated name.
           If it can't find an association, returns the number.

=cut

sub translate {
    my ( $self, $num ) = @_;
    if ( defined $self->{'translation'}{$num} ) {
        return $self->{'translation'}{$num};
    }
    else {
        return $num;
    }
}

=head2 reroot_tree

 Title   : reroot_tree
 Usage   : $block->reroot_tree($outgroup,$root_position, $treename);
 Function: Reroot a tree using an OTU as new outgroup.
 Returns : none
 Args    : outgroup name, the distance before the root position and tree name

=cut

sub reroot_tree {
    my ( $self, $outgroup, $root_position, $treename ) = @_;
    if ( not defined $treename and not defined $outgroup ) {
    	throw 'BadArgs' => 'Need to specify a tree name and outgroup name for rerooting';
    }
    my $tree = $self->get_tree($treename);
    my @rerooted_trees;
    foreach my $tree ( @{ $self->get_trees() } ) {
        if ( $tree->get_name ne $treename ) {
            push @rerooted_trees, $tree;
        }
        else {
            push @rerooted_trees, $tree->reroot( $outgroup, $root_position );
        }
    }
    $self->set_trees( \@rerooted_trees );
    return $self;
}

=head2 reroot_all_trees

 Title   : reroot_all_trees
 Usage   : $block->reroot_all_trees($outgroup, $root_position);
 Function: Reroot all the trees in the treesblock tree. use an OTU as new outgroup
 Returns : none
 Args    : outgroup name and root position 

=cut

sub reroot_all_trees {
    my ( $self, $outgroup, $root_position ) = @_;
    return if not defined $self->get_tree;
    my @rerooted_trees;
    foreach my $tree ( @{ $self->get_trees() } ) {
        push @rerooted_trees, $tree->reroot( $outgroup, $root_position );
    }
    $self->set_trees( \@rerooted_trees );
    return $self;
}

=head2 rename_otus

 Title   : rename_otus
 Usage   : $block->rename_otus(\%translation);
 Function: Renames nodes based on a translation hash
 Returns : none
 Args    : hash containing translation (e.g., { old_name => new_name} )
 Comments: nodes not included in translation hash are unaffected

=cut

sub rename_otus {
    my ( $self, $translate ) = @_;
    return if not defined $self->get_tree;
    for my $tree ( @{ $self->get_trees() } ) {
        my $nodes = $tree->get_nodes();
        for my $node (@$nodes) {
            my $name           = $node->get_name();
            my $translatedname = $translate->{$name};
            if ($translatedname) {
                $node->set_name($translatedname);
            }
        }
    }
    my $newnames = $self->get_tree()->get_node_names();
    $self->set_taxlabels($newnames);
}

=head2 select_otus

 Name    : select_otus
 Usage   : $nexus->select_otus(\@otunames);
 Function: select a subset of OTUs
 Returns : a new nexus object 
 Args    : a ref to array of OTU names

=cut

sub select_otus {
    my ( $self, $otunames ) = @_;
    for my $tree ( @{ $self->get_trees() } ) {
        $tree->prune("@{$otunames}");
    }
    $self->set_taxlabels($otunames);
    return $self;
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
	# print "Warning: Bio::NEXUS::TreesBlock::add_otu_clone() method not fully implemented\n";
	
	# . iterate through all trees:
	foreach my $tree ( @{ $self->{'blockTrees'} }) {
		# . find the original node
		# if not found, something must be done !
		my $original_node = $tree->find($original_otu_name);
		print "TreesBlock::add_otu_clone(): original otu [$original_otu_name] was not found.\n" if (! defined $original_node);
		# . clone the node
		my $cloned_node = $original_node->clone();
		# . rename the new node
		$cloned_node->set_name($copy_otu_name);
		
		# find the parent of the original node, add to it a new
		# child that will be parent of both original and
		# clone nodes. Remove the original node from the 
		# list of children of its original parent
		my $original_parent = $original_node->get_parent();
		
		foreach my $child ( @{ $original_parent->get_children() }) {
			# print "Child name: ", $child->get_name(), "\n";
			if ($child->get_name() eq $original_otu_name) {
				my $new_parent = $self->nodetype->new();

				$new_parent->set_length($original_node->get_length());
						
				$cloned_node->set_length(0);
				$original_node->set_length(0);
				
				$new_parent->add_child($cloned_node);
				$cloned_node->set_parent_node($new_parent);
				$new_parent->add_child($original_node);
				$original_node->set_parent_node($new_parent);

				$new_parent->set_parent_node($original_parent);
				$child = $new_parent;
				last;
			}
		}
	}
	
	# todo:
	# add the clone to {'translation'} if the original is also there
}

=head2 select_tree

 Name    : select_tree
 Usage   : $nexus->select_tree($treename);
 Function: select a tree
 Returns : a new nexus object 
 Args    : a tree name

=cut

sub select_tree {
    my ( $self, $treename ) = @_;
    my @oldtrees = @{ $self->get_trees() };
    $self->set_trees();
    for my $tree (@oldtrees) {
        if ( $tree->get_name() eq $treename ) {
            $self->add_tree($tree);
            last;
        }
    }
    return $self;
}

=head2 select_subtree

 Name    : select_subtree
 Usage   : $nexus->select_subtree($inodename);
 Function: select a subtree
 Returns : a new nexus object 
 Args    : an internal node name for subtree to be selected

=cut

sub select_subtree {
    my ( $self, $nodename, $treename ) = @_;
    if ( not $nodename ) {
    	throw 'BadArgs' => 'Need to specify an internal node name for subtree';
    }
    my $tree = $self->get_tree($treename);
    if ( not $tree ) {
    	throw 'BadArgs' => "Tree $treename not found.";
    }
    $tree = $tree->select_subtree($nodename);
    $self->set_trees();
    $self->add_tree($tree);
    $self->set_taxlabels( $tree->get_node_names() );

    return $self;
}

=head2 exclude_subtree

 Name    : exclude_subtree
 Usage   : $nexus->exclude_subtree($inodename);
 Function: remove a subtree
 Returns : a new nexus object 
 Args    : an internal node for subtree to be removed

=cut

sub exclude_subtree {
    my ( $self, $nodename, $treename ) = @_;
    if ( not $nodename ) {
    	throw 'BadArgs' => 'Need to specify an internal node name for subtree';
    }

    my $tree = $self->get_tree($treename);
    if ( not $tree ) {
    	throw 'BadArgs' => "Tree $treename not found.";
    }

    $tree = $tree->exclude_subtree($nodename);
    $self->set_trees();
    $self->add_tree($tree);
    $self->set_taxlabels( $tree->get_node_names() );

    return $self;
}

=head2 equals

 Name    : equals
 Usage   : $nexus->equals($another);
 Function: compare if two NEXUS objects are equal
 Returns : boolean 
 Args    : a NEXUS object

=cut

sub equals {
    my ( $self, $block ) = @_;
    if ( !Bio::NEXUS::Block::equals( $self, $block ) ) { return 0; }

    #    if ($self->get_type() ne $block->get_type()) {return 0;}
    my @trees1 = @{ $self->get_trees() };
    my @trees2 = @{ $block->get_trees() };
    if ( @trees1 != @trees2 ) { return 0; }
    @trees1 = sort { $a->get_name() cmp $b->get_name() } @trees1;
    @trees2 = sort { $a->get_name() cmp $b->get_name() } @trees2;
    for ( my $i = 0; $i < @trees1; $i++ ) {
        if ( !$trees1[$i]->equals( $trees2[$i] ) ) { return 0; }
    }
    return 1;
}

# method under testing
sub _equals_test {
    my ( $self, $block ) = @_;
    if ( !Bio::NEXUS::Block::equals( $self, $block ) ) { return 0; }

    #    if ($self->get_type() ne $block->get_type()) {return 0;}
    my @trees1 = @{ $self->get_trees() };
    my @trees2 = @{ $block->get_trees() };
    if ( @trees1 != @trees2 ) { return 0; }
    @trees1 = sort { $a->get_name() cmp $b->get_name() } @trees1;
    @trees2 = sort { $a->get_name() cmp $b->get_name() } @trees2;
    for ( my $i = 0; $i < @trees1; $i++ ) {
        if ( !$trees1[$i]->_equals_test( $trees2[$i] ) ) { return 0; }
    }
    return 1;
}

=begin comment

 Name    : _write
 Usage   : $block->_write($file_handle,verbose);
 Function: Writes Trees Block object into the filehandle or STDOUT
 Returns : none
 Args    : File handle for writing the trees and verbose option( 0 or 1). 
           If file handle is empty then the output it written on STDOUT.

=end comment 

=cut

sub _write {
    my ( $self, $fh, $verbose ) = @_;
    $fh ||= \*STDOUT;

    Bio::NEXUS::Block::_write( $self, $fh );
    $self->_write_trees( $fh, $verbose );
    print $fh "END;\n";
}

=begin comment

 Name    : _write_trees
 Usage   : $block->_write_trees($file_handle,verbose);
 Function: Writes trees in the object into the file handle or STDOUT as string.(used in $self->_write)
 Returns : none
 Args    : File handle for writing the trees and verbose option( 0 or 1). 
           If file handle is empty then the output it written on STDOUT.

=end comment 

=cut

sub _write_trees {
    my ( $self, $fh, $verbose ) = @_;
    $fh ||= \*STDOUT;

    for my $tree ( @{ $self->get_trees() } ) {
        print $fh "\tTREE ";
        if ( $tree->is_default() ) {
            print $fh "* ";
        }
        # tree name has to be protected if it contains quotations
        print $fh _nexus_formatted($tree->get_name()), " = ";
        if ( !$tree->is_rooted() ) {
            print $fh "[&U] ";
        }
        print $fh $tree->as_string(), "\n";
    }

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
        throw 'UnknownMethod' => "ERROR: Unknown method $AUTOLOAD called";
    }
    return;
}

1;
