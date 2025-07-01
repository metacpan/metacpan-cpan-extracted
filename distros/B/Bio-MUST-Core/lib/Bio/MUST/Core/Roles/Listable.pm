package Bio::MUST::Core::Roles::Listable;
# ABSTRACT: Listable Moose role for objects with implied id lists
$Bio::MUST::Core::Roles::Listable::VERSION = '0.251810';
use Moose::Role;

use autodie;
use feature qw(say);

use Smart::Comments '###';

use Carp;
use Const::Fast;
use Date::Format;
use List::AllUtils qw(nsort_by rev_nsort_by);
use POSIX qw(ceil floor);
use Statistics::Descriptive;

use Bio::MUST::Core::Types;
use Bio::MUST::Core::Constants qw(:seqids);

requires 'all_seq_ids';


# IdList factory methods


# alias for std_list emphasizing its use as a lookup
sub new_lookup {
    return shift->_list_from_seq_ids(0);
}


sub std_list {
    return shift->_list_from_seq_ids(0);
}


sub alphabetical_list {
    return shift->_list_from_seq_ids(1);
}

sub _list_from_seq_ids {
    my $self = shift;
    my $sort = shift;

    my @ids = map { $_->full_id } $self->all_seq_ids;
    @ids = sort @ids if $sort;          # optionally sort list
    return Bio::MUST::Core::IdList->new( ids => \@ids );
}

around qw(complete_seq_list len_mapper) => sub {
    my $method = shift;
    my $self   = shift;

    # ensure that seqs are available (e.g., the object is an Ali)
    unless ( $self->can('all_seqs') ) {
        carp '[BMC] Warning: cannot proceed without seqs; returning undef!';
        return;
    }

    return $self->$method(@_);
};


sub desc_seq_len_list {
    my $self = shift;
    return $self->complete_seq_list(0);     # explicit 0 for clarity
}


sub complete_seq_list {
    my $self    = shift;
    my $min_res = shift;

    # sort seqs in desc order according to their (non-missing) length
    # Note: accessor call is optimized
    my @seqs = rev_nsort_by { $_->nomiss_seq_len } $self->all_seqs;

    # optionally truncate list
    if ($min_res) {

        # take max seq length from first seq
        my $max_len = $seqs[0]->nomiss_seq_len;

        # convert fractional min_res to conservative integer (if needed)
        $min_res = ceil($min_res * $max_len)
            if 0 < $min_res && $min_res < 1;

        # filter out seqs with less than min_res non-missing chars
        # Note: this might seem inefficient but results in clearer code
        @seqs = List::AllUtils::before {
            $_->nomiss_seq_len < $min_res
        } @seqs;
    }

    # get ids from ordered (and possibly truncated list)
    my @ids = map { $_->full_id } @seqs;

    # in scalar context return bare IdList
    my $list = Bio::MUST::Core::IdList->new( ids => \@ids );
    return $list unless wantarray;

    # in list context further return the corresponding lengths
    # Note: consider recycling old code below for efficiency
    my @lens = map { $_->nomiss_seq_len } @seqs;
    return ($list, \@lens);
}

# old code (maybe faster but more complex and without sort)

# sub complete_seq_list {
#     my $self    = shift;
#     my $min_res = shift;
#
#     # get (non-missing char) lengths of all seqs and record max_len
#     my @lengths = map { $_->nomiss_seq_len } $self->all_seqs;
#     my $max_len = List::AllUtils::max @lengths;
#
#     # convert fractional min_res to conservative integer (if needed)
#     $min_res = ceil($min_res * $max_len)
#         if 0 < $min_res && $min_res < 1;
#
#     # filter out seqs with less than min_res non-missing chars
#     my @ids = map { $_->full_id } $self->all_seq_ids;
#     my @indices = grep { $lengths[$_] >= $min_res } 0..$#ids;
#
#     return Bio::MUST::Core::IdList->new( ids => [ @ids[@indices] ] );
# }

around qw(long_branch_list) => sub {
    my $method = shift;
    my $self   = shift;

    # ensure that tips are available (e.g., the object is a Tree)
    unless ( $self->can('tree') ) {
        carp '[BMC] Warning: cannot proceed without a tree; returning undef!';
        return;
    }

    return $self->$method(@_);
};


sub asc_br_len_list {
    my $self = shift;
    return $self->long_branch_list( { %{ shift // {} }, iqr_fact => 0 } );
}       # explicitly disable list truncation but leave other args "as is"

# Note: very naive approach and not applicable in practice.
# Should probably use the derivative of branch length increase in log space.
# Meanwhile: use treeshrink


sub long_branch_list {
    my $self = shift;
    my $args = shift // {};             # HashRef (should not be empty...)

    my $iqr_fact = $args->{iqr_fact};
    my $to_root  = $args->{to_root};

    # TODO: consider caching lengths if too slow with calc_path_to_root
    my $method = 'get_branch_length';
    if ($to_root) {
        $method = 'calc_path_to_root';
        carp '[BMC] Warning: tree should be rooted for distances to root!'
            unless $self->tree->is_rooted;
    }

    # sort tips in desc order according to their branch length
    # Note: accessor call is optimized
    my @tips = nsort_by { $_->$method }
        @{ $self->tree->get_terminals };

    # optionally truncate list
    # TODO: check if this makes sense with calc_path_to_root
    if ($iqr_fact) {

        # define threshold using `iqr_fact` x IQR beyond Q3
        my $stat = Statistics::Descriptive::Full->new;
           $stat->add_data( [ map { $_->$method } @tips ] );
        my ($q1, $q3) = ( $stat->quantile(1), $stat->quantile(3) );
        #### $q1
        #### $q3
        #### iqr: $q3-$q1
        #### $iqr_fact
        my $threshold = $q3 + $iqr_fact * ($q3 - $q1);
        #### $threshold

        # filter out tips with branch length over the threshold
        # Note: this might seem inefficient but results in clearer code
        @tips = List::AllUtils::after_incl {
            $_->$method > $threshold
        } @tips;
    }

    # get ids from ordered (and possibly truncated list)
    my @ids = map {
        Bio::MUST::Core::SeqId->new( full_id => $_->get_name )->full_id
    } @tips;

    # in scalar context return bare IdList
    my $list = Bio::MUST::Core::IdList->new( ids => \@ids );
    return $list unless wantarray;

    # in list context further return the corresponding branch lengths
    # Note: consider recycling old code below for efficiency
    my @lens = map { $_->$method } @tips;
    return ($list, \@lens);
}

# old code (maybe faster but more complex and without sort)

# sub long_leaf_list {
#     my $self = shift;
#     my $fact = shift // 1.5;
#
#     my @tips = @{ $self->tree->get_terminals };
#
#     # compute terminal branch length distribution
#     my @lengths = map { $_->get_branch_length } @tips;
#     #### list: sort { $a <=> $b } @lengths
#     my $stat = Statistics::Descriptive::Full->new;
#        $stat->add_data( \@lengths );
#
#     my ($q1, $q3) = ( $stat->quantile(1), $stat->quantile(3) );
#     #### $q1
#     #### $q3
#     #### iqr: $q3-$q1
#     #### $fact
#     my $threshold = $q3 + $fact * ($q3 - $q1);
#     #### $threshold
#
#     my @seq_ids =  map { SeqId->new( full_id => $_->get_name ) }
#                   grep { $_->get_branch_length > $threshold    } @tips;
#
#     #### n: scalar @seq_ids
#     return IdList->new( ids => \@seq_ids );
# }

# IdMapper factory methods


sub std_mapper {
    my $self   = shift;
    my $args   = shift // {};           # HashRef (should not be empty...)

    my $prefix = $args->{id_prefix} // 'seq';
    my $offset = $args->{offset}    // 0;

    my @seq_ids = $self->all_seq_ids;
    return Bio::MUST::Core::IdMapper->new(
        long_ids => [ map { $_->full_id  }              @seq_ids ],  # list
        abbr_ids => [ map { $prefix . ($_+$offset) } 1..@seq_ids ],  # scalar
    );
}

sub acc_mapper {
    my $self   = shift;
    my $prefix = shift // q{};

    # Note: this mapper could fail with non-GenBank Seqs
    my @seq_ids = $self->all_seq_ids;
    return Bio::MUST::Core::IdMapper->new(
        long_ids => [ map {           $_->full_id   } @seq_ids ],
        abbr_ids => [ map { $prefix . $_->accession } @seq_ids ],
    );
}


sub len_mapper {
    my $self = shift;

    my @seq_ids = $self->all_seq_ids;
    my @lengths = map { $_->nomiss_seq_len } $self->all_seqs;
    return Bio::MUST::Core::IdMapper->new(
        long_ids => [ map { $_->full_id . '@' . shift @lengths } @seq_ids ],
        abbr_ids => [ map { $_->full_id                        } @seq_ids ],
    );
}


sub regex_mapper {                          ## no critic (RequireArgUnpacking)
    my $self   = shift;
    # my $prefix = shift // q{};    # note the currying below
    # my $regex  = shift // $DEF_ID;

    my @long_ids = map { $_->full_id             } $self->all_seq_ids;
    my @abbr_ids = map { $_->abbr_with_regex(@_) } $self->all_seq_ids;

    return Bio::MUST::Core::IdMapper->new(
        long_ids => \@long_ids,
        abbr_ids => \@abbr_ids
    );
}


sub org_mapper_from_long_ids {
    my $self   = shift;
    my $mapper = shift;             # mapper long_org => abbr_org

    my @long_ids;
    my @abbr_ids;

    ID:
    for my $seq_id ( $self->all_seq_ids ) {
        next ID if $seq_id->is_foreign;     # needed to skip already abbr_ids

        push @long_ids, $seq_id->full_id;
        push @abbr_ids, $mapper->abbr_id_for( $seq_id->full_org )
                . '|' . $seq_id->accession;
    }

    return Bio::MUST::Core::IdMapper->new(
        long_ids => \@long_ids,
        abbr_ids => \@abbr_ids
    );
}


sub org_mapper_from_abbr_ids {
    my $self   = shift;
    my $mapper = shift;             # mapper long_org => abbr_org

    my @long_ids;
    my @abbr_ids;

    ID:
    for my $seq_id ( $self->all_seq_ids ) {
        my $abbr_id = $seq_id->full_id;
        my ($abbr_org, $accession) = split /\|/xms, $abbr_id, 2;
        next ID unless $accession;          # needed to skip already long_ids

        push @long_ids, $mapper->long_id_for($abbr_org) . '@' . $accession;
        push @abbr_ids, $abbr_id;
    }

    return Bio::MUST::Core::IdMapper->new(
        long_ids => \@long_ids,
        abbr_ids => \@abbr_ids
    );
}


const my $NBS_ID_LEN => 79;

sub store_nbs {
    my $self    = shift;
    my $outfile = shift;

    # #Sequences extracted from c111_78.ali of the 5 May 2009 at 11 hours 40
    # #File c111_78.nbs created on Tuesday 5 May 2009 at 11 hours 40
    # #184 positions remain on the 184 aligned positions
    # #life.col,life.nom
    # #Here is the list of the 78 species used:
    # Aciduliprofundum_boonei_T469___________________________________________________  Aeropyrum_pernix_K1____________________________________________________________
    # Archaeoglobus_fulgidus_DSM_4304________________________________________________  Archaeoglobus_profundus_Av18__DSM_5631_________________________________________
    # ...

    my @ids = $self->all_seq_ids;

    open my $out, '>', $outfile;

    # print minimum header
    print {$out} "#File $outfile created on " . ctime(time);
    say   {$out} '#Here is the list of the ' . scalar @ids . ' species used:';

    # print padded ids on two columns
    for my $i (0..$#ids) {
        my $id = $ids[$i]->foreign_id;
        my $pad_id = $id . '_' x ($NBS_ID_LEN - length $id);
        my $term = $i % 2 ? "\n" : q{  };
        print {$out} $pad_id . $term;
    }
    say {$out} q{};

    close $out;

    return;
}

no Moose::Role;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Core::Roles::Listable - Listable Moose role for objects with implied id lists

=head1 VERSION

version 0.251810

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 METHODS

=head2 new_lookup

=head2 std_list

=head2 alphabetical_list

=head2 desc_seq_len_list

=head2 complete_seq_list

=head2 asc_br_len_list

=head2 long_branch_list

=head2 std_mapper

=head2 acc_mapper

=head2 len_mapper

=head2 regex_mapper

=head2 org_mapper_from_long_ids

=head2 org_mapper_from_abbr_ids

=head2 store_nbs

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
