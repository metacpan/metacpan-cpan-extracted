package Bio::MUST::Core::Tree;
# ABSTRACT: Thin wrapper around Bio::Phylo trees
$Bio::MUST::Core::Tree::VERSION = '0.180140';
use Moose;
# use MooseX::SemiAffordanceAccessor;
use namespace::autoclean;

use autodie;
use feature qw(say);

use Smart::Comments;

use Carp;
use File::Basename;
use List::AllUtils qw(uniq);
use Tie::IxHash;

use Bio::Phylo::IO qw(parse);

use Bio::MUST::Core::Types;
use Bio::MUST::Core::Constants qw(:files);
use aliased 'Bio::MUST::Core::SeqId';
with 'Bio::MUST::Core::Roles::Commentable',
     'Bio::MUST::Core::Roles::Listable';


has 'tree' => (
    is       => 'ro',
    isa      => 'Maybe[Bio::Phylo::Forest::Tree]',
    default  => undef,
    writer   => '_set_tree',
);


# Note: we don't store SeqId objects in the tree but dynamically build them
# to benefit from SeqId methods (e.g., auto-removal of first '_'). This is
# the most flexible approach without costing too much in CPU-time.


sub all_seq_ids {
    my $self = shift;

    # old code:
    #     my @tips = @{ $self->tree->get_terminals };
    #     my @full_ids = map { $_->get_name } @tips;
    #     return map { SeqId->new(full_id => $_) } @full_ids;

    # Note1: we use a slower visitor method to ensure that the id array
    # is sorted as when displayed by TreeDrawer methods
    # Note2: this order is consistent with FigTree display as well, but not
    # with Seaview (and njplot) renderings

    my @full_ids;

    $self->tree->visit_depth_first(
        # collect tip names and convert them to SeqIds
        -pre => sub {
            my $node = shift;
            if ($node->is_terminal) {
                push @full_ids, SeqId->new( full_id => $node->get_name );
            }
            return;
        },
     );

    return @full_ids;
}


# NODE-LABEL EDITING METHODS


sub shorten_ids {                           ## no critic (RequireArgUnpacking)
    return shift->_change_ids_(1, @_);
}


sub restore_ids {                           ## no critic (RequireArgUnpacking)
    return shift->_change_ids_(0, @_);
}


sub _change_ids_ {
    my $self      = shift;
    my $abbr      = shift;
    my $id_mapper = shift;

    # update only terminal nodes
    for my $tip ( @{ $self->tree->get_terminals } ) {
        my $seq_id = SeqId->new( full_id => $tip->get_name );
        my $new_id = $abbr ? $id_mapper->abbr_id_for( $seq_id->full_id )
                           : $id_mapper->long_id_for( $seq_id->full_id );
        $tip->set_name($new_id) if $new_id;
    }                       # Note: leave id alone if not found

    return;
}


sub switch_attributes_and_labels_for_terminals {    ## no critic (RequireArgUnpacking)
    return shift->_switch_attributes_and_labels_(0, @_);
}


sub switch_attributes_and_labels_for_internals {    ## no critic (RequireArgUnpacking)
    return shift->_switch_attributes_and_labels_(1, @_);
}


sub switch_attributes_and_labels_for_entities {     ## no critic (RequireArgUnpacking)
    return shift->_switch_attributes_and_labels_(2, @_);
}


sub _switch_attributes_and_labels_ {
    my $self = shift;
    my $mode = shift;
    my $key  = shift;

    # TODO: investigate options of Bio::Phylo::Unparsers::Newick

    # update either terminal or internal nodes
    my $tree = $self->tree;
    my @nodes = @{
        $mode == 2 ? $tree->get_entities  :
        $mode == 1 ? $tree->get_internals :
                     $tree->get_terminals
    };

    # Note: old labels are backuped in specified attributes and vice-versa
    # TODO: allow appending acc for terminal nodes?
    for my $node (@nodes) {
        my $label     = $node->get_name;
        my $attribute = $node->get_generic($key);
        $node->set_generic($key => $label);
        $node->set_name($attribute);
    }

    return;
}


sub switch_branch_lengths_and_labels_for_entities {
    my $self = shift;

    # use branch lengths as labels
    my $tree = $self->tree;
    for my $node ( @{ $tree->get_internals } ) {
        $node->set_name($node->get_branch_length);
    }

    # delete branch lengths
    for my $node ( @{ $tree->get_entities } ) {
        $node->set_branch_length(undef);
    }

    return;
}


sub collapse_subtrees {
    my $self = shift;
    my $key  = shift // 'taxon_collapse';

    # compute maximal path length (from root)
    my $tree_max_path = $self->tree->get_root->calc_max_path_to_tips;

    # "balanced"-order tree traversal
    my $collapsed;      # will be defined when within a collapsed subtree
    $self->tree->visit_depth_first(

        # collapse subtrees with identical attributes
        -pre_daughter => sub {
            my $node = shift;
            return if $node->is_terminal;

            # reset collapsing for robustness
            $node->set_generic('!collapse' => undef);

            # do not further collapse children of a collapsed subtree
            # to facilitate interactive uncollapsing (e.g., in FigTree)
            return if $collapsed;

            # collect children attributes
            my @attrs;
            for (my $i = 0; my $child = $node->get_child($i); $i++) {
                push @attrs, $child->get_generic($key);
            }

            # collapse subtree if all attributes are defined and identical
            return if List::AllUtils::any { not defined $_ } @attrs;
            return if uniq(@attrs) > 1;

            # compute and set FigTree's "node height" for collapsed clade
            # Note: the tallest tip will be 0
            my $sub_max_path = $node->calc_max_path_to_tips
                             + $node->calc_path_to_root;
            my $node_height = $tree_max_path - $sub_max_path;
            $node->set_generic('!collapse' => qq|{"collapsed",$node_height}|);

            # set "within a collapsed subtree" status
            $collapsed = $node->get_id;

            return;
        },

        -post_daughter => sub {
            my $node = shift;
            return if $node->is_terminal;

            # unset "within a collapsed subtree" status (when leaving subtree)
            $collapsed = undef
                if defined $collapsed && $collapsed eq $node->get_id;

            return;
        },
     );

    return;
}


# TREE-MATCHING METHODS


# TODO1: need for a taxon pruning sub as it seems that the -keep option
# TODO1: of Bio::Phylo Newick parser does not work completely
# TODO2: need for a rerooting sub that completely works!

sub match_branch_lengths {
    my $self    = shift;
    my $other   = shift;                # second tree

    my $tree1 = $self->tree;
    my $tree2 = $other->tree;
    tie my %blens_for, 'Tie::IxHash';

    for my $tree ($tree1, $tree2) {
        for my $node ( @{ $tree->get_entities } ) {

            # compute clade key and store corresponding branch length
            my $clade_key
                = join '::',
                  sort { $a cmp $b }
                  map { $_->get_internal_name } @{ $node->get_terminals }
            ;
            my $branch_length = $node->get_branch_length;
            push @{ $blens_for{$clade_key} },
                $branch_length if defined $branch_length;
        }
    }

    # ensure that bipartitions matching proceeded as expected
    carp 'Warning: cannot match all bipartitions; returning useless hash!'
        unless List::AllUtils::all {
            @{ $blens_for{$_} } == 2
        } keys %blens_for;

    return \%blens_for;
}


# I/O METHODS


sub load {
    my $class  = shift;
    my $infile = shift;

    open my $in, '<', $infile;

    my $tree = $class->new();
    my $newick_str;

    LINE:
    while (my $line = <$in>) {
        chomp $line;

        # skip empty lines and process comment lines
        next LINE if $line =~ $EMPTY_LINE
                  || $tree->is_comment($line);

        $newick_str .= $line;
    }

    my $forest = parse(-format => 'newick', -string => $newick_str);
    $tree->_set_tree($forest->first);

    return $tree;
}


# Note: it seems that to_newick automatically replace spaces by '_' in node
# labels (ids), which is a quite reasonable behavior.

# TODO: define better API for outputting branch lengths/support values
# TODO: use constants for to_newick parameters



sub store {
    my $self    = shift;
    my $outfile = shift;
    my $args    = shift // {};          # HashRef (should not be empty...)

    # TODO: consider allowing this hash for all store methods?

    $args->{-nodelabels} //= 1;         # default to nodelabels on

    open my $out, '>', $outfile;
    say {$out} _clean_newick_str( $self->tree->to_newick( %$args ) );

    return;
}


sub store_figtree {
    my $self    = shift;
    my $outfile = shift;

    # transfer taxon names for internals only
    # this is needed to avoid double naming of tips (std label + taxon)
    for my $node ( @{ $self->tree->get_internals } ) {
        my $taxon = $node->get_generic('taxon');
        $node->set_generic('!name' => qq|"$taxon"|) if $taxon;
    }   # Note: get_generic does not return undef, hence: if $taxon

    # build mesquite-enabled Newick string
    my $newick_str = $self->tree->to_newick(
        -nodelabels => 1,
#         -blformat => '%.10f',
        -nhxkeys    => [ '!name', '!color', '!collapse' ],
        -nhxstyle   => 'mesquite',
    );

    # ... and adapt it for FigTree
    $newick_str =~ s{\[%}{[&}xmsg;

    # ... then restore zero-valued bootstrap values
    # since 'false' internal names are converted to 'NodeNNN' strings
    $newick_str =~ s{\b Node\d+ \b}{0}xmsg;
    # TODO: consider doing that also in the standard store?

    open my $out, '>', $outfile;

    # output minimal NEXUS tree file
    print {$out} <<"EOF";
#NEXUS

begin trees;
    tree tree_1 = [&R] $newick_str
end;
EOF

    return;
}


sub store_arb {
    my $self    = shift;
    my $outfile = shift;
    my $args    = shift // {};          # HashRef (should not be empty...)

    my $alifile = $args->{alifile};

    # optionally link to Ali (without path)
    if ($alifile) {
        my ($basename, $dir, $ext) = fileparse($alifile, qr{\.[^.]*}xms);
        $self->insert_comment("$basename$ext");
    }

    # build standard Newick string
    my $newick_str = _clean_newick_str(
        $self->tree->to_newick( -nodelabels => 0 )
    );

    open my $out, '>', $outfile;

    # output ARB tree file
    print {$out} $self->header;
    say {$out} $newick_str;

    return;
}


sub store_grp {
    my $self    = shift;
    my $outfile = shift;

    # extract tip ids, non-root nodes and support values
    my @tip_ids =  map {     $_->foreign_id  }    $self->all_seq_ids;
    my @nodes   = grep { not $_->is_root     } @{ $self->tree->get_internals };
    my @bp_vals =  map {     $_->get_name    } @nodes;

    # determine support value type (BP or PP)
    my $pp = List::AllUtils::all { $_ >= 0.0 && $_ <= 1.0 } @bp_vals;

    open my $out, '>', $outfile;

    for my $node (@nodes) {

        # build bipartition string
        my %in_bip = map {
            SeqId->new( full_id => $_->get_name )->foreign_id => 1
        } @{ $node->get_terminals };
        my $bip = join q{}, map { $in_bip{$_} ? '*' : '.' } @tip_ids;

        # fetch (and possibly fix) support value for bipartition
        my $support = shift @bp_vals;
           $support = int( $support * 100.0 ) if $pp;

        # write bipartition line
        say {$out} "$bip  $support";
    }

    return;
}


sub store_tpl {
    my $self    = shift;
    my $outfile = shift;

    # backup and discard branch lengths
    # Note: I have to do that since I cannot clone the tree (Bio::Phylo bug?)
    my @branch_lengths;
    for my $node ( @{ $self->tree->get_entities } ) {
        push @branch_lengths, $node->get_branch_length;
        $node->set_branch_length(undef);
    }

    open my $out, '>', $outfile;

    # output topology
    say {$out} '1';     # TODO: improve this for multiple topologies
    say {$out} _clean_newick_str(
        $self->tree->to_newick( -nodelabels => 0 )
    );

    # restore branch lengths
    for my $node ( @{ $self->tree->get_entities } ) {
        $node->set_branch_length( shift @branch_lengths );
    }

    return;
}


sub _clean_newick_str {
    my $newick_str = shift;

    # remove quotes...
    # ...and trailing zero-length branch length (RAxML) if any
    $newick_str =~ tr{'"}{}d;
    $newick_str =~ s{:0\.0+;}{;}xmsg;

    return $newick_str;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Core::Tree - Thin wrapper around Bio::Phylo trees

=head1 VERSION

version 0.180140

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 METHODS

=head2 all_seq_ids

=head2 shorten_ids

=head2 restore_ids

=head2 switch_attributes_and_labels_for_terminals

=head2 switch_attributes_and_labels_for_internals

=head2 switch_attributes_and_labels_for_entities

=head2 switch_branch_lengths_and_labels_for_entities

=head2 collapse_subtrees

=head2 match_branch_lengths

=head2 load

=head2 store

=head2 store_figtree

=head2 store_arb

=head2 store_grp

=head2 store_tpl

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
