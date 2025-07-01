package Bio::MUST::Core::Ali::Stash;
# ABSTRACT: Thin wrapper for an indexed Ali read from disk
$Bio::MUST::Core::Ali::Stash::VERSION = '0.251810';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

use Smart::Comments;

use Carp;

use Bio::MUST::Core::Types;
use Bio::MUST::Core::Constants qw(:seqids);
use aliased 'Bio::MUST::Core::Ali';

# ATTRIBUTES


has 'seqs' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Ali',
    required => 1,
    handles  => [
        qw(filename count_comments all_comments get_comment
            guessing all_seq_ids has_uniq_ids is_protein is_aligned
            get_seq first_seq all_seqs filter_seqs count_seqs
            gapmiss_regex
        )
    ],      # comment-related methods needed by IdList
);


has 'lookup' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::IdList',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_lookup',
    handles  => [ qw(index_for) ],
);

with 'Bio::MUST::Core::Roles::Aliable';

## no critic (ProhibitUnusedPrivateSubroutines)

sub _build_lookup {
    return shift->seqs->new_lookup;
}

## use critic

# ACCESSORS


sub get_seq_with_id {
    my $self = shift;
    my $id   = shift;

    # override Ali method with faster lookup-based alternative
    my $index = $self->index_for($id);
    return $self->get_seq($index)
        if defined $index;

    carp "[BMC] Warning: cannot find seq with id: $id; returning undef!";
    return;
}

# I/O methods


sub load {
    my $class  = shift;
    my $infile = shift;
    my $args   = shift // {};           # HashRef (should not be empty...)

    my $seqs = Ali->load($infile);
       $seqs->dont_guess;

    if ( $args->{truncate_ids} ) {
        my $mapper = $seqs->regex_mapper( q{}, $DEF_ID );
        $seqs->shorten_ids($mapper);
    }

    return $class->new(seqs => $seqs);
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Core::Ali::Stash - Thin wrapper for an indexed Ali read from disk

=head1 VERSION

version 0.251810

=head1 SYNOPSIS

    #!/usr/bin/env perl

    use Modern::Perl '2011';
    # same as:
    # use strict;
    # use warnings;
    # use feature qw(say);

    use Bio::MUST::Core;
    use aliased 'Bio::MUST::Core::Ali::Stash';
    use aliased 'Bio::MUST::Core::IdList';

    # load database
    my $db = Stash->load('database.fasta');

    # process OrthoFinder-like output file
    # where each line defines a cluster followed by its member sequences
    # cluster1: seq3 seq7 seq2
    # cluster2: seq1 seq4 seq6 seq5
    # ...

    open my $in, '<', 'clusters.txt';
    while (my $line = <$in>) {
        chomp $line;

        # extract member id list for current cluster
        my ($cluster, @ids) = split /\s+/xms, $line;
        $cluster =~ s/:\z//xms;             # remove trailing colon (:)
        my $list = IdList->new( ids => \@ids );

        # assemble Ali and store it as FASTA file
        my $ali = $list->reordered_ali($db);
           $ali->dont_guess;
        $ali->store( $cluster . '.fasta' );
    }

=head1 DESCRIPTION

This module implements a class representing a sequence database where ids are
indexed for faster access. To this end, it combines an internal
L<Bio::MUST::Core::Ali> object and a L<Bio::MUST::Core::IdList> object.

An Ali::Stash is meant to be built from an existing ALI (or FASTA) file
residing on disk and cannot be altered once loaded. Its sequences are supposed
not to be aligned but aligned FASTA files are also processed correctly. By
default, the full-length sequence ids are indexed. If the first word of each
id (non-whitespace containing string or accession) is unique across the
database, it can be used instead via the option C<<truncate_ids => 1>> of the
C<load> method (see the SYNOPSIS for an example).

While this class is more efficient than the standard C<Ali>, it is way slower
at reading large sequence databases than specialized external programs such as
NCBI C<blastdbcmd> working on indexed binary files. Thus, if you need more
performance, have a look at the C<Blast::Database> class from the
L<Bio::MUST::Drivers> distribution.

=head1 ATTRIBUTES

=head2 seqs

L<Bio::MUST::Core::Ali> object (required)

This required attribute contains the L<Bio::MUST::Core::Seq> objects that
populate the associated sequence database file. It should be initialized
through the class method C<load> (see the SYNOPSIS for an example).

For now, it provides the following methods: C<count_comments>,
C<all_comments>, C<get_comment>, C<guessing>, C<all_seq_ids>, C<has_uniq_ids>,
C<is_protein>, C<is_aligned>, C<get_seq>, C<get_seq_with_id> (see below),
C<first_seq>, C<all_seqs>, C<filter_seqs> and C<count_seqs> (see
L<Bio::MUST::Core::Ali>).

=head2 lookup

L<Bio::MUST::Core::IdList> object (auto)

This attribute is automatically initialized with the list indexing the
sequence ids of the internal C<Ali> object. Thus, it cannot be user-specified.

It provides the following method: C<index_for> (see
L<Bio::MUST::Core::IdList>). Yet, it is nearly a private method. Instead,
individual sequences should be accessed through the C<get_seq_with_id> method
(see below), while sequence batches should be recovered via user-specified
IdList objects (see the SYNOPSIS for an example).

=head1 ACCESSORS

=head2 get_seq_with_id

Returns a sequence of the Ali::Stash by its id. Note that sequence ids are
assumed to be unique in the corresponding database. If no sequence exists for
the specified id, this method will return C<undef>.

    my $id = 'Pyrus malus_3750@658052655';
    my $seq = $db->get_seq_with_id($id);
    croak "Seq $id not found in Ali::Stash!" unless defined $seq;

This method accepts just one argument (and not an array slice).

It is a faster implementation of the same method from the C<Ali> class.

=head1 I/O METHODS

=head2 load

Class method (constructor) returning a new Ali::Stash read from disk. As in
C<Ali>, this method will transparently import plain FASTA files in addition to
the MUST pseudo-FASTA format (ALI files).

    # load database
    my $db = Stash->load( 'database.fasta' );

    # alternatively... (indexing only accessions)
    my $db = Stash->load( 'database.fasta', { truncate_ids => 1 } );

This method requires one argument and accepts a second optional argument
controlling the way sequence ids are processed. It is a hash reference that
may only contain the following key:

    - truncate_ids: consider only the first id word (accession)

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
