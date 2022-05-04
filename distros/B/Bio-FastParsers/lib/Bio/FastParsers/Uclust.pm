package Bio::FastParsers::Uclust;
# ABSTRACT: Front-end class for UCLUST parser
# CONTRIBUTOR: Amandine BERTRAND <amandine.bertrand@doct.uliege.be>
$Bio::FastParsers::Uclust::VERSION = '0.221230';
use Moose;
use namespace::autoclean;

use autodie;

use Tie::IxHash;

extends 'Bio::FastParsers::Base';


# public attributes (inherited)


with 'Bio::FastParsers::Roles::Clusterable';


sub BUILD {
    my $self = shift;

    my $infile = $self->filename;
    open my $in, '<', $infile;

    tie my %members_for, 'Tie::IxHash';

    LINE:
    while (my $line = <$in>) {
        chomp $line;
        my ($type, @fields) = split /\t/xms, $line;

        # https://www.drive5.com/usearch/manual/opt_uc.html
        # Field Description
        # - Record type S, H, C or N (see table below).
        # 0 Cluster number (0-based).
        # 1 Sequence length (S, N and H) or cluster size (C).
        # 2 For H records, percent identity with target.
        # 3 For H records, the strand: + or - for nucleotides, . for proteins.
        # 4 Not used, parsers should ignore this field. Included for backwards compatibility.
        # 5 Not used, parsers should ignore this field. Included for backwards compatibility.
        # 6 Compressed alignment or the symbol '=' (equals sign). The = indicates that the query is 100% identical to the target sequence (field 10).
        # 7 Label of query sequence (always present).
        # 8 Label of target sequence (H records only).

        if    ($type eq 'C') {
            push @{ $members_for{ $fields[7] } }, ();
        }
        elsif ($type eq 'H') {
            push @{ $members_for{ $fields[8] } }, $fields[7];
        }
    }

    # store representative and member sequence ids
    $self->_set_members_for( \%members_for );

    return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::FastParsers::Uclust - Front-end class for UCLUST parser

=head1 VERSION

version 0.221230

=head1 SYNOPSIS

    use aliased 'Bio::FastParsers::Uclust';

    # open and parse UCLUST report
    my $infile = 'test/uclust.uc';
    my $report = Uclust->new( file => $infile );

    # loop through representatives to get members
    for my $repr ( $report->all_representatives ) {
        my $members = $report->members_for($repr);
        # ...
    }

    # get representatives ordered by descending cluster size
    my @reprs = $report->all_representatives_by_cluster_size;

    # create IdMapper
    # Note: this requires Bio::MUST::Core
    my $mapper = $report->clust_mapper(':');
    my @long_ids = $mapper->all_long_ids;

    # ...

=head1 DESCRIPTION

This module implements a parser for the output file of the UCLUST program. It
provides methods for getting the ids of the representative sequences (either
sorted by descending cluster size or not) and for obtaining the members of any
cluster from the id of its representative.

It also has a method for facilitating the re-mapping of all the ids of every
cluster on a phylogenetic tree through a L<Bio::MUST::Core::IdMapper> object.

=head1 ATTRIBUTES

=head2 file

Path to UCLUST report file to be parsed

=head1 METHODS

=head2 all_representatives

Returns all the ids of the representative sequences of the clusters (not an
array reference).

    # $report is a Bio::FastParsers::Uclust
    for my $repr ( $report->all_representatives ) {
        # process $repr
        # ...
    }

This method does not accept any arguments.

=head2 all_representatives_by_cluster_size

Returns all the ids of the representative sequences of the clusters (not an
array reference) sorted by descending cluster size (and then lexically by id).

    # $report is a Bio::FastParsers::Uclust
    for my $repr ( $report->all_representatives_by_cluster_size ) {
        # process $repr
        # ...
    }

This method does not accept any arguments.

=head2 members_for

Returns all the ids of the member sequences of the cluster corresponding to
the id of the specified representative (as an array refrence).

    # $report is a Bio::FastParsers::Uclust
    for my $repr ( $report->all_representatives ) {
        my $members = $report->members_for($repr);
        # process $members ArrayRef
        # ...
    }

This method requires one argument: the id of the representative.

=head2 clust_mapper

Returns a L<Bio::MUST::Core::IdMapper> object associating representative
sequence ids to stringified full lists of their member sequence ids (including
the representatives themselves).

This method needs L<Bio::MUST::Core> to be installed on the computer.

    # $report is a Bio::FastParsers::Uclust
    my $mapper = $report->clust_mapper(':');

The native methods from L<Bio::MUST::Core::IdMapper> can be applied on
C<$mapper>, e.g., C<all_long_ids> or C<long_id_for>.

This method accepts an optional argument: the id separator (default: C</>).

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTOR

=for stopwords Amandine BERTRAND

Amandine BERTRAND <amandine.bertrand@doct.uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
