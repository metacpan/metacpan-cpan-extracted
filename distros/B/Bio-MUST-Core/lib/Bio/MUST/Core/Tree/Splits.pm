package Bio::MUST::Core::Tree::Splits;
# ABSTRACT: Tree splits (bipartitions)
$Bio::MUST::Core::Tree::Splits::VERSION = '0.251810';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

use Carp;
use List::AllUtils qw(max_by zip_by);
use Regexp::Common;
use Scalar::Util qw(looks_like_number);

use Smart::Comments '###';

use Bio::MUST::Core::Types;
use aliased 'Bio::MUST::Core::IdList';
use aliased 'Bio::MUST::Core::SeqId';
use aliased 'Bio::MUST::Core::Tree';


# public attributes

has 'rep_n' => (
    is       => 'ro',
    isa      => 'Maybe[Int]',
    lazy     => 1,
    builder  => '_build_rep_n',
);

has 'lookup' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::IdList',
    required => 1,
    handles  => qr{.*}xms,      # expose all IdList methods (and attributes)
);

# private attributes

has '_bp_for' => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef[Str]',
    lazy     => 1,
    default  => sub { {} },
    writer   => '_set_bp_for',
    handles  => {
            bp_for  => 'get',
        all_bp_keys => 'keys',
        all_bp_vals => 'values',
    },
);

has '_comp_bp_for' => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef[Str]',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_comp_bp_for',
    handles  => {
            comp_bp_for  => 'get',
        all_comp_bp_keys => 'keys',
    },
);

## no critic (ProhibitUnusedPrivateSubroutines)

sub _build_rep_n {
    my $self = shift;

    # check for non-numeric node metadata
    if (List::AllUtils::any { !looks_like_number $_ } $self->all_bp_vals) {
        carp '[BMC] Warning: node metadata are not all numeric!';
        return;
    }

    # determine number of replicates from max BP value
    my $max_bp = List::AllUtils::max $self->all_bp_vals;
    carp '[BMC] Warning: max BP value (rep_n) is nor 1 nor a multiple of 10!'
        if $max_bp != 1 && $max_bp % 10;

    return $max_bp;
}

sub _build_comp_bp_for {
    my $self = shift;

    my %comp_bp_for = map {
        ( tr/.*/*./r ) => $self->bp_for($_)
    } $self->all_bp_keys;

    return \%comp_bp_for;
}

## use critic


sub ids2key {
    my $self = shift;
    my $ids  = shift;
    # TODO: handle array?

    my $bp_key = q{.} x $self->count_ids;

    ID:
    for my $seq_id ( @{$ids} ) {

        # get id from SeqId or full_id
        unless ( $seq_id->can('full_id') ) {
            $seq_id = SeqId->instance( full_id => $seq_id );
        }

        # get index for seq_id
        my $id = $seq_id->full_id;
        my $index = $self->index_for($id);
        unless (defined $index) {
            carp "[BMC] Warning: $id missing from id list; ignoring!";
            next ID;
        }

        # put star for corresponding id
        substr $bp_key, $index, 1, q{*};
    }

    return $bp_key;
}


sub key2ids {
    my $self   = shift;
    my $bp_key = shift;

    my @seq_ids = map {
        SeqId->instance( full_id => $self->get_id($_) )
    } _indices($bp_key, q{*});

    # TODO: handle wantarray?
    return \@seq_ids;
}


sub node2key {
    my $self = shift;
    my $node = shift;

    #### $node
    #### r: $node->is_root
    #### t: $node->is_terminal
    #### n: $node->get_name

    # skip root (as it includes all tips)
    return if $node->is_root;

    # skip trivial bipartitions
    my @tips = @{ $node->get_terminals };
    #### @tips
    # Note: also handle keys for trivial splits (for rooting on single OTUs)
    # return if @tips < 2 || ( $self->count_ids - @tips ) < 2;
    #### n2k: join qq{\n}, q{}, map { $_->get_name } @tips

    return $self->ids2key( [ map { $_->get_name } @tips ] );
}


sub is_a_clan {
    my $self   = shift;
    my $bp_key = shift;

    return  1 if $self->bp_for(     $bp_key);       #      standard clan (*)
    return -1 if $self->comp_bp_for($bp_key);       # complementary clan (.)

    return;                                         # undef if not found
}


sub clan_support {
    my $self   = shift;
    my $bp_key = shift;

    my $support   = $self->bp_for(     $bp_key);    #      standard clan (*)
       $support //= $self->comp_bp_for($bp_key);    # complementary clan (.)

    return $support;                                # silent undef if not found
}


sub sub_clans {
    my $self   = shift;
    my $bp_key = shift;

    # TODO: use some bit masking approach instead of explicit indices?
    my %is_wanted = map { $_ => 1 } _indices($bp_key, q{*});

    my @sub_clans;
    for (my $size = keys(%is_wanted) - 1; $size > 1; $size--) {
        push @sub_clans,
            grep { List::AllUtils::all { $is_wanted{$_} } _indices($_, q{*}) }
            grep { tr/*// == $size }
                $self->all_bp_keys,                 #      standard clans (*)
                $self->all_comp_bp_keys             # complementary clans (.)
        ;
    }   # examine clans of target size and keep those including only wanted ids

    # TODO: handle wantarray?
    return @sub_clans;
}


my %xor_for = (
    '..' => '.',
    '.*' => '*',
    '*.' => '*',
    '**' => '.',
);

sub xor_clans {                             ## no critic (RequireArgUnpacking)
    return join q{},
        zip_by { $xor_for{"$_[0]$_[1]"} } map { [ split // ] } @_[1..2];
}


sub get_node_for_split {
    my $self   = shift;
    my $tree   = shift;
    my $bp_key = shift;

    # transparently fetch Bio::Phylo component object
    # TODO: avoid code repetition?
    $tree = $tree->tree if $tree->isa('Bio::MUST::Core::Tree');

    my $comp_bp_key = $bp_key =~ tr/.*/*./r;

    NODE:
    for my $node ( @{ $tree->get_entities } ) {
        my $node_key = $self->node2key($node);
        next NODE unless $node_key;
        return $node if $node_key eq $bp_key || $node_key eq $comp_bp_key;
    }

    carp "[BMC] Warning: cannot find split with key: $bp_key; returning undef";

    return;
}


sub score_split {
    my $self   = shift;
    my $filter = shift;
    my $bp_key = shift;

    #### $bp_key
    my $comp_bp_key = $bp_key =~ tr/.*/*./r;
    #### 1: join qq{\n}, q{}, map { $_->full_id } @{ $self->key2ids(     $bp_key) }
    #### 2: join qq{\n}, q{}, map { $_->full_id } @{ $self->key2ids($comp_bp_key) }

    # compute score...
    my ($score1, $seen1) = $filter->score( @{ $self->key2ids(     $bp_key) } );
    my ($score2, $seen2) = $filter->score( @{ $self->key2ids($comp_bp_key) } );
    # ... considering both possible split keys (standard and complementary)
    my $score = List::AllUtils::max( $score1 - $score2, $score2 - $score1 );
    #### $score

    # Note: the following would be useful to decorate nodes with scores...
    # ... but it would not work for terminals!
    # $self->_bp_for->{$bp_key} = $score;

    # TODO: warn only once?
    carp '[BMC] Warning: filter could not match any seq id!'
        unless $seen1 || $seen2;

    return $score;
}


sub get_split_that_maximizes {
    my $self   = shift;
    my $filter = shift;

    # return split for which method yields the highest value
    my $split = max_by { $self->score_split($filter, $_) } $self->all_bp_keys,
        $self->_trivial_bp_keys;        # also consider single seqs
    # Note: scalar context to get only one node!
    # TODO: handle ties to allow for additional criteria

    return $split;
}

sub _indices {
    my $haystack = shift;
    my $needle   = shift;

    my @indices;

    my $pos = 0;
    while ( ($pos = index($haystack, $needle, $pos)) >= 0 ) {
        push @indices, $pos++;
    }   # Note: 0-based indices to match IdList (lookup) slots

    return @indices;
}

sub _trivial_bp_keys {
    my $self = shift;

    my @bp_keys;

    # build all possible trivial keys (one per OTU)
    my $id_n = $self->count_ids;
    for my $index (0..$id_n-1) {
        my $bp_key = q{.} x $id_n;
        substr $bp_key, $index, 1, q{*};
        push @bp_keys, $bp_key;
    }

    return @bp_keys;
}


# I/O METHODS


# refactored from parse_consense_out.pl

sub load_consense {
    my $class  = shift;
    my $infile = shift;

    open my $in, '<', $infile;

    my $rep_n;
    my @ids;
    my %bp_for;

    LINE:
    while (my $line = <$in>) {
        chomp $line;

        # read number of replicates
        if ($line =~ m/How\ many\ times\ out\ of \s+ ([0-9\.]+)/xms) {
            $rep_n = sprintf '%.0f', $1;        # turn number to integer
        }

        # process OTU line
        # TODO: check robustness here due to consense truncating seq_ids
        if ($line =~ m/\A \s* (\d+) \. \s+ (.*)/xms) {
            my $index = $1;
            my $id = $2;
            $id =~ tr/ /_/;             # replace inner spaces by underscores
            $id =~ s/_+\z//xmsg;        # delete trailing underscores (if any)
            push @ids, $id;             # ignore 1-based index
        }

        # process bipartition line
        if ($line =~ m/\A ([\ .*]+) \s+ (\d+\.\d+) \z/xms) {
           (my $bp_key = $1) =~ tr/ //d;
            my $bp_val = $2;
            $bp_for{$bp_key} = 0 + $bp_val;
        }
    }

    my $splits = $class->new(
        rep_n   => $rep_n,
        lookup  => IdList->new( ids => \@ids ),
        _bp_for => \%bp_for,
    );

    return $splits;
}


# refactored from parse_consense_out.pl

sub load_splits {
    my $class  = shift;
    my $infile = shift;

    open my $in, '<', $infile;

    my @ids;
    my $id_n;
    my %bp_for;

    LINE:
    while (my $line = <$in>) {
        chomp $line;

        # process OTU line
        if ($line =~ m/\A TAXLABELS/xms .. $line =~ m/\A ;/xms) {
            my ($index, $id) = $line =~ m/\A \[ (\d+) \] \s+ \' (\S+) \'/xms;
            push @ids, $id if $index;       # ignore 1-based index
        }

        # process bipartition line
        if ($line =~ m/\A    MATRIX/xms .. $line =~ m/\A ;/xms) {
            my ($bp_val, @indices) = $line =~ m/\b (\d+) \b/xmsg;

            # skip null and trivial bipartitions
            next LINE unless $bp_val;       # new wrt parse_consense_out.pl
            next LINE if @indices < 2;

            # build bipartition from OTU index list
            $id_n //= @ids;                 # only compute once
            my $bp_key = q{.} x $id_n;
            substr( $bp_key, $_-1, 1, q{*} ) for @indices;
            $bp_for{$bp_key} = 0 + $bp_val;
        }
    }

    my $splits = $class->new(
        # no data about rep_n here
        lookup  => IdList->new( ids => \@ids ),
        _bp_for => \%bp_for,
    );

    return $splits;
}


sub load_newick {
    my $class  = shift;
    my $infile = shift;

    # return $class->new_from_newick_str(
    #     Tree->load($infile)->newick_str( -nodelabels => 1 )
    # );  # node labels are needed to recover BP values directly at nodes

    return $class->new_from_tree( Tree->load($infile) );
}

# Note: in principle useless now that new_from_tree is available

# =method new_from_newick_str
#
# =cut
#
# sub new_from_newick_str {
#     my $class = shift;
#     my $str   = shift;
#
#     # TODO: upgrade to handle non-numeric metadata?
#
#     # 1. extract topology (refactored from parse_consense_out.pl' get_topology)
#
#     # strip chars unrelated to topology
#     $str =~ s/_{2,}//xmsg;              # delete series of underscores
#     $str =~ s/: $RE{num}{real}//xmsg;   # delete branch lengths (if any)
#
#     # restrict str to topology (not fool-proof for bad trees, really needed?)
#     my ($tpl) = $str
#         =~ m/\A .*? ($RE{balanced}{-parens=>'()'} $RE{num}{real}? ;) /xms;
#
#     unless ($tpl) {
#         carp '[BMC] Warning: unable to extract topology from tree string;'
#             . ' returning undef!';
#         return;
#     }
#
#     # 2. build OTU index (refactored from pco's get_species_hash)
#     # TODO: consider refactoring using Tree::std_list?
#
#     # extract OTU list from topology str
#     # Note1: for this BP values must be first deleted (+look-behind assert)
#     # Note2: we also trim surrounding whitespace for each OTU
#     # Note3: but Newick str is assumed to be already stripped of quotes
#     ( my $bare_tpl = $tpl ) =~ s/(?<=\)) $RE{num}{real}//xmsg;
#     my $lookup = IdList->new( ids => [
#         map { $RE{ws}{crop}->subs($_) } split q{,}, $bare_tpl =~ tr/();//dr
#     ] );
#     my $id_n = $lookup->count_ids;
#
#     # 3. build splits hash (refactored from pco's read_tree)
#     my %bp_for;
#     my @bp_keys;
#
#     # parse topology
#     my $chunk;
#     my $char = substr $tpl, 0, 1;
#
#     CHUNK:
#     while ($char ne q{;}) {
#         $chunk = 1;                     # defaults to advancing one char
#
#         # skip commas and spaces
#         if ($char =~ m/[,\s]/xms) {
#             next CHUNK;
#         }
#
#         # open new bipartition
#         if ($char eq q{(}) {
#             my $bp_key =q {.} x $id_n;
#             push @bp_keys, $bp_key;
#             next CHUNK;
#         }
#
#         # close most recently opened bipartition
#         if ($tpl =~ m/\A \) $RE{num}{real}{-keep}?/xms) {
#
#             # handle optional bootstrap support values
#             my $bp_val = $1 // 1;       # defaults to 1 if no support
#             $chunk += length $1 if defined $1;
#
#             # throw error if not balanced parentheses
#             unless (@bp_keys) {
#                 carp '[BMC] Warning: unbalanced parentheses in tree string;'
#                     . ' returning undef!';
#                 return;
#             }
#
#             # store bipartition...
#             my $bp_key = pop @bp_keys;
#             my $star_n = $bp_key =~ tr/*//;
#             # ... skipping full tree and trivial bipartitions
#             $bp_for{$bp_key} = 0 + $bp_val if $star_n > 1 && $star_n < $id_n;
#             next CHUNK;
#         }
#
#         # process OTU id
#         # TODO: consider using a variation of $FULL_ID to match this?
#         if ($tpl =~ m/\A ([A-Za-z0-9_\@\-\.\ \#]+)/xms) {
#
#             # put stars for corresponding OTU in all open bipartitions
#             my $seq_id = SeqId->new( full_id => $1 );
#             my $offset = $lookup->index_for( $seq_id->full_id );
#             substr $bp_keys[$_], $offset, 1, q{*} for 0..$#bp_keys;
#             $chunk = length $1;
#             next CHUNK;
#         }
#
#         # throw error if anything else found than expected cases
#         carp "[BMC] Warning: unexpected char in tree string: '$char';"
#             . ' returning undef!';
#         return;
#     }
#
#     continue {
#         # advance in topology string
#         substr $tpl, 0, $chunk, q{};
#
#         # read next char
#         $char = substr $tpl, 0, 1;
#     }
#
#     my $splits = $class->new(
#         # no data about rep_n here
#         lookup  => $lookup,
#         _bp_for => \%bp_for,
#     );
#
#     return $splits;
# }


sub new_from_tree {
    my $class = shift;
    my $tree  = shift;

    # transparently fetch Bio::Phylo component object
    # TODO: avoid code repetition?
    $tree = $tree->tree if $tree->isa('Bio::MUST::Core::Tree');

    # build lookup as fast as possible (no tree visitor method)
    my $lookup = IdList->new(
        ids => [ map { $_->get_name } @{ $tree->get_terminals } ]
    );

    # instantiate Splits object to benefit from ids2key method
    my $splits = $class->new(
        # no data about rep_n here
        lookup  => $lookup,
    );

    # compute bipartitions and store node metadata
    my %bp_for;

    NODE:
    for my $node ( @{ $tree->get_internals } ) {
        my $bp_key = $splits->node2key($node);
        next NODE unless $bp_key;

        $bp_for{$bp_key} = $node->get_name || 1;    # defaults to "seen"
    }

    # TODO: handle rooted trees where the root has a BP value but not children
    # e.g., mullidae-well-rooted.tre

    # complete Splits object
    $splits->_set_bp_for( \%bp_for );

    return $splits;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Core::Tree::Splits - Tree splits (bipartitions)

=head1 VERSION

version 0.251810

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 METHODS

=head2 ids2key

=head2 key2ids

=head2 node2key

=head2 is_a_clan

=head2 clan_support

=head2 sub_clans

=head2 xor_clans

=head2 get_node_for_split

=head2 score_split

=head2 get_split_that_maximizes

=head2 load_newick

=head2 new_from_tree

=head1 I/O METHODS

=head2 load_consense

=head2 load_splits

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
