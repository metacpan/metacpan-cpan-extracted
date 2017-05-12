######################################################
# Node.pm
######################################################
# Author:  Weigang Qiu, Eugene Melamud, Chengzhi Liang, Peter Yang, Thomas Hladish, Vivek Gopalan
# $Id: Node.pm,v 1.70 2009/08/13 20:35:55 astoltzfus Exp $

#################### START POD DOCUMENTATION ##################

=head1 NAME

Bio::NEXUS::Node - Provides functions for manipulating nodes in trees

=head1 SYNOPSIS

new Bio::NEXUS::Node;

=head1 DESCRIPTION

Provides a few useful functions for nodes.

=head1 FEEDBACK

All feedback (bugs, feature enhancements, etc.) are all greatly appreciated. There are no mailing lists at this time for the Bio::NEXUS::Node module, so send all relevant contributions to Dr. Weigang Qiu (weigang@genectr.hunter.cuny.edu).

=head1 AUTHORS

 Weigang Qiu (weigang@genectr.hunter.cuny.edu)
 Eugene Melamud (melamud@carb.nist.gov)
 Chengzhi Liang (liangc@umbi.umd.edu)
 Thomas Hladish (tjhladish at yahoo)

=head1 CONTRIBUTORS

 Peter Yang (pyang@rice.edu)

=head1 METHODS

=cut

package Bio::NEXUS::Node;

use strict;
use Bio::NEXUS::Functions;
use Bio::NEXUS::NHXCmd;
use Bio::NEXUS::Util::Exceptions;
use Bio::NEXUS::Util::Logger;
use vars qw($VERSION $AUTOLOAD);
#use Data::Dumper; # XXX this is not used, might as well not import it!
#use Carp; # XXX this is not used, might as well not import it!

use Bio::NEXUS; $VERSION = $Bio::NEXUS::VERSION;
my $logger = Bio::NEXUS::Util::Logger->new();

sub BEGIN {
    eval {
        require warnings;
        1;
        }
        or do {
        no strict 'refs';
        *warnings::import = *warnings::unimport = sub { };
        $INC{'warnings.pm'} = '';
        };
}

=head2 new

 Title   : new
 Usage   : $node = new Bio::NEXUS::Node();
 Function: Creates a new Bio::NEXUS::Node object
 Returns : Bio::NEXUS::Node object
 Args    : none

=cut

sub new {
    my ($class) = @_;
    my $self = { _nhx_obj => undef };
    bless $self, $class;
    return $self;
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
    my $newnode = bless( { %{$self} }, $class );
    if ( defined $self->{_nhx_obj} ) {
        $newnode->{_nhx_obj} = $self->clone_nhx_command;
    }
    my @children = @{ $newnode->get_children() };
    $newnode->set_children();
    for my $child (@children) {
        my $newchild = $child->clone();
        $newnode->add_child($newchild);
        $newchild->set_parent_node($newnode);
    }
    return $newnode;
}

=head2 get_seq

 Title   : get_seq
 Usage   : $sequence = $node->get_seq();
 Function: Returns the node's sequence
 Returns : sequence (string)
 Args    : none

=cut

sub get_seq {
    my ($self) = @_;
    return $self->{'seq'};
}

=head2 set_seq

 Title   : set_seq
 Usage   : $node->set_seq($sequence);
 Function: Sets sequence of the node
 Returns : none
 Args    : sequence (string)

=cut

sub set_seq {
    my ( $self, $seq ) = @_;
    $self->{'seq'} = $seq;
}

=head2 set_parent_node

 Title   : set_parent_node
 Usage   : $node->set_parent_node($parent);
 Function: Sets the parent node of the node
 Returns : none
 Args    : parent node (Bio::NEXUS::Node object)

=cut

sub set_parent_node {
    my ( $self, $parent ) = @_;
    $self->{'parent'} = $parent;
}

=head2 get_parent

 Title   : get_parent
 Usage   : $parent=$node->get_parent();
 Function: Returns the parent node of the node
 Returns : parent node (Bio::NEXUS::Node object) or undef if nonexistent
 Args    : none

=cut

sub get_parent {
    if ( defined $_[0]->{'parent'} ) {
        return $_[0]->{'parent'};
    }
    else {
        return undef;
    }
}

=head2 set_length

 Title   : set_length
 Usage   : $node->set_length($length);
 Function: Sets the node's length (meaning the length of the branch leading to the node)
 Returns : none
 Args    : length (number)

=cut

sub set_length {
    my ( $self, $length ) = @_;
    $self->{'length'} = $length;
}

=head2 get_length

 Title   : length
 Usage   : $length=$node->get_length();
 Function: Returns the node's length
 Returns : length (integer) or undef if nonexistent
 Args    : none

=cut

sub get_length {
    if ( defined $_[0]->{'length'} ) {
        return $_[0]->{'length'};
    }
    else {
        return undef;
    }
}

=head2 get_total_length

 Title   : get_total_length
 Usage   : $total_length = $node->get_total_length();
 Function: Gets the total branch length of the node and that of all the children (???)
 Returns : total branch length
 Args    : none

=cut

sub get_total_length {
    my $self = shift;
    my $len = $self->get_length() || 0;
    for my $child ( @{ $self->get_children() } ) {
        $len += $child->get_total_length();
    }
    return $len;
}

=head2 set_support_value

 Title   : set_support_value
 Usage   : $node->set_support_value($bootstrap);
 Function: Sets the branch support value associated with this node
 Returns : none
 Args    : bootstrap value (integer)

=cut

sub set_support_value {
    my ( $self, $bootstrap ) = @_;
    if ( defined $bootstrap and not _is_number($bootstrap) ) {
    	$logger->info("Attempt to set bad branch support value: <$bootstrap> is not a valid number");
    }
    elsif ( not defined $bootstrap ) {
    	$logger->info("Attempt to set undefined branch support value");
    }

    $self->set_nhx_tag( 'B', [$bootstrap] );
}

=head2 get_support_value

 Title   : get_support_value
 Usage   : $bootstrap = $node->get_support_value();
 Function: Returns the branch support value associated with this node
 Returns : bootstrap value (integer) or undef if nonexistent
 Args    : none

=cut

sub get_support_value {
    my ($self)        = @_;
    my ($support_val) = $self->get_nhx_values('B');
    return $support_val;
}

=begin comment

 Title   : _set_xcoord
 Usage   : $node->_set_xcoord($xcoord);
 Function: Sets the node's x coordinate (?)
 Returns : none
 Args    : x coordinate (integer)

=end comment 

=cut

sub _set_xcoord {
    my ( $self, $xcoord ) = @_;
    $self->{'xcoord'} = $xcoord;
}

=begin comment

 Title   : _get_xcoord
 Usage   : $xcoord=$node->_get_xcoord();
 Function: Returns the node's x coordinate
 Returns : x coordinate (integer) or undef if nonexistent
 Args    : none

=end comment 

=cut

sub _get_xcoord {
    if ( defined $_[0]->{'xcoord'} ) {
        return $_[0]->{'xcoord'};
    }
    else {
        return undef;
    }
}

=begin comment

 Title   : _set_ycoord
 Usage   : $node->_set_ycoord($ycoord);
 Function: Sets the node's y coordinate (?)
 Returns : none
 Args    : y coordinate (integer)

=end comment 

=cut

sub _set_ycoord {
    my ( $self, $ycoord ) = @_;
    $self->{'ycoord'} = $ycoord;
}

=begin comment

 Title   : _get_ycoord
 Usage   : $ycoord=$node->_get_ycoord();
 Function: Returns the node's y coordinate
 Returns : y coordinate (integer) or undef if nonexistent
 Args    : none

=end comment 

=cut

sub _get_ycoord {
    my $self = shift;
    return $self->{'ycoord'};
}

=head2 set_name

 Title   : set_name
 Usage   : $node->set_name($name);
 Function: Sets the node's name
 Returns : none
 Args    : name (string/integer)

=cut

sub set_name {
    my ( $self, $name ) = @_;
    $self->{'name'} = $name;
}

=head2 get_name

 Title   : get_name
 Usage   : $name = $node->get_name();
 Function: Returns the node's name
 Returns : name (integer/string) or undef if nonexistent
 Args    : none

=cut

sub get_name {
    my $self = shift;
    return $self->{'name'};
}

=head2 is_otu

 Title   : is_otu
 Usage   : $node->is_otu();
 Function: Returns 1 if the node is an OTU or 0 if it is not (internal node)
 Returns : 1 or 0
 Args    : none

=cut

sub is_otu {
    my $self = shift;
    defined $self->{'children'} ? return 0 : return 1;
}

=head2 add_child

 Title   : add_childTU
 Usage   : $node->add_child($node);
 Function: Adds a child to an existing node
 Returns : none
 Args    : child (Bio::NEXUS::Node object)

=cut

sub add_child {
    my ( $self, $child ) = @_;
    push @{ $self->{'children'} }, $child;
}

=head2 get_distance

 Title   : get_distance
 Usage   : $distance = $node1->get_distance($node2);
 Function: Calculates tree distance from one node to another (?)
 Returns : distance (floating-point number)
 Args    : target node (Bio::NEXUS::Node objects)

=cut

sub get_distance {
    my ( $node1, $node2 ) = @_;
    if ( not defined $node2 ) {
    	Bio::NEXUS::Util::Exceptions::BadArgs->throw(
    		'error' => "Missing argument for 'get_distance' method.\n"
    				."The target node is node has to be defined"
    	);
    }
    my $distance = 0;
    if ( $node1 eq $node2 ) {
        return 0;
    }
    my $tmp_node1 = $node1;
    my $tmp_node2 = $node2;

    my %parent1;
    my $common_parent;

    while ( defined $tmp_node1->{'parent'} ) {
        $parent1{$tmp_node1} = 1;
        $tmp_node1 = $tmp_node1->{'parent'};
    }

    #add root node to hash
    $parent1{$tmp_node1} = 1;

    #the following line handles cases where node2 is root
    $common_parent = $tmp_node2;

    while ( not exists $parent1{$tmp_node2} ) {
        if ( defined $tmp_node2->{'parent'} ) {
            $distance += $tmp_node2->get_length();
            $tmp_node2 = $tmp_node2->{'parent'};
        }
        $common_parent = $tmp_node2;
        my $tmp = $common_parent->get_length();
    }

    $tmp_node1 = $node1;    #reset node1
    while ( $tmp_node1 ne $common_parent ) {
        if ( defined $tmp_node1->{'parent'} ) {
            $distance += $tmp_node1->get_length();
            $tmp_node1 = $tmp_node1->{'parent'};
        }
    }
    return $distance;
}

=head2 to_string

 Title   : to_string
 Usage   : my $string; $root->tree_string(\$string, 0, $format)
 Function: recursively builds Newick tree string from root to tips 
 Returns : none
 Args    : reference to string, boolean $remove_inode_names flag, string - $format (NHX or STD) 

=cut

sub to_string {
    my ( $self, $outtree, $remove_inode_names, $out_format ) = @_;

    my $name = $self->get_name();
    $name = _nexus_formatted($name);

    #my $bootstrap = $self->get_support_value();
    my $comment =
        ( $out_format =~ /NHX/i )
        ? $self->nhx_command_to_string
        : $self->get_support_value;
    my $length   = $self->get_length();
    my @children = @{ $self->get_children() };

    if (@children) {    # if $self is an internal node
        $$outtree .= '(';

        for my $child (@children) {
            $child->to_string( $outtree, $remove_inode_names, $out_format );
        }

        $$outtree .= ')';

        if ( defined $name && !$remove_inode_names ) { $$outtree .= $name }
        if ( defined $length )  { $$outtree .= ":$length" }
        if ( defined $comment ) { $$outtree .= "[$comment]" }

        $$outtree .= ',';

    }
    else {    # if $self is a terminal node

        if ( not defined $name ) {
        	Bio::NEXUS::Util::Exceptions::BadArgs->throw(
        		'error' => "OTU found without a name (terminal nodes must be named)"
        	);
        }
        $$outtree .= $name;

        if ( defined $length )  { $$outtree .= ":$length" }
        if ( defined $comment ) { $$outtree .= "[$comment]" }

        $$outtree .= ',';
    }
    $$outtree =~ s/,\)/)/g;
}

=head2 set_children

 Title   : set_children
 Usage   : $node->set_children($children);
 Function: Sets children
 Returns : $node
 Args    : arrayref of children

=cut

sub set_children {
    my ( $self, $children ) = @_;
    $self->{'children'} = $children;
}

=head2 get_children

 Title   : get_children
 Usage   : @children = @{ $node->get_children() };
 Function: Retrieves list of children
 Returns : array of children (Bio::NEXUS::Node objects)
 Args    : none

=cut

sub get_children {
    my $self = shift;
    return $self->{'children'} if ( $self->{'children'} );
    return [];
}

=head2 walk

 Title   : walk
 Usage   : @descendents = $node->walk();
 Function: Walks through tree and compiles a "clade list" 
     (including $self and all inodes and otus descended from $self)
 Returns : array of nodes
 Args    : generally, none, though walk() calls itself recurseively with 
     2 arguments: the node list so far, and a counting variable for inode-naming

=cut

sub walk {
    my ( $self, $nodes, $i ) = @_;

    my $name = $self->get_name();
    # if the node doesn't have a name, name it inode<number>
    if ( !$name ) {
        $self->set_name( 'inode' . $$i++ );
    }

    # if it's not an otu, and the name is a number ('X'), rename it inodeX
    elsif ( !$self->is_otu() && $name =~ /^\d+$/ ) {
        $self->set_name( 'inode' . $name );
    }

    my @children = @{ $self->get_children() };

    # if $self is not an otu,
    if (@children) {
        for my $child (@children) {
            $child->walk( $nodes, $i ) if $child;
        }
    }

    #print scalar @{$nodes}, "\n";;
    push @$nodes, $self;
}

=head2 get_otus

 Title   : get_otus
 Usage   : @listOTU = @{$node->get_otu()}; (?)
 Function: Retrieves list of OTUs
 Returns : reference to array of OTUs (Bio::NEXUS::Node objects)
 Args    : none

=cut

sub get_otus {
    my $self = shift;
    my @otus;
    $self->_walk_otus( \@otus );
    return \@otus;
}

=begin comment

 Title   : _walk_otus
 Usage   : $self->_walk_otus(\@otus);
 Function: Walks through tree and retrieves otus; recursive
 Returns : none
 Args    : reference to list of otus

=end comment 

=cut

sub _walk_otus {
    my $self  = shift;
    my $nodes = shift;

    my $children = $self->get_children();
    for my $child (@$children) {
        if ( $child->is_otu ) {
            push @$nodes, $child;
        }
        else {
            $child->_walk_otus($nodes) if @$children;
        }
    }
}

=head2 printall

 Title   : printall
 Usage   : $tree_as_string = $self->printall(); 
 Function: Gets the node properties as a tabbed string for printing nicely 
           formatted trees (developed by Tom)
 Returns : Formatted string
 Args    : Bio::NEXUS::Node object

=cut

sub printall {
    my $self = shift;

    my $children = $self->get_children();
    my $str      = "Name: ";
    $str .= $self->get_name()   if ( $self->get_name() );
    $str .= "   OTU\?: ";
    $str .= $self->is_otu();
    $str .= "    Length: ";
    $str .= $self->get_length() if $self->get_length();

    #$str .= "    bootstrap: ";
    #$str .= $self->get_support_value() if $self->get_support_value();
    $str .= "    Comment: ";
    $str .= $self->nhx_command_to_string() if $self->nhx_command_to_string();
    $str .= "\n";

    #carp($str);
    print $str;

    for my $child (@$children) {
        $child->printall();
    }
}

=begin comment

 Title   : _parse_newick
 Usage   : $self->_parse_newick($nexus_words, $pos);
 Function: Parse a newick tree string and build up the NEXPL tree it implies
 Returns : none
 Args    : Ref to array of NEXUS-style words that make up the tree string; ref to current position in array

=end comment 

=cut

sub _parse_newick {
    no warnings qw( recursion );
    my ( $self, $words, $pos ) = @_;
    if ( not $words and not @$words ) {
    	Bio::NEXUS::Util::Exceptions::BadArgs->throw(
    		'error' => 'Bio::NEXUS::Node::_parse_newick() called without something to parse'
    	);
    }
    $pos = 0 unless $pos;

    for ( ; $pos < @$words; $pos++ ) {
        my $word = $words->[$pos];

        # For parsing the comments within the NEXUS word.
        $word = $self->_parse_comment($word);
        if ( $word eq '(' ) {
            my $parent_node = $self;

            # start a new clade
            my $new_node = new Bio::NEXUS::Node;
            $parent_node->adopt($new_node);
            $pos = $new_node->_parse_newick( $words, ++$pos );
        }

        # We're starting a sibling of the current node's
        elsif ( $word eq ',' ) {
            my $parent_node = $self->get_parent();
            my $new_node    = new Bio::NEXUS::Node;
            $parent_node->adopt($new_node);
            $pos = $new_node->_parse_newick( $words, ++$pos );
        }

        elsif ( $word eq ')' ) {
            my $parent_node = $self->get_parent();
            $pos = $parent_node->_parse_newick( $words, ++$pos );

            # finish a clade
            last;
        }
        elsif ( $word eq ':' ) {
            $pos = $self->_parse_length( $words, ++$pos );
        }
        else {
            $self->set_name($word);
        }
    }
    return $pos;
}

=begin comment

 Title   : _parse_comment
 Usage   : $self->_parse_comment($words,$pos);
 Function: parses and stores comments in the nodes
 Returns : none
 Args    : $words, $pos string, which may contain bootstraps as well

=end comment 

=cut

sub _parse_comment {
    my ( $self, $word ) = @_;
    my $nhx_obj;

    if ( $word =~ s/\[(.*)\]// ) {

        # parse non-empty comment string
        my $comment_str = $1;
        $nhx_obj = new Bio::NEXUS::NHXCmd($comment_str);

        # check if the comment was an NHX command (&&NHX)
        if ( defined $nhx_obj->to_string ) {
            $self->{'is_nhx'} = 1;
        }
        else {
            $self->{'is_nhx'} = 0;
            $nhx_obj->set_tag( 'B', [$comment_str] );
            $self->_parse_support_value($comment_str) if defined $comment_str;

            #$nhx_obj = new Bio::NEXUS::NHXCmd();
            #$nhx_obj->set_tag('B',$support_value);
        }
        $self->{_nhx_obj} = $nhx_obj;
    }
    return $word;
}

=begin comment

 Title   : _parse_length
 Usage   : $self->_parse_length($length);
 Function: parses and stores branch lengths
 Returns : none
 Args    : $distance string, which may contain bootstraps as well

=end comment 

=cut

sub _parse_length {
    my ( $self, $words, $pos ) = @_;

    my $length;

    # number may have been split up if there were '-' (negative) signs
    until ( !defined $words->[$pos] || $words->[$pos] =~ /^[),]$/ ) {
        $length .= $words->[ $pos++ ];
    }
    --$pos;

    $length = $self->_parse_comment($length);

    # empty branch length definition
    return $pos unless defined $length;

	if ( not _is_number($length) ) {
		Bio::NEXUS::Util::Exceptions::BadNumber->throw(
			'error' => "Bad branch length found in tree string: <$length> is not a valid number"
			
		);
	}

    if ( $length =~ /e/i ) {
        $length = _sci_to_dec($length);
    }
    $self->set_length($length);
    return $pos;
}

=begin comment

 Title   : _parse_support_value
 Usage   : $self->_parse_support_value($boostrap_value);
 Function: Unsure
 Returns : none
 Args    : unsure

=end comment 

=cut

sub _parse_support_value {
    my ( $self, $bootstrap ) = @_;

	if ( not _is_number($bootstrap) ) {
		Bio::NEXUS::Util::Exceptions::BadNumber->throw(
			'error' => "Bad branch support value found in tree string: <$bootstrap> is not a valid number"
		);
	}

    $self->set_support_value( _sci_to_dec($bootstrap) )
        if defined _sci_to_dec($bootstrap);
    return $bootstrap;
}

=head2 find

 Title   : find
 Usage   : $node = $node->find($name);
 Function: Finds the first occurrence of a node called 'name' in the tree
 Returns : Bio::NEXUS::Node object
 Args    : name (string)

=cut

sub find {
    my ( $self, $name ) = @_;
    my $nodename = $self->get_name();
    my $children = $self->get_children();
    return $self if ( $self->get_name() eq $name );
    for my $child (@$children) {
        my $result = $child->find($name);
        return $result if $result;
    }
    return undef;
}

=head2 prune

 Name    : prune
 Usage   : $node->prune($OTUlist);
 Function: Removes everything from the tree except for OTUs specified in $OTUlist
 Returns : none
 Args    : list of OTUs (string)

=cut

sub prune {
    my ( $self, $OTUlist ) = @_;
    my $name = $self->get_name();
    # the following line is in response to [rt.cpan.org #47707] Bug in Bio::NEXUS::Node.pm
    $name = quotemeta $name; 
    if ( $self->is_otu() ) {
        if ( $OTUlist =~ /\s+$name\s+/ ) {

            # if in the list, keep this OTU
            return "keep";
        }
        else {
            # otherwise, delete it
            return "delete";
        }
    }
    my @children    = @{ $self->get_children() };
    my @newchildren = ();
    for my $child (@children) {
        my $result = $child->prune($OTUlist);
        if ( $result eq "keep" ) {
            push @newchildren, $child;
        }
    }
    $self->{'children'} = \@newchildren;
    if ( $#newchildren == -1 ) {

        # delete the inode because it doesn't have any children
        $self->{'children'} = undef;
        return "delete";
    }
    @children = @{ $self->get_children() };
    if ( $#children == 0 ) {
        my $child     = $children[0];
        my $childname = $children[0]->get_name();

        $self->set_name( $child->get_name() );
        $self->set_seq( $child->get_seq() );
        my $self_length = $self->get_length() || 0;
        $self->set_length( $self_length + $child->get_length() );
        $self->set_support_value( $child->get_support_value() );
        $self->set_nhx_obj( $child->get_nhx_obj()->clone )
            if defined $child->{_nhx_obj};
        $self->_set_xcoord( $child->_get_xcoord() );
        $self->_set_ycoord( $child->_get_ycoord() );
        $self->{'children'} = $child->{'children'};

        if ( $child->is_otu() ) {
            $self->{'children'} = undef;
            undef $self->{'children'};
        }

        # assigning inode $name to child $childname
        return "keep";
    }

    # keeping this inode as is, since it has multiple children
    return "keep";
}

=head2 equals

 Name    : equals
 Usage   : $node->equals($another_node);
 Function: compare if two nodes (and their subtrees) are equivalent
 Returns : 1 if equal or 0 if not
 Args    : another Node object

=cut

sub equals {
    my ( $self, $other ) = @_;

    # 1 if only one is OTU
    if (   ( $self->is_otu() && !$other->is_otu() )
        || ( !$self->is_otu() && $other->is_otu() ) )
    {

        # not the same
        return 0;
    }

    # 2. both are OTUs
    if ( $self->is_otu() && $other->is_otu() ) {
        if ( $self->_same_attributes($other) ) {

            # ...
            return 1;
        }
        else {
            return 0;
        }
    }

    # 3. neither is OTU
    my @self_children  = @{ $self->get_children() };
    my @other_children = @{ $other->get_children() };

    # compare the attributes of the nodes - see if different
    if ( !$self->_same_attributes($other) ) { return 0; }

    my $num_of_kids = scalar @self_children;

    if ( scalar @self_children != scalar @other_children ) {

        # children are different (their quantity differs)
        return 0;
    }
    else {
        for ( my $self_index = 0; $self_index < $num_of_kids; $self_index++ ) {
            my $found = 'false';

            for (
                my $other_index = $self_index;
                $other_index < $num_of_kids;
                $other_index++
                )
            {

                # the fun part starts here
                # comparing the unsorted arrays of children

                if ( $self_children[$self_index]
                    ->equals( $other_children[$other_index] ) )
                {
                    $found = 'true';

                    # pull out the child that was found and add it to
                    # the front of the array
                    my $temp = $other_children[$other_index];
                    splice( @other_children, $other_index, 1 );
                    unshift( @other_children, $temp );

                    last;
                }
            }

            if ( $found eq 'false' ) {
                return 0;
            }
        }
    }

    return 1;

}

# helper function that compares attributes of two node objects
sub _same_attributes {
    my ( $self, $other ) = @_;

	# mighty one-liner (if the length of one of the nodes is defined, and the length of the other node is not, return false)
	return 0 if (!((defined $self->get_length() && defined $other->get_length())
					||
					(! defined $self->get_length() && ! defined $other->get_length())));
	
	if (defined $self->get_length() && defined $other->get_length()) {
			if ( $self->get_length() != $other->get_length() ) { return 0; }
	}

    # if the nodes are internal, don't check their names...
    # they will most likely differ
    if ( $self->is_otu() && $other->is_otu() ) {
        if ( $self->get_name() ne $other->get_name() ) { return 0; }
    }

    if ( defined $self->get_nhx_obj() && defined $other->get_nhx_obj() ) {
        if ( !$self->get_nhx_obj()->equals( $other->get_nhx_obj ) ) {
            return 0;
        }
    }
    if ( !defined $self->get_nhx_obj() && defined $other->get_nhx_obj() ) {
        return 0;
    }
    if ( defined $self->get_nhx_obj() && !defined $other->get_nhx_obj() ) {
        return 0;
    }

    return 1;
}

=head2 get_siblings

 Name    : get_siblings
 Usage   : $node->get_siblings();
 Function: get sibling nodes of this node
 Returns : array ref of sibling nodes
 Args    : none

=cut

sub get_siblings {
    my $self = shift;
    return [] unless defined $self->get_parent;
    my $generation = $self->get_parent()->get_children();
    my $siblings   = [];
    for my $potential_sibling ( @{$generation} ) {
        if ( $potential_sibling ne $self ) {
            push( @$siblings, $potential_sibling );
        }
    }
    return $siblings;
}

=head2 is_sibling

 Name    : is_sibling
 Usage   : $node1->is_sibling($node2);
 Function: tests whether node1 and node2 are siblings
 Returns : 1 if true, 0 if false
 Args    : second node

=cut

sub is_sibling {
    my ( $self, $node2 ) = @_;
    if ( not defined $node2 ) {
    	Bio::NEXUS::Util::Exceptions::BadArgs->throw(
    		'error' => "Missing argument for 'is_sibling' method.\n"
    				. " The node object to test for sibiling has to be given as argument"
    	);
    }
    my $parent1 = $self->get_parent();
    my $parent2 = $node2->get_parent();
    return "1"
        if ( ( defined $parent1 and defined $parent2 )
        and $parent1 eq $parent2 );
    return "0";
}

=begin comment

 Name    : _rearrange
 Usage   : $node->_rearrange($newparentnode);
 Function: re-arrange this node's parent and children (used in rerooting)
 Returns : this node after rearrangement
 Args    : this node's new parent node, $newparentnode must be this node's old child

=end comment 

=cut

sub _rearrange {
    my ( $self, $newparent ) = @_;

    # Remove the newparent from this node's children
    $self->set_children( $newparent->get_siblings() );

    # Recursively work up the tree until you get to the node
    my $oldparent = $self->get_parent();
    if ($oldparent) { $oldparent->_rearrange($self); }

    # set new parent as parent, self as child
    $newparent->adopt( $self, 0 );
    $self->set_support_value( $newparent->get_support_value() );
    $self->set_nhx_obj( $newparent->get_nhx_obj()->clone )
        if defined $newparent->{_nhx_obj};
    $self->set_length( $newparent->get_length() );

    return $self;
}

=head2 adopt

 Title   : adopt
 Usage   : $parent->adopt($child, $overwrite_children);
 Function: make a parent-child relationship between two nodes
 Returns : none
 Args    : the child node, boolean clobber flag

=cut

sub adopt {
    my ( $parent, $child, $overwrite_children ) = @_;
    $child->set_parent_node($parent);
    if ($overwrite_children) {
        $parent->set_children( [$child] );
    }
    else {
        $parent->add_child($child);
    }
}

=head2 combine

 Title   : combine
 Usage   : my $newblock = $node->combine($child);
 Function: removes a node from the tree, effectively by sliding its only child up the branch to its former position
 Returns : none
 Args    : the child node
 Methods : Combines the child node and the current node by assigning the
           name, bootstrap value, children and other properties of the child.  The branch length
	   of the current node is added to the child node's branch length.

=cut

sub combine {
    my ( $self, $child ) = @_;
    $self->set_name( $child->get_name() );
    $self->set_support_value( $child->get_support_value() );
    $self->set_nhx_obj( $child->get_nhx_obj()->clone )
        if defined $child->{_nhx_obj};
    $self->set_length( ( $self->get_length() || 0 ) + $child->get_length() );
    $self->set_children();
    $self->set_children( $child->get_children() )
        if @{ $child->get_children } > 0;
}

=begin comment

 Title   : _assign_otu_ycoord
 Usage   : $root->_assign_otu_ycoord(\$ypos, \$spacing);
 Function: Assign y coords of OTUs
 Returns : none
 Args    : references to initial y position and space between each OTU

=end comment 

=cut

# Traverses tree and determines y position of every OTU it finds. If it finds
# an OTU, it adds the current y position to a hash of y coordinates (one key
# for each OTU) and increments the y position.
sub _assign_otu_ycoord {
    my ( $self, $yposref, $spacingref ) = @_;
    return if $self->is_otu();
    for my $child ( @{ $self->get_children() } ) {
        if ( $child->is_otu() ) {
            $child->_set_ycoord($$yposref);
            $$yposref += $$spacingref;
        }
        else {
            $child->_assign_otu_ycoord( $yposref, $spacingref );
        }
    }
}

=begin comment

 Title   : _assign_inode_ycoord
 Usage   : $root->_assign_inode_ycoord();
 Function: Get y coords of internal nodes based on OTU position (see _assign_otu_ycoord)
 Returns : none
 Args    : none

=end comment 

=cut

# Determines position of an internal node (halfway between all its children). Recursive.
sub _assign_inode_ycoord {
    my $self = shift;

    my @tmp;
    for my $child ( @{ $self->get_children() } ) {
        $child->_assign_inode_ycoord() unless ( defined $child->_get_ycoord() );
        push @tmp, $child->_get_ycoord();
    }
    my @sorted = sort { $a <=> $b } @tmp;
    my $high   = pop @sorted;
    my $low    = shift @sorted || $high;
    $self->_set_ycoord( $low + 1 / 2 * ( $high - $low ) );
}

=head2 set_depth

 Title   : set_depth
 Usage   : $root->set_depth();
 Function: Determines depth in tree of every node below this one
 Returns : none
 Args    : This node's depth

=cut

sub set_depth {
    my ( $self, $depth ) = @_;
    $self->{'depth'} = $depth;
    return if $self->is_otu();
    for my $child ( @{ $self->get_children() } ) {
        $child->set_depth( $depth + 1 );
    }
}

=head2 get_depth

 Title   : get_depth
 Usage   : $depth = $node->get_depth();
 Function: Returns the node's depth (number of 'generations' removed from the root) in tree
 Returns : integer representing node's depth
 Args    : none

=cut

sub get_depth {
    my $self = shift;
    return $self->{'depth'};
}

=head2 find_lengths

 Title   : find_lengths
 Usage   : $cladogram = 1 unless $root->find_lengths();
 Function: Tries to determine if branch lengths are present in the tree
 Returns : 1 if lengths are found, 0 if not
 Args    : none

=cut

sub find_lengths {
    my $self   = shift;
    my $length = $self->get_length();
    return 1 if ( $length || ( $length = 0 ) );
    for my $child ( @{ $self->get_children() } ) {
        return 1 if $child->find_lengths();
    }
    return 0;
}

=head2 mrca

 Title     : mrca
 Usage     : $mrca = $otu1-> mrca($otu2, $treename);
 Function  : Finds most recent common ancestor of otu1 and otu2
 Returns   : Node object of most recent common ancestor
 Args      : Nexus object, two otu objects, name of tree to look in

=cut

sub mrca {
    my ( $otu1, $otu2, $treename ) = @_;
    if ( not $otu1->is_otu and not $otu2->is_otu ) {
    	Bio::NEXUS::Util::Exceptions::ObjectMismatch->throw(
    		'error' => "the mrca method to calculate most recent\n"
    				. "common ancestor can be performed only on\n"
    				. "an OTU node and also requires another OTU\n"
    				. "node (target) as input argument"
    	);
    }

    my $currentnode = $otu1;
    my @ancestors;
    my $mrca;
    until ( $currentnode->get_name() eq 'root' ) {
        $currentnode = $currentnode->get_parent();
        push( @ancestors, $currentnode );
    }
    $currentnode = $otu2;
    until ( $currentnode->get_name() eq 'root' ) {
        $currentnode = $currentnode->get_parent();
        for my $inode (@ancestors) {
            if ( $inode eq $currentnode ) {
                return $inode;
            }
        }
    }
}

=head2 get_mrca_of_otus

 Title     : get_mrca_of_otus
 Usage     : $mrca = $root->get_mrca_of_otus(\@otus);
 Function  : Finds most recent common ancestor of set of OTUs
 Returns   : Node object of most recent common ancestor
 Args      : Nexus object, two otu objects, name of tree to look in

=cut

sub get_mrca_of_otus {

# Not yet implemented completely. Still in the testing mode -- Vivek Gopalan 10MAR2007.
# Used in assigning meaning inode names to gene tree based on species tree and species names of the OTUs of the inodes.
# Note: Internal nodes can also be given as input instead of the OTU to find the mrca;

    my ($self, $otus, $ancestors ) = @_;
    $ancestors ||= [];
    my @inp_otus = @{$otus};
    my $node_otus =[];
    $self->walk($node_otus);
    my $eq_count = 0 ;
    foreach my $inp_otu (@inp_otus) {
	    if ( grep {$_->get_name eq $inp_otu} @{$node_otus}) {
		    $eq_count++;
		    last if $eq_count == scalar @inp_otus;
	    }
	    #print "$inp_otu $eq_count\n";
    }
    if ($eq_count == scalar @inp_otus) {
	    #print Dumper $ancestors;
	    push @{$ancestors}, $self;
	    foreach my $child ( @{$self->get_children} ) {
		    next if $child->is_otu;
		    $child->get_mrca_of_otus($otus, $ancestors);
	    }
	    #print $self->get_name, "," , $eq_count, ", ", scalar @inp_otus, "\n";
    if (scalar @{$ancestors}) {
	    return $ancestors->[$#{$ancestors}];
    }
    }
    return;

}

sub AUTOLOAD {
	return if $AUTOLOAD =~ /DESTROY$/;
    my $package_name = 'Bio::NEXUS::Node::';

    # The following methods are deprecated and are temporarily supported
    # via a warning and a redirection
    my %synonym_for = (
        "${package_name}depth"       => "${package_name}get_depth",
        "${package_name}boot"        => "${package_name}get_support_value",
        "${package_name}_parse_boot" => "${package_name}_parse_support_value",
        "${package_name}set_boot"    => "${package_name}set_support_value",
        "${package_name}name"        => "${package_name}get_name",
        "${package_name}children"    => "${package_name}get_children",
        "${package_name}length"      => "${package_name}get_length",
        "${package_name}seq"         => "${package_name}get_seq",
        "${package_name}distance"    => "${package_name}get_distance",
        "${package_name}xcoord"      => "${package_name}_get_xcoord",
        "${package_name}ycoord"      => "${package_name}_get_ycoord",
        "${package_name}set_xcoord"  => "${package_name}_set_xcoord",
        "${package_name}set_ycoord"  => "${package_name}_set_ycoord",
        "${package_name}parent_node" => "${package_name}get_parent",
        "${package_name}isOTU"       => "${package_name}is_otu",
        "${package_name}walk_OTUs"   => "${package_name}_walk_otus",
        "${package_name}rearrange"   => "${package_name}_rearrange",
        "${package_name}parse"       => "${package_name}_parse_newick",
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

################## NHXCmd adapter functions ###############

=head2 contains_nhx_tag

Title   : contains_nhx_tag
Usage   : $node_obj->_contains_nhx_tag($tag_name)
Function: Checks if a given tag exists
Returns : 1 if the tax exists, 0 if it doesn't
Args    : $tag_name - a string representation of a tag

=cut

sub contains_nhx_tag {
    my ( $self, $tag_name ) = @_;
    if ( defined $self->{_nhx_obj} ) {
        return $self->{_nhx_obj}->contains_tag($tag_name);
    }

}    # end of sub

=head2 get_nhx_tags

Title   : get_nhx_tags
Usage   : $node_obj->get_nhx_tags(); 
Function: Reads and returns an array of tags
Returns : An array of tags
Args    : None

=cut

sub get_nhx_tags {
    my ($self) = @_;
    if ( defined $self->{_nhx_obj} ) {
        return $self->{_nhx_obj}->get_tags();
    }
    else {
        return ();
    }
}

=head2 get_nhx_values 

Title   : get_nhx_values
Usage   : $node_obj->get_nhx_values($tag_name);
Function: Returns the list of values associated with a given tag ($tag_name)
Returns : Array of values
Args    : $tag_name - a string representation of the tag

=cut

sub get_nhx_values {
    my ( $self, $tag_name ) = @_;

    if ( defined $self->{_nhx_obj}
        && $self->{_nhx_obj}->contains_tag($tag_name) )
    {
        return $self->{_nhx_obj}->get_values($tag_name);
    }
    else {
        return ();
    }
}

=head2 set_nhx_tag

Title   : set_nhx_tag
Usage   : node_obj->set_nhx_tag($tag_name, $tag_reference);
Function: Updates the list of values associated with a given tag
Returns : Nothing
Args    : $tag_name - a string, $tag_reference - an array-reference

=cut

sub set_nhx_tag {
    my ( $self, $tag_name, $tag_values ) = @_;
	if ( not defined $tag_name || not defined $tag_values ) {
		Bio::NEXUS::Util::Exceptions::BadArgs->throw(
			'error' => "tag_name or tag_values is not defined"
		);
	}
	if ( ref $tag_values ne 'ARRAY' ) {
		Bio::NEXUS::Util::Exceptions::BadArgs->throw(
			'error' => 'tag_values is not an array reference'
		);
	}
    $self->{_nhx_obj} = new Bio::NEXUS::NHXCmd
        unless ( defined $self->{_nhx_obj} );
    $self->{_nhx_obj}->set_tag( $tag_name, $tag_values );

}

=head2 add_nhx_tag_value

Title   : add_nhx_tag_value
Usage   : $node_obj->add_nhx_tag_value($tag_name, $tag_value);
Function: Adds a new tag/value set to the $nhx_obj;
Returns : Nothing
Args    : $tag_name - a string, $tag_reference - an array-reference

=cut

sub add_nhx_tag_value {
    my ( $self, $tag_name, $tag_value ) = @_;

    $self->{_nhx_obj} = new Bio::NEXUS::NHXCmd
        unless ( defined $self->{_nhx_obj} );
    return $self->{_nhx_obj}->add_tag_value( $tag_name, $tag_value );

}

=head2 delete_nhx_tag

Title   : delete_nhx_tag
Usage   : $node_obj->delete_nhx_tag($tag_name);
Function: Removes a given tag (and the associated valus) from the $nhx_obj
Returns : Nothing
Args    : $tag_name - a string representation of the tag

=cut

sub delete_nhx_tag {
    my ( $self, $tag_name ) = @_;
    if ( defined( $self->{_nhx_obj} ) ) {
        $self->{_nhx_obj}->delete_tag($tag_name);
    }

}

=head2 delete_all_nhx_tags

Title   : delete_all_nhx_tags
Usage   : $node_obj->delete_all_nhx_tags();
Function: Removes all tags from $nhx_obj
Returns : Nothing
Args    : None

=cut

sub delete_all_nhx_tags {
    my ($self) = @_;

    $self->{_nhx_obj}->delete_all_tags() if defined $self->{_nhx_obj};
}

=head2 nhx_command_to_string 

Title   : nhx_command_to_string
Usage   : $node_obj->nhx_command_to_string();
Function: As NHX command string
Returns : NHX command string
Args    : None

=cut

sub nhx_command_to_string {
    my ($self) = @_;
    if ( defined $self->{_nhx_obj} ) {
        return $self->{_nhx_obj}->to_string();
    }
    else {
        return undef;
    }
}

=head2 clone_nhx_command

Title   : clone_nhx_command
Usage   : $some_node_obj->clone_nhx_command($original_node);
Function: Copies the data of the NHX command of the $original_node object into the NHX command of the $some_node_obj
Returns : Nothing
Args    : $original_node - Bio::NEXUS::NHXCmd object whose NHX command data will be cloned

=cut

sub clone_nhx_command {
    my ($self) = @_;
    if ( defined $self->{_nhx_obj} ) {
        return $self->{_nhx_obj}->clone();
    }
    else {
        return undef;
    }

}

=head2 check_nhx_tag_value_present

Title   : check_nhx_tag_value
Usage   : $boolean = nhx_obj->check_nhx_tag_value($tag_name, $value);
Function: check whether a particular value is present in a tag
Returns : 0 or 1 [ true or false]
Args    : $tag_name - a string, $value - scalar (string or number)

=cut

sub check_nhx_tag_value_present {
    my ( $self, $tag_name, $tag_value ) = @_;


    return $self->{_nhx_obj}->check_tag_value_present( $tag_name, $tag_value )
        if defined $self->{_nhx_obj};
}

=head2 set_nhx_obj

Title   : set_nhx_obj
Usage   : $node->set_nhx_obj($nhx_obj);
Function: Sets Bio::NEXUS::NHXCmd object associated with this node
Returns : Nothing
Args    : Reference of the NHXCmd object
othing

=cut

sub set_nhx_obj {
    my ( $self, $nhx_obj ) = @_;
    $self->{_nhx_obj} = $nhx_obj;
}

=head2 get_nhx_obj

Title   : get_nhx_obj
Usage   : $nhx_obj = get_nhx_obj();
Function: Returns Bio::NEXUS::NHXCmd object associated with this node
Returns : Reference of the NHXCmd object
Args    : Nothing

=cut

sub get_nhx_obj {
    my ($self) = @_;
    return $self->{_nhx_obj};
}

1;
