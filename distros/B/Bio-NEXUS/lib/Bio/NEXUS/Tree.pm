######################################################
# Tree.pm
######################################################
# Author:  Weigang Qiu, Chengzhi Liang, Peter Yang, Thomas Hladish
# $Id: Tree.pm,v 1.62 2007/09/21 23:09:09 rvos Exp $

#################### START POD DOCUMENTATION ##################

=head1 NAME

Bio::NEXUS::Tree - Provides functions for manipulating trees

=head1 SYNOPSIS

new Bio::NEXUS::Tree;

=head1 DESCRIPTION

Provides a few useful functions for trees.

=head1 FEEDBACK

All feedback (bugs, feature enhancements, etc.) are all greatly appreciated. There are no mailing lists at this time for the Bio::NEXUS::Tree module, so send all relevant contributions to Dr. Weigang Qiu (weigang@genectr.hunter.cuny.edu).

=head1 AUTHORS

 Eugene Melamud (melamud@carb.nist.gov)
 Thomas Hladish (tjhladish at yahoo)
 Weigang Qiu (weigang@genectr.hunter.cuny.edu)
 Chengzhi Liang (liangc@umbi.umd.edu)
 Peter Yang (pyang@rice.edu)

=head1 METHODS

=cut

package Bio::NEXUS::Tree;

use strict;
use Bio::NEXUS::Functions;
use Bio::NEXUS::Node;
#use Data::Dumper; # XXX this is not used, might as well not import it!
#use Carp;
use Bio::NEXUS::Util::Exceptions;
use Bio::NEXUS::Util::Logger;
use vars qw($VERSION $AUTOLOAD);
use Bio::NEXUS; $VERSION = $Bio::NEXUS::VERSION;

my $logger = Bio::NEXUS::Util::Logger->new();

=head2 new

 Title   : new
 Usage   : $tree = new Bio::NEXUS::Tree();
 Function: Creates a new Bio::NEXUS::Tree object
 Returns : Bio::NEXUS::Tree object
 Args    : none

=cut

sub new {
    my ($class) = @_;
    my $root_node = new Bio::NEXUS::Node;
    my $self = { name => undef, root_node => $root_node };
    bless $self, $class;
    return $self;
}

=head2 clone

 Name    : clone
 Usage   : my $new_tree = $self->clone();
 Function: clone a Bio::NEXUS::Tree (self) object. All the nodes are also cloned. 
 Returns : new Bio::NEXUS::Tree object
 Args    : none

=cut

sub clone {
    my ($self) = @_;
    my $class = ref($self);
    my $newtree = bless( { %{$self} }, $class );

    # clone nodes
    $newtree->set_rootnode( $self->get_rootnode()->clone() );
    return $newtree;
}

=head2 set_rootnode

 Title   : set_rootnode
 Usage   : $tree->set_rootnode($newnode);
 Function: Sets the root node to a new node
 Returns : none
 Args    : root node (Bio::NEXUS::Node object)

=cut

sub set_rootnode {
    my $self    = shift;
    my $newroot = shift;
    $self->{root_node} = $newroot;
}

=head2 get_rootnode

 Title   : get_rootnode
 Usage   : $node = $tree->get_rootnode();
 Function: Returns the tree root node 
 Returns : root node (Bio::NEXUS::Node object)
 Args    : none

=cut

sub get_rootnode {
    my $self = shift;
    if ( defined $self->{'root_node'} ) {
        return $self->{'root_node'};
    }
}

=begin comment

 Title   : _parse_newick
 Usage   : $tree->_parse_newick($tree_string);
 Function: Creates a tree out of the existing tree string
 Returns : none
 Args    : array ref of NEXUS 'words' (a newick tree string that has been parsed by &_parse_nexus_words)

=end comment 

=cut

sub _parse_newick {
    my ( $self, $tree_words ) = @_;

    my $root = $self->get_rootnode();
    $root->_parse_newick($tree_words);
    $self->set_depth();
    $self->determine_cladogram();
    return;
}

=head2 set_name

 Title   : set_name
 Usage   : $tree->set_name($name);
 Function: Sets the tree name
 Returns : none
 Args    : name (string)

=cut

sub set_name {
    my ( $self, $name ) = @_;
    $self->{'name'} = $name;
}

=head2 get_name

 Title   : get_name
 Usage   : $name = $tree->get_name();
 Function: Returns the tree's name
 Returns : name (string) or undef if name doesn't exist
 Args    : none

=cut

sub get_name {
    if ( defined $_[0]->{'name'} ) {
        return $_[0]->{'name'};
    }
    else {
        return undef;
    }
}

=head2 set_as_default

 Title   : set_as_default
 Usage   : $tree->set_as_default();
 Function: assigns is_default variable for this object to 1. (default : 0)
 Returns : none
 Args    : none

=cut

sub set_as_default {
    my $self = shift;
    $self->{'is_default'} = 1;
}

=head2 is_default

 Title   : is_default
 Usage   : $is_default_tree = $tree->is_default();
 Function: check whether the tree is assigned as the default.
 Returns : 0 (false) or 1 (true)
 Args    : none

=cut

sub is_default {
    my $self = shift;
    return $self->{'is_default'};
}

=head2 set_as_unrooted

 Title   : set_as_unrooted
 Usage   : $tree->set_as_unrooted();
 Function: assigns is_unrooted variable for this object to 1. (default : 0)
 Returns : none
 Args    : none

=cut

sub set_as_unrooted {
    my $self = shift;
    $self->{'is_unrooted'} = 1;
}

=head2 is_rooted

 Title   : is_rooted
 Usage   : $is_rooted_tree = $tree->is_rooted();
 Function: Check whether the tree is rooted.
 Returns : 0 (false) or 1 (true)
 Args    : none

=cut

sub is_rooted {
    my $self = shift;
    return !$self->{'is_unrooted'};
}

=head2 determine_cladogram

 Title   : determine_cladogram
 Usage   : $tree->determine_cladogram();
 Function: Determine if a tree is a cladogram or not (that is, whether branch lengths are present)
 Returns : none
 Args    : none

=cut

sub determine_cladogram {
    my $self = shift;
    my $root = $self->get_rootnode();
    if ( $root->find_lengths() ) {
        $self->{'is_cladogram'} = 0;
    }
    else {
        $self->{'is_cladogram'} = 1;
    }
}

=head2 set_output_format 

 Title   : set_output_format 
 Usage   : $tree->set_output_format('STD');  
 Function: Sets the output format for the Tree, (options : STD or NHX)
 Returns : none
 Args    : string: 'STD' or 'NHX'

=cut

sub set_output_format {
    my ( $self, $format ) = @_;
    $self->{'_out_format'} = $format;
}

=head2 get_output_format 

 Title   : get_output_format 
 Usage   : $output_format = $tree->get_output_format();  
 Function: Returns the output format for the Tree, (options : STD or NHX)
 Returns : string: 'STD' or 'NHX'
 Args    : none

=cut

sub get_output_format {
    my ($self) = @_;
    if ( defined $self->{_out_format} ) {
        return $self->{_out_format};
    }
    else {
        my $format = 'STD';
        my $nodes  = $self->get_nodes();
        my @otus;
        for my $node ( @{$nodes} ) {
            if ( $node->{is_nhx} ) {
                $format = 'NHX';
                last;
            }
        }
        $self->{_out_format} = $format;
    }
    return $self->{_out_format};
}

=head2 is_cladogram

 Title   : is_cladogram
 Usage   : &dothis() if $tree->is_cladogram();
 Function: Returns whether tree is a cladogram or not
 Returns : 0 (no) or 1 (yes)
 Args    : none

=cut

sub is_cladogram {
    my $self = shift;
    return $self->{'is_cladogram'};
}

=head2 as_string

 Title   : as_string
 Usage   : $treestring = $tree->as_string();
 Function: Returns the tree as a string
 Returns : tree string (string)
 Args    : none

=cut

sub as_string {
    my $self = shift;
    my $root = $self->get_rootnode();
    my $string;
    $root->to_string( \$string, 0, $self->get_output_format );
    $string =~ s/\,$/\;/;
    return $string;
}

=head2 as_string_inodes_nameless

 Title   : as_string_inodes_nameless
 Usage   : $treestring = $tree->as_string_inodes_nameless();
 Function: Returns the tree as a string without internal node names
 Returns : tree string (string)
 Args    : none

=cut

sub as_string_inodes_nameless {
    my $self = shift;
    my $root = $self->get_rootnode();
    my $string;
    $root->to_string( \$string, 1, $self->get_output_format );
    $string =~ s/\,$/\;/;
    return $string;
}

=head2 get_nodes

 Title   : get_nodes
 Usage   : @nodes = @{$tree->get_nodes()};
 Function: Returns the list of ALL nodes in the tree
 Returns : reference to array of nodes (Bio::NEXUS::Node objects)
 Args    : none

=cut

sub get_nodes {
    my $self = shift;
    my $root = $self->get_rootnode();
    my @nodes;
    my $i = 1;
    $root->walk( \@nodes, \$i );
    $root->set_name('root')
        if !$root->get_name() || $root->get_name() =~ /^inode1/;
    return \@nodes;
}

=head2 get_node_names

 Title   : get_node_names
 Usage   : @otu_names = @{$tree->get_node_names()};
 Function: Returns the list of names of otus (terminal nodes)
 Returns : array ref of node names
 Args    : none

=cut

sub get_node_names {
    my $self  = shift;
    my $nodes = $self->get_nodes();
    my @otus;
    for my $node ( @{$nodes} ) {
        if ( $node->is_otu() ) {
            push @otus, $node->get_name();
        }
    }
    return \@otus;
}

=head2 get_distances

 Title   : get_distances
 Usage   : %distances = %{$tree->get_distances()};
 Function: Finds the distances from the root node for all OTUs
 Returns : reference to a hash of OTU names as keys and distances as values
 Args    : none

=cut

sub get_distances {
    my $self  = shift;
    my $nodes = $self->get_nodes();
    my $root  = $self->get_rootnode();
    my %distances;
    for my $node ( @{$nodes} ) {
        $distances{ $node->get_name() } = $root->get_distance($node);
    }
    return \%distances;
}

=head2 get_tree_length

 Title   : get_tree_length
 Usage   : $tre_length  = $self->get_tree_length;
 Function: Gets the total branch lengths in the tree.
 Returns : total branch length
 Args    : none

=cut

sub get_tree_length {
    my $self = shift;
    my $root = $self->get_rootnode();
    return $root->get_total_length();
}

=head2 get_support_values

 Title   : get_support_values
 Usage   : %bootstraps = %{$tree->get_support_values()};
 Function: Finds all branch support values for all OTUs
 Returns : reference to a hash where OTU names are keys and branch support values are values
 Args    : none

=cut

sub get_support_values {
    my $self  = shift;
    my $nodes = $self->get_nodes();
    my %bootstraps;
    for my $node ( @{$nodes} ) {
        my $boot = $node->get_support_value();
        $bootstraps{ $node->get_name() } = $boot if $boot;
    }
    return \%bootstraps;
}

=begin comment

 Title   : _set_xcoord
 Usage   : $tree->_set_xcoord($xpos,$maxx);
 Function: Determines x coords of OTUs and internal nodes
 Returns : none
 Args    : maximum x (number)

=end comment 

=cut

sub _set_xcoord {
    my ( $self, $maxx, $cladogramMethod ) = @_;
    my $xcoord =
        [ { 'node' => '', 'xcoord' => '' }, { 'node' => '', 'xcoord' => '' } ];
    my $root  = $self->get_rootnode();
    my @nodes = @{ $self->get_nodes() };
    if ( $self->is_cladogram() || $cladogramMethod ) {
        $cladogramMethod = 'normal' unless $cladogramMethod;
        my $maxdepth = $self->max_depth();
        my $unit     = $maxx / $maxdepth;
        my @xcoord;
        if ( $cladogramMethod eq "accelerated" ) {
            for my $node (@nodes) {
                if ( $node->is_otu() ) {
                    $node->_set_xcoord( $maxdepth * $unit );
                }
                else {
                    $node->_set_xcoord( $node->get_depth() * $unit );
                }
            }
        }
        elsif ( $cladogramMethod eq "normal" ) {
            my %depth = %{ $self->get_depth() };
            for my $node (@nodes) {
                $node->_set_xcoord( $node->get_depth() * $unit );
            }
        }
    }
    else {
        for my $node (@nodes) {
            $node->_set_xcoord( $root->get_distance($node) );
        }
    }
}

=begin comment

 Title   : _set_ycoord
 Usage   : $tree->_set_ycoord($ypos,$spacing);
 Function: Determines y coords of OTUs and internal nodes
 Returns : none
 Args    : initial y position (number), space between OTUs (number)

=end comment 

=cut

sub _set_ycoord {
    my ( $self, $ypos, $spacing ) = @_;
    my $root = $self->get_rootnode();
    $root->_assign_otu_ycoord( \$ypos, \$spacing );
    $root->_assign_inode_ycoord();
}

=head2 set_depth

 Title   : set_depth
 Usage   : $tree->set_depth();
 Function: Sets depth of root node
 Returns : none
 Args    : none

=cut

sub set_depth {
    my $self = shift;
    my $root = $self->get_rootnode();
    $root->set_depth(0);
}

=head2 get_depth

 Title   : get_depth
 Usage   : %depth=%{$tree->get_depth()};
 Function: Get depth in tree of all OTUs and internal nodes
 Returns : reference to hash with keys = node names and values = depth
 Args    : none

=cut

sub get_depth {
    my $self  = shift;
    my $nodes = $self->get_nodes();
    my %depth;
    for my $node ( @{$nodes} ) {
        my $d = $node->get_depth();
        $depth{ $node->get_name() } = $d if ( $d || ( $d == 0 ) );
    }
    return \%depth;
}

=head2 max_depth

 Title   : max_depth
 Usage   : $maxdepth=%{$tree->max_depth()};
 Function: Get maximum depth of tree
 Returns : integer indicating maximum depth
 Args    : none

=cut

sub max_depth {
    my $self   = shift;
    my %depth  = %{ $self->get_depth() };
    my @sorted = sort { $a <=> $b } values %depth;
    return ( pop @sorted );
}

=head2 find

 Title   : find
 Usage   : $node = $tree->find($name);
 Function: Finds the first occurrence of a node called 'name' in the tree
 Returns : Bio::NEXUS::Node object
 Args    : name (string)

=cut

sub find {
    my ( $self, $name ) = @_;
    my $rootnode = $self->get_rootnode();
    my $node     = $rootnode->find($name);
    return $node;
}

=head2 find_all

 Title   : find_all
 Usage   : @nodes = @{ $tree->find_all($name) };
 Function: find all occurrences of nodes called 'name' in the tree
 Returns : Bio::NEXUS::Node objects
 Args    : name (string)

=cut

sub find_all {
    my $self = shift;
    my @nodes;
    my @all_nodes = @{ $self->get_nodes() };
    my $name      = shift;
    for my $node (@all_nodes) {
        if ( $name eq $node->get_name() ) {
            push( @nodes, $node );
        }
    }
    return \@nodes;
}

=head2 prune

 Name    : prune
 Usage   : $tree->prune($OTUlist);
 Function: Removes everything from the tree except for OTUs specified in $OTUlist
 Returns : none
 Args    : list of OTUs (string)

=cut

sub prune {
    my ( $self, $OTUlist ) = @_;
    $OTUlist = ' ' . $OTUlist . ' ';
    my $rootnode = $self->get_rootnode();
    $rootnode->prune($OTUlist);
}

=head2 equals

 Name    : equals
 Usage   : $tree->equals($another_tree);
 Function: compare if two trees are equivalent in topology
 Returns : 1 if equal or 0 if not
 Args    : another Bio::NEXUS::Tree object

=cut

sub equals {
    my ( $self, $tree ) = @_;

    if ( $self->get_name() ne $tree->get_name() ) { return 0; }
    return $self->get_rootnode()->equals( $tree->get_rootnode() );
}

sub _equals_test {
    my ( $self, $tree ) = @_;

    if ( $self->get_name() ne $tree->get_name() ) { return 0; }
    return $self->get_rootnode()->_equals_test( $tree->get_rootnode() );
}

=head2 reroot

 Name    : reroot
 Usage   : $tree = $tree->reroot($outgroup_name);
 Function: re-root a tree with a node as outgroup
 Returns : 
 Args    : the node name to be used as new outgroup

=cut

sub reroot {
    my ( $self, $outgroup_name, $dist_back_to_newroot ) = @_;
    if ( not defined $outgroup_name ) {
    	Bio::NEXUS::Util::Exceptions::BadArgs->throw(
    		'error' => 'An outgroup name must be supplied as an argument in order to reroot'
    	);
    }

    my $tree = $self->clone();

    # find the current root of the tree
    my $oldroot = $tree->get_rootnode();

    # rename it, since nexplot relies on all nodes having unique names
    &_rename_oldroot( $tree, $oldroot );

    # get the outgroup node
    my $outgroup = $tree->find($outgroup_name);

    # create & name a new node that will become the new root
    my $newroot = new Bio::NEXUS::Node();

    if (   $dist_back_to_newroot
        && $dist_back_to_newroot == $outgroup->get_length() )
    {
        $newroot = $outgroup->get_parent();
        $outgroup->set_length($dist_back_to_newroot);
        $newroot->get_parent()->_rearrange($newroot);
    }
    else {

        # find the node that will (temporarily) become the newroot's parent
        my $outgroup_old_parent = $outgroup->get_parent();

        # get the siblings of the outgroup
        my $newroot_siblings = $outgroup->get_siblings();

        # get the correct branch lengths for newroot and outgroup
        &_position_newroot( $outgroup, $newroot, $dist_back_to_newroot );

        # make outgroup the newroot's child and newroot the outgroup's parent
        $newroot->adopt( $outgroup, 1 );

        # remove the outgroup from the old parent's children
        $outgroup_old_parent->set_children($newroot_siblings);

        # add the newroot as a child
        $outgroup_old_parent->adopt( $newroot, 0 );

# recursively reverse the parent-child relationships between newroot and oldroot
        $outgroup_old_parent->_rearrange($newroot);
    }

    # set newroot's values to make it root
    $newroot->set_name('root');
    $newroot->set_parent_node();
    $newroot->set_support_value();
    $newroot->set_length();
    $newroot->set_depth(0);
    $tree->set_rootnode($newroot);

    # remove oldroot if the tree was bifurcating
    &_remove_oldroot_if_superfluous($oldroot);

    return $tree;
}

sub _rename_oldroot {
    my ( $tree, $oldroot ) = @_;
    my $i               = 0;
    my $renamed_oldroot = 0;
    my $oldroot_name    = 'oldroot';
    while ( $renamed_oldroot == 0 ) {
        if ( !$tree->find("$oldroot_name") ) {
            $oldroot->set_name("$oldroot_name");
            $renamed_oldroot = 1;
        }
        else {
            $oldroot_name = "oldroot" . "$i";
            $i++;
        }
    }
}

sub _position_newroot {
    my ( $outgroup, $newroot, $dist_back_to_newroot ) = @_;
    if ( $outgroup->get_length() ) {
        my $outgroup_length = $outgroup->get_length();
        if ($dist_back_to_newroot) {
            if (   $dist_back_to_newroot < $outgroup_length
                && $dist_back_to_newroot > 0 )
            {
                ## $dist_back_to_newroot should already be negative
                $newroot->set_length(
                    $outgroup_length - $dist_back_to_newroot );
                $outgroup->set_length($dist_back_to_newroot);
            }
            else {
                Bio::NEXUS::Util::Exceptions::BadNumber->throw(
                	'error' => "Branch length error: The new root's position\n"
                			. "up the tree from the outgroup must be a positive\n"
                			. "number less than or equal to the outgroup's branch length.\n"
                );
            }
        }
        else {
            $newroot->set_length( $outgroup_length / 2 );
            $outgroup->set_length( $outgroup_length / 2 );
        }
    }
    else {
        if ($dist_back_to_newroot) {
        	Bio::NEXUS::Util::Exceptions::BadArgs->throw(
        		'error' => "You provided a position for the new root on the\n"
        				. "outgroup's branch length, but the outgroup does\n"
        				. "not have a branch length.\n"
        	);
        }
    }
}

sub _remove_oldroot_if_superfluous {
    my ($oldroot) = @_;
    if ( @{ $oldroot->get_children() } == 1 ) {
        my $oldroot_child = ${ $oldroot->get_children() }[0];
        if (   defined $oldroot->get_length()
            || defined $oldroot_child->get_length() )
        {
            $oldroot_child->set_length(
                $oldroot->get_length() + $oldroot_child->get_length() );
        }
        my $oldroot_parent = $oldroot->get_parent();
        $oldroot_parent->set_children( $oldroot->get_siblings() );
        $oldroot_parent->adopt( $oldroot_child, 0 );
    }
}

=head2 select_subtree 

 Name    : select_subtree
 Usage   : $new_tree_obj = $self->select_subtree($node_name);
 Function: selects the subtree (the given node and all its children) from the tree object.
 Returns : new Bio::NEXUS::Tree object
 Args    : Node name

=cut

sub select_subtree {
    my ( $self, $nodename ) = @_;
    my $newroot  = $self->find($nodename);
    my $treename = $self->get_name();
    if ( not $newroot ) {
    	Bio::NEXUS::Util::Exceptions::BadArgs->throw(
    		'error' => "Node $nodename not found in $treename"
    	);
    }
    $newroot = $newroot->clone();    # need to clone subtree
    $newroot->set_parent_node();     # make it as root
    $newroot->set_support_value();
    $newroot->set_length();
    my $tree = new Bio::NEXUS::Tree();
    $tree->set_name( $self->get_name() );
    $tree->set_rootnode($newroot);
    return $tree;
}

=head2 exclude_subtree

 Name    : exclude_subtree
 Usage   : $new_tree_obj = $self->exclude_subtree($node_name);
 Function: removes the given node and all its children from the tree object.
 Returns : new Bio::NEXUS::Tree object
 Args    : Node name

=cut

sub exclude_subtree {
    my ( $self, $nodename ) = @_;
    my $treename   = $self->get_name();
    my $tree       = $self->clone();
    my $removenode = $tree->find($nodename);
    
    if ( not $removenode ) {
    	Bio::NEXUS::Util::Exceptions::BadArgs->throw(
    		'error' => "Node $nodename not found in $treename"
    	);
    }    

    my $parent   = $removenode->get_parent();
    my @children = @{ $parent->get_children() };
    $parent->set_children();
    for my $child (@children) {
        if ( $child->get_name() ne $removenode->get_name() ) {
            $parent->add_child($child);
        }
    }
    if ( @{ $parent->get_children() } == 1 ) {
        my $sibling = $parent->get_children()->[0];
        $parent->combine($sibling);
    }

    return $tree;
}

=head2 get_mrca_of_otus

 Name    : get_mrca_of_otus
 Usage   : $node = $self->get_mrca_of_otus($otus);
 Function: gets the most recent common ancestor for the input $otus
 Returns : Bio::NEXUS::Node object
 Args    : $otus : Array reference of the OTUs

=cut

sub get_mrca_of_otus {
    my ( $self, $otus) = @_;
    my $root_node = $self->get_rootnode;
   return $root_node->get_mrca_of_otus($otus);
}

sub AUTOLOAD {
    return if $AUTOLOAD =~ /DESTROY$/;
    my $package_name = __PACKAGE__ . '::';

    # The following methods are deprecated and are temporarily supported
    # via a warning and a redirection
    my %synonym_for = (
        "${package_name}node_list"  => "${package_name}get_nodes",
        "${package_name}otu_list"   => "${package_name}get_node_names",
        "${package_name}set_xcoord" => "${package_name}_set_xcoord",
        "${package_name}set_ycoord" => "${package_name}_set_ycoord",
        "${package_name}name"       => "${package_name}get_name",
        "${package_name}set_tree"   => "${package_name}_parse_newick",
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
    return;
}

1;
