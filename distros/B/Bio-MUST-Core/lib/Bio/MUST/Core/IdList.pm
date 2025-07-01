package Bio::MUST::Core::IdList;
# ABSTRACT: Id list for selecting specific sequences
$Bio::MUST::Core::IdList::VERSION = '0.251810';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

# use Smart::Comments;

use Carp;

use Bio::MUST::Core::Types;
use Bio::MUST::Core::Constants qw(:files);
use aliased 'Bio::MUST::Core::SeqId';
use aliased 'Bio::MUST::Core::Ali';
with 'Bio::MUST::Core::Roles::Commentable',
     'Bio::MUST::Core::Roles::Listable';


# public array
has 'ids' => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Types::full_ids',
    default  => sub { [] },
    coerce   => 1,
    writer   => '_set_ids',
    handles  => {
        count_ids => 'count',
          all_ids => 'elements',
          add_id  => 'push',
          get_id  => 'get',
    },
);


# private hash for faster querying
has '_index_for' => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef[Num]',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_index_for',
    handles  => {
      count_indices   => 'count',
            is_listed => 'defined',
            index_for => 'get',
        set_index     => 'set',
    },
);


## no critic (ProhibitUnusedPrivateSubroutines)

# Note: we don't store SeqId objects in the list but dynamically build them
# to benefit from SeqId methods (e.g., auto-removal of first '_'). This is
# the most flexible approach without costing too much in CPU-time.

sub _build_index_for {
    my $self = shift;

    # build private hash from internal array
    my $i = 0;
    return { map { $_->full_id => $i++ }  $self->all_seq_ids };
}

## use critic

after 'add_id' => sub {
    my $self = shift;

    # check if there are indeed ids not yet in private hash
    # Note: this might not be the case when adding ids in an empty list
    my $n = $self->count_ids;
    my $i = $self->count_indices;
    return if $n == $i;

    # update private hash from internal array
    $self->set_index(
             map { $_->full_id => $i++ } ($self->all_seq_ids)[$i..$n-1]
    );
    return;
};


sub all_seq_ids {
    my $self = shift;
    return map { SeqId->new( full_id => $_ ) } $self->all_ids;
}



sub negative_list {
    my $self     = shift;
    my $listable = shift;

    # filter out seq ids that are in the original list
    my @ids = map { $_->full_id } $listable->all_seq_ids;
    return $self->new( ids => [ grep { not $self->is_listed($_) } @ids ] );
}


# IdList-based Ali factory methods


sub reordered_ali {                         ## no critic (RequireArgUnpacking)
    return shift->_ali_from_list_(1, @_);
}



sub filtered_ali {                          ## no critic (RequireArgUnpacking)
    return shift->_ali_from_list_(0, @_);
}


sub _ali_from_list_ {
    my $self    = shift;
    my $reorder = shift;
    my $ali     = shift;
    my $lookup  = shift;        # optional IdList indexing the Ali

    # override passed lookup with internal lookup if available
    # Note: this allows Stash lookups to be used transparently
    $lookup = $ali->lookup if $ali->can('lookup');

    # TODO: warn for missing ids in Ali?

    # create new Ali object (extending header comment)
    # TODO: allow custom comments
    my $new_ali = Ali->new(
        comments => [ $ali->all_comments,
            'built by ' . ($reorder ? 'reordered_ali' : 'filtered_ali')
        ],
    );

    # case 1: use lookup when available
    if (defined $lookup) {
        ### Using lookup...

        # get slot list from lookup
        # Note1: Since this list follows the list in $self it is 'reordered'.
        # We thus sort it by ascending slot if the Ali order must be kept.
        # Note2: We go through SeqId objects to correctly handle MUST ids
        my @ids = map { $_->full_id } $self->all_seq_ids;
        my @slots = $lookup->index_for(@ids);
           @slots = sort { $a <=> $b } @slots unless $reorder;

        # populate new Ali with deep copies of Seqs in slot list
        $new_ali->add_seq( $ali->get_seq($_)->clone ) for @slots;
    }

    # case 2: scan all seqs to find those that are listed
    else {

        SEQ:
        for my $seq ($ali->all_seqs) {
            next SEQ unless $self->is_listed($seq->full_id);

            # add Seq to new Ali honoring either IdList order...
            if ($reorder) {
                $new_ali->set_seq(
                    $self->index_for($seq->full_id), $seq->clone
                );
                next SEQ;
            }

            # ...or original Ali order
            $new_ali->add_seq($seq->clone);
        }

        # when reordering an Ali, ensure that new Ali does not contain
        # empty slots due to some missing ids in the original Ali
        $new_ali->_set_seqs(
            [ $new_ali->filter_seqs( sub { defined } ) ]
        ) if $reorder;
    }

    return $new_ali;
}


# I/O methods


sub load {
    my $class  = shift;
    my $infile = shift;
    my $args   = shift // {};           # HashRef (should not be empty...)

    my $col = $args->{column}    // 0;
    my $sep = $args->{separator} // qr{\t}xms;

    open my $in, '<', $infile;

    my $list = $class->new();

    my @ids;

    LINE:
    while (my $line = <$in>) {
        chomp $line;

        # skip empty lines and process comment lines
        next LINE if $line =~ $EMPTY_LINE
                  || $list->is_comment($line);

        my @fields = split $sep, $line;
        push @ids, $fields[$col];
    }

    $list->_set_ids( \@ids );

    return $list;
}



sub load_lis {
    my $class  = shift;
    my $infile = shift;

    open my $in, '<', $infile;

    my $list = $class->new();

    my $count;
    my @ids;

    LINE:
    while (my $line = <$in>) {
        chomp $line;

        # skip empty lines and process comment lines
        next LINE if $line =~ $EMPTY_LINE
                  || $list->is_comment($line);

        # read id count as first lone number if not yet defined
        if (!defined $count && $line =~ $COUNT_LINE) {
            $count = $line;
            next LINE;
        }

        push @ids, $line;
    }

    $list->_set_ids( \@ids );

    carp '[BMC] Warning: id list size does not match id count in header!'
        unless $list->count_ids == $count;

    return $list;
}



sub store {
    my $self = shift;
    my $outfile = shift;

    open my $out, '>', $outfile;

    print {$out} $self->header;
    say {$out} join "\n", $self->all_ids;

    close $out;

    return;
}



sub store_lis {
    my $self = shift;
    my $outfile = shift;

    open my $out, '>', $outfile;

    print {$out} $self->header;
    say {$out} $self->count_ids;
    say {$out} join "\n", $self->all_ids;

    close $out;

    return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Core::IdList - Id list for selecting specific sequences

=head1 VERSION

version 0.251810

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 METHODS

=head2 all_seq_ids

=head2 negative_list

=head2 reordered_ali

=head2 filtered_ali

=head2 load

=head2 load_lis

=head2 store

=head2 store_lis

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
