package Bio::FastParsers::Uclust;
# ABSTRACT: front-end class for UCLUST parser
# CONTRIBUTOR: Amandine BERTRAND <amandine.bertrand@doct.uliege.be>
$Bio::FastParsers::Uclust::VERSION = '0.180330';
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

Bio::FastParsers::Uclust - front-end class for UCLUST parser

=head1 VERSION

version 0.180330

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 ATTRIBUTES

=head2 file

Path to UCLUST report file to be parsed

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
