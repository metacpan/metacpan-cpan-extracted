=encoding utf8

=head1 NAME

Bio::BPWrapper::TreeManipulations - Functions for biotree

=head1 SYNOPSIS

    use Bio::BPWrapper::TreeManipulations;
    # Set options hash ...
    initialize(\%opts);
    write_out(\%opts);

=cut

# Package global variables
my ($in, $out, $aln, %opts, $file, $in_format, $out_format, @nodes,
    $tree, $print_tree, $rootnode);

###################### subroutine ######################

package Bio::BPWrapper::TreeManipulations;

use strict;
use warnings;
use v5.10;
use Bio::BPWrapper;
use Bio::TreeIO;
use Bio::Tree::Tree;
use Bio::Tree::Node;
use Data::Dumper;

if ($ENV{'DEBUG'}) { use Data::Dumper }

use vars qw(@ISA @EXPORT @EXPORT_OK);

@ISA         = qw(Exporter);

@EXPORT      = qw(print_tree_shape edge_length_abundance swap_otus getdistance
                  sister_pairs countOTU reroot clean_tree delete_otus initialize
                  write_out);

=head1 SUBROUTINES

=head2 initialize()

Sets up most of the actions to be performed on an alignment.

Call this right after setting up an options hash.

Sets package variables: C<$in_format>, C<@nodes>, C<$tree>, C<$out_format>, and C<$out>.


=cut

sub initialize {
    my $opts_ref = shift;
    Bio::BPWrapper::common_opts($opts_ref);
    %opts = %{$opts_ref};

    $in_format = $opts{"input"} // 'newick';  # This doesn't work...or does it?
    $out_format = $opts{"output"} // "newick";
    $print_tree = 0;    # Trigger printing the tree.
    my $file = shift || "STDIN";

    $in = Bio::TreeIO->new(-format => $in_format, ($file eq "STDIN") ? (-fh => \*STDIN) : (-file => $file));
    $tree = $in->next_tree(); # get the first tree (and ignore the rest)

    $out      = Bio::TreeIO->new(-format => $out_format);
    @nodes    = $tree->get_nodes;
    $rootnode = $tree->get_root_node;
}


sub print_tree_shape {
    my @matrix;
    my (%leaf, %inode);
    my $ct_leaf = 0;
    my $ct_inode = 0;
    for my $nd (@nodes) {
	if ($nd->is_Leaf()) {
	    $leaf{$nd->id} = ++$ct_leaf;
	} else {
	    $inode{$nd->internal_id} = ++$ct_inode;
	}
    }

    for my $nd (@nodes) {
	next if $nd->is_Leaf();
	my @dscs = $nd->each_Descendent;
	die unless @dscs == 2;
	my $id1 = $dscs[0]->is_Leaf
	    ? -1 * $leaf{$dscs[0]->id} : $inode{$dscs[0]->internal_id};
	my $id2 = $dscs[1]->is_Leaf
	    ? -1 * $leaf{$dscs[1]->id} : $inode{$dscs[1]->internal_id};
	if ($nd eq $rootnode) { # root at first
	    unshift @matrix, [ ($id1, $id2) ];
	} else {
	    push @matrix, [ ($id1, $id2) ]
	}
    }
    for (my $i = $#matrix; $i >=0; $i--) {
	print $matrix[$i]->[0], "\t", $matrix[$i]->[1], "\n";
    };
    #    print Dumper(\%leaf, \%inode);
}

sub edge_length_abundance {
    my @inodes;
    my @brs;
    push (@inodes, $_) for _walk_up($rootnode);

    for my $nd (@inodes) {
	next if $nd eq $rootnode;
        my $id = $nd->internal_id;
	my $ct_otus = 0;
        if ($nd->is_Leaf) {
	    $ct_otus = 1;
	} else {
	    foreach (&_each_leaf($nd)) {
		$ct_otus++;
	    }
	}
        push @brs, { 'id' => $id, 'num_tips' => $ct_otus, 'br_len' => $nd->branch_length() }
    }

    my $ct_tips = 0;
    foreach my $nd (@nodes) {
	$ct_tips ++ if $nd->is_Leaf();
    }

    for (my $k=1; $k<=$ct_tips; $k++) {
	my $total = 0;
	my @nds = grep { $_->{num_tips} == $k }  @brs;
	if (@nds) { $total += $_->{br_len} for @nds }
	printf "%d\t%.6f\n", $k, $total/$tree->total_branch_length();
    }
}

sub swap_otus {
    my @otus;
    my $otu_ct = 0;
    foreach (@nodes) {
	next unless $_->is_Leaf();
	push @otus, $_;
	$otu_ct++;
    }
    @otus = sort {$a->id() cmp $b->id() } @otus;
    my $ref_otu;
    if ($opts{'swap-otus'}) {
	$ref_otu = $tree->find_node($opts{'swap-otus'}) || die "node not found\n";
    } else {
	$ref_otu = $otus[0];
    }

    foreach my $nd (@otus) {
	next if $nd eq $ref_otu;
	my $nd_id = $nd->id();
	my $ref_id = $ref_otu->id();
	$nd->id("new_".$ref_id);
	$ref_otu->id("new_".$nd_id);
	say $tree->as_text($out_format);
	$nd->id($nd_id);
	$ref_otu->id($ref_id);
    }
}

# Get the distance between nodes
sub getdistance {
    my @dnodes = _name2node($opts{'distance'});
    if (scalar(@dnodes) != 2) { say "Error: Provide exactly two nodes/leaves to use with --distance" }
    else { say $tree->distance(-nodes => \@dnodes) }
}

sub sister_pairs {
    my @otus;
    my $otu_ct = 0;
    foreach (@nodes) {
	next unless $_->is_Leaf();
	push @otus, $_;
	$otu_ct++;
    }

    @otus = sort {$a->id() cmp $b->id() } @otus;
    for (my $i = 0; $i < $otu_ct; $i++) {
	my $pa_i = $otus[$i]->ancestor();
	for (my $j = $i+1; $j < $otu_ct; $j++) {
	    my $pa_j = $otus[$j]->ancestor();
	    print $otus[$i]->id, "\t", $otus[$j]->id, "\t";
	    print $pa_i eq $pa_j ? 1 : 0;
	    print "\n";
	}
    }
}

=head2 countOTU()

Print total number of OTUs (leaves).

=cut

sub countOTU {
	my $otu_ct = 0;
	foreach (@nodes) { $otu_ct++ if $_->is_Leaf() }
	say $otu_ct
}

=head2 reroot()

Reroot tree to node in C<$opts{'reroot'}> by creating new branch.

=cut

sub reroot {
    my $outgroup_id = $opts{'reroot'};
    my $outgroup    = $tree->find_node($outgroup_id);
    my $newroot     = $outgroup->create_node_on_branch(-FRACTION => 0.5, -ANNOT => {id => 'newroot'});
    $tree->reroot($newroot);
    $print_tree = 1;
}

sub clean_tree {
    foreach my $nd (@nodes) {
	$nd->branch_length(0) if $opts{'cleanbr'};
	if ($opts{'cleanboot'}) {
	    $nd->bootstrap(0);
	    $nd->id('') unless $nd->is_Leaf;
	}
    }
    $print_tree = 1;
}

sub delete_otus {
    my $ref_otus = &_get_otus();
    my @otus_to_retain = &_remove_otus($ref_otus, $opts{'delete-otus'});
#    print Dumper(\@otus_to_retain);
    $opts{'subset'} = join ",", @otus_to_retain;
    &subset();
}

sub _get_otus {
    my @list;
    foreach my $nd (@nodes) { push @list, $nd if $nd->is_Leaf }
    return \@list;
}

sub _remove_otus {
    my $ref = shift;
    my $str = shift;
    my @list;
    my @otus_to_remove = split /\s*,\s*/, $str;

    foreach my $nd (@$ref) {
	foreach my $otu (@otus_to_remove) {
	    push @list, $nd->id() unless $otu eq $nd->id();
	}
    }
    return @list;
}

sub multi2bi {
    foreach my $nd (@nodes) {
#	next if $nd eq $rootnode;
	&_add_node($nd);
    }
    $print_tree = 1;
}

sub _add_node {
    my $node = shift;
#    warn "processing\t", $node->internal_id, "\n";
    my @desc = $node->each_Descendent;
    return if scalar(@desc) <= 2;
#    warn "multifurcating node:\t", $node->internal_id, " ... add a new node\n";
    shift @desc; # retain the first descent
#    my $new_node = $node->create_node_on_branch(-FRACTION => 0.5, -FORCE => 1, -ANNOT=>{ -id => "new_id" });
    my $new_node = Bio::Tree::Node->new(-id => "new", -branch_length => 0);
    $node->add_Descendent($new_node);
#    warn "\ta new node created:\t", $new_node->id, "\n";
    foreach (@desc) {
	$node->remove_Descendent($_); # remove from grand-parent
#	warn "\t\tremove descendant:\t", $_->internal_id, "\n";
	$new_node->add_Descendent($_); # re-attarch to parent
#	warn "\t\tadd descendant to the new node:\t", $_->internal_id, "\n";
    }
    &_add_node($new_node);
}

# Subset a tree
sub subset {
	# Collect the subset of nodes from STDIN or from $_
    my @keep_nodes;
	if ($opts{'subset'}) { @keep_nodes = _name2node($opts{'subset'}) }
	else { my $ar = $_[0]; @keep_nodes = @$ar }

	# Collect list of descendents
    my @descendents;
    for my $nd (@keep_nodes) { push @descendents, $_ for $nd->get_all_Descendents }

    # Collect list of ancestors
    my @ancestors;
    my $tmp;
    for (@keep_nodes) {
	$tmp = $_;
        while ($tmp->ancestor) {
	    push @ancestors, $tmp->ancestor;
	    $tmp = $tmp->ancestor
	}
    }

    # Make a hash of nodes to keep
    my %keep = map { $_->internal_id => $_ } @keep_nodes;
    $keep{$_->internal_id} = $_ for @descendents;
    $keep{$_->internal_id} = $_ for @ancestors;

    # Remove all nodes but those in %keep
    for (@nodes) { $tree->remove_Node($_) unless exists($keep{$_->internal_id}) }

    # Clean up internal single-descendent nodes
    my @desc;
    my $nd_len;
    my $desc_len;
    for my $nd ($tree->get_nodes) {
	next if $nd == $rootnode;
	@desc = $nd->each_Descendent;
	next unless scalar(@desc) == 1;
	$nd_len   = $nd->branch_length()      || 0;
	$desc_len = $desc[0]->branch_length() || 0;
	$desc[0]->branch_length($nd_len + $desc_len);
	$nd->ancestor->add_Descendent($desc[0]);
	$tree->remove_Node($nd)
    }

    # Take care of the a single-descendent root node
    @desc = $rootnode->each_Descendent;
    if (scalar(@desc) == 1) {
	$rootnode->add_Descendent($_) for $desc[0]->each_Descendent;
	$tree->remove_Node($desc[0])
    }
    $print_tree = 1
}

# Print OTU names and lengths
sub print_leaves_lengths {
    foreach (@nodes) { say $_->id(), "\t", $_->branch_length() if $_->is_Leaf() }
}

# Get LCA
sub getlca {
    my @lca_nodes;
	if (_name2node($opts{'lca'})) { @lca_nodes = _name2node($opts{'lca'}) }
	else { my $ar = $_[0]; @lca_nodes = @$ar }
    my @nd_pair;
    my $lca;

    $nd_pair[0] = $lca_nodes[0];
    if (@lca_nodes > 1) {
        for (my $index = 1; $index < @lca_nodes; $index++) {
            $nd_pair[1] = $lca_nodes[$index];
            $lca = $tree->get_lca(-nodes => \@nd_pair);
            $nd_pair[0] = $lca
        }
		if (_name2node($opts{'lca'})) { say $lca->internal_id } else { return $lca }
    } elsif (@lca_nodes == 1) {
		if (_name2node($opts{'lca'})) { say $lca_nodes[0]->ancestor->internal_id }
		else { return $lca_nodes[0]->ancestor->internal_id }
	}
}

# Label nodes with their internal ID's
sub label_nodes {
    for (@nodes) {
        next if $_ == $rootnode;
        my $suffix = defined($_->id) ? "_" . $_->id : "";
        $_->id($_->internal_id . $suffix)
    }
    $print_tree = 1
}

# Print half-tree id distances between all pairs of nodes
sub listdistance {
    my (@leaves, @sortedleaf_names, @leafnames);
    foreach (@nodes) { push(@leaves, $_) if $_->is_Leaf() }

    # Make an alphabetical list of OTU names
    push @sortedleaf_names, $_->id foreach sort {lc($a->id) cmp lc($b->id)} @leaves;

    @leaves = ();

    #Rebuld leaf array with new alphabetical order
    push @leaves, $tree->find_node(-id => $_) foreach @sortedleaf_names;

    # Prints a half-matrix of distance values
    my $i = 1;
    for my $firstleaf (@leaves) {
        my @dnodes;
        for (my $x = $i; $x < scalar(@leaves); $x++) {
            @dnodes = ($firstleaf, $leaves[$x]);
            say join "\t", ($firstleaf->id(), $leaves[$x]->id(), $tree->distance(-nodes => \@dnodes))
        }
        $i++
    }
}

=head2 bin()

Divides tree into number of specified segments and counts branches up
to height the segment. Prints: bin_number, branch_count, bin_floor,
bin_ceiling.

=cut

sub bin {
	my $treeheight = _treeheight(\$tree);
	my $bincount = $opts{'ltt'};
	my $binsize = $treeheight/$bincount;
	my @bins;
	while ($treeheight > 0) {
		unshift @bins, $treeheight;
		$treeheight -= $binsize
	}
	# Handle imperfect division. When approaching 0, if a tiny number is found, such as 2e-17, assign it as 0 and ignore negatives that may follow.
	for (@bins) { shift @bins if $_ < 1e-10 }
	unshift @bins, 0;

	for (my $i=0; $i+1<@bins; $i++) {
		my $branchcount = 1; # branch from root
		# Starting from the root, add a branch for each found descendent
		$branchcount += _binrecursive(\$rootnode, $bins[$i+1]);
		printf "%3d\t%3d\t%.4f\t%.4f\n", $i+1, $branchcount, $bins[$i], $bins[$i+1];
	}
}

sub print_all_lengths{
    for (@nodes) {
        next if $_ == $rootnode;
	my $p_node = $_->ancestor();
	my $p_id = $p_node->id ? $p_node->id : $p_node->internal_id;
	my $c_id = $_->id ? $_->id() : $_->internal_id;
	say $p_id, "\t",  $c_id, "\t", $_->branch_length;
    }
}

sub random_tree{
	my @otus = _each_leaf($rootnode);
	my @sample;
	my $sample_size = $opts{"random"} == 0 ? int(scalar(@otus) / 2) : $opts{"random"};

	die "Error: sample size ($sample_size) exceeds number of OTUs (", scalar(@otus), ")" if $sample_size > scalar(@otus);

	# Use Reservoir Sampling to pick random otus.
	my @sampled = (1 .. $sample_size);
	for ($sample_size + 1 .. scalar(@otus)) {
		$sampled[rand(@sampled)] = $_ if rand() < $sample_size/$_
    }
	push @sample, $otus[--$_] for @sampled;
	&subset(\@sample)
}

# Depth to the root for a node
sub depth_to_root {
    say $_->depth for _name2node($opts{'depth'})
}

# Remove Branch Lenghts
sub remove_brlengths {
    foreach (@nodes) { $_->branch_length(0) if defined $_->branch_length }
    $print_tree = 1
}

sub alldesc {
    my @inodes;
    my $inode_id = $opts{'allchildOTU'};

    if ($inode_id eq 'all') { push (@inodes, $_) for _walk_up($rootnode) }
    else { push @inodes, $tree->find_node(-internal_id => $inode_id) }

    for my $nd (@inodes) {
        print $nd->internal_id, " ";
        if ($nd->is_Leaf) { print $nd->id } else { print $_->id, " " for _each_leaf($nd) }
        print "\n"
    }
}

# Walks from starting OTU
sub walk {
    my $startleaf = $tree->find_node($opts{'walk'});
    my $curnode   = $startleaf->ancestor;
    my $last_curnode = $startleaf;
    my @decs;
    my %visited;
    my $totlen = 0;
    my @dpair;
    my $vcount = 0;

    $visited{$startleaf} = 1;

    while ($curnode) {
        $visited{$curnode} = 1;
        @dpair = ($last_curnode, $curnode);
        $totlen += $tree->distance(-nodes => \@dpair);
        _desclen($curnode, \%visited, \$totlen, \$vcount);
        $last_curnode = $curnode;
        $curnode = $curnode->ancestor
    }
}


=head2 write_out()

Performs the bulk of the actions actions set via
L<C<initialize(\%opts)>|/initialize>.

Call this after calling C<#initialize(\%opts)>.

=cut
sub write_out {
    my $opts = shift;
    getdistance() if $opts->{'distance'};
    say $tree->total_branch_length() if $opts->{'length'};
    countOTU() if $opts->{'numOTU'};
    $print_tree = 1 if defined($opts->{'output'});
    reroot() if $opts->{'reroot'};
    subset() if $opts->{'subset'};
    print_leaves_lengths() if $opts->{'otu'};
    getlca() if $opts->{'lca'};

    label_nodes() if $opts->{'labelnodes'};
    listdistance() if $opts->{'distanceall'};
    bin() if $opts->{'ltt'};
    print_all_lengths() if $opts->{'lengthall'};
    random_tree() if defined($opts->{'random'});
    depth_to_root() if $opts->{'depth'};
    remove_brlengths() if $opts->{'rmbl'};
    alldesc() if $opts->{'allchildOTU'};
    walk() if $opts->{'walk'};
    multi2bi() if $opts->{'multi2bi'};
    clean_tree() if $opts->{'cleanbr'} || $opts->{'cleanboot'};
    delete_otus() if $opts->{'delete-otus'};
    sister_pairs() if $opts->{'sis-pairs'};
    swap_otus() if $opts->{'swap-otus'};
    edge_length_abundance() if $opts->{'ead'};
    print_tree_shape() if $opts->{'tree-shape'};
    say $tree->as_text($out_format) if $print_tree;
}

################# internal subroutines ##############

sub _name2node {
    my $str = shift;
    my @node_names = split /,/, $str;
    my $nd;
    my @node_objects;
    for my $node_name (@node_names) {
        $nd = $tree->find_node(-id => $node_name) || $tree->find_node(-internal_id => $node_name);
        if ($nd) { push @node_objects, $nd } else { say "Node/leaf '$node_name' not found. Ignoring..." }
    }
    return @node_objects
}

# _each_leaf ($node): returns a list of all OTU's descended from this node, if any
sub _each_leaf {
	my @leaves;
	for ($_[0]->get_all_Descendents) { push (@leaves, $_) if $_->is_Leaf }
	return @leaves
}

# main routine to walk up from root
sub _wu {
	my (@lf, @nd);
	my $curnode       = $_[0];
	my @decs          = $_[0]->each_Descendent;
	my $visitref      = $_[1];
	my %visited       = %$visitref;
	my $node_list_ref = $_[2];
#	my $ref_ct_otu    = $_[3];
#	my $ref_tatal_br_len = $_[4];

	for (@decs) {
#	    $ref_total_br_len += $_->branch_length;
	    if ($_->is_Leaf) {
		push @lf, $_;
#		$$ref_ct_otu++;
	    } else {
		push @nd, $_
	    }
	}

	for (@lf) { if (!exists($visited{$_})) { $visited{$_} = 1; push @$node_list_ref, $_ } }
	for (@nd) {
		next if exists($visited{$_});
		$visited{$_} = 1;
		push @$node_list_ref, $_;
		_wu($_, \%visited, $node_list_ref)
	}
}

# Walk Up: "Walks" up from a given node and returned an order array representing the order that each node descended from the given node was visited.
sub _walk_up {
	my %visited;
	my @node_list = $_[0];
	_wu($_[0], \%visited, \@node_list);
	return @node_list
}

sub _treeheight {
	my $height = 0;
	my $tree = $_[0];
	for ($$tree->get_nodes) { $height = $_->depth if $_->depth > $height }
	return $height
}

sub _binrecursive {

    my $branchcount = 0;
    my $noderef = $_[0];
    my $upper = $_[1];
    my @desc = $$noderef->each_Descendent;
    $branchcount-- unless $$noderef->is_Leaf;

    for (@desc) {
	$branchcount++;
	$branchcount += _binrecursive(\$_, $upper) if $_->depth <= $upper
    }
    return $branchcount
}

# Starting at a node that has 2 descendents, print the distance from start to desc if it's a leaf or call itself passing the internal-node descendent
# Input: basenode, internal node
sub _desclen {
    # startlear, curnode
    my (@dpair, @lf, @nd);
    my $curnode   = $_[0];
    my @decs      = $_[0]->each_Descendent;
    my $visitref  = $_[1];
    my $totlen    = $_[2];
    my $vcountref = $_[3];
    my %visited   = %$visitref;
    my $dist;

    for (@decs) { if ($_->is_Leaf) { push @lf, $_ } else { push @nd, $_ } }
    for (@lf) {
	next if exists($visited{$_});
	$visited{$_} = 1;
	$dpair[0] = $curnode;
	$dpair[1] = $_;
	$dist = $tree->distance(-nodes => \@dpair);
	$$totlen += $dist;
	$$vcountref++;
	say	$_->id, "\t$$totlen\t$$vcountref"
    }

    for (@nd) {
	next if exists($visited{$_});
	$visited{$_} = 1;
	$dpair[0] = $curnode;
	$dpair[1] = $_;
	$dist = $tree->distance(-nodes => \@dpair);
	$$totlen += $dist;
	_desclen($_, \%visited, $totlen, $vcountref)
    }
}

1;

__END__

=head1 SEE ALSO

=over 4

=item *

L<bioatree>: command-line tool for using this

=item *

L<Qui Lab wiki page|http://diverge.hunter.cuny.edu/labwiki/Bioutils>

=item *

L<Github project wiki page|https://github.com/bioperl/p5-bpwrapper/wiki>

=back

=head1 CONTRIBUTORS

=over 4

=item *
William McCaig <wmccaig at gmail dot com>

=item *
Girish Ramrattan <gramratt at gmail dot com>

=item  *
Che Martin <che dot l dot martin at gmail dot com>

=item  *
Yözen Hernández yzhernand at gmail dot com

=item *
Levy Vargas <levy dot vargas at gmail dot com>

=item  *
L<Weigang Qiu|mailto:weigang@genectr.hunter.cuny.edu> (Maintainer)

=item *
Rocky Bernstein

=back

=cut
