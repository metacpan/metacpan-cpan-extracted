package Bio::FastParsers::Blast::Table::Hsp;
# ABSTRACT: Internal class for tabular BLAST parser
$Bio::FastParsers::Blast::Table::Hsp::VERSION = '0.201110';
use Moose;
use namespace::autoclean;


# public attributes

has $_ => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
) for qw(query_id hit_id);

has $_ => (
    is       => 'ro',
    isa      => 'Num',
    required => 1,
) for qw(
    percent_identity hsp_length mismatches gaps
    query_from  query_to
      hit_from    hit_to
    query_strand
      hit_strand
    query_start query_end
      hit_start   hit_end
);

has $_ => (
    is       => 'ro',
    isa      => 'Maybe[Num]',
    required => 1,
) for qw(
    evalue bit_score
);



sub expect {
    return shift->evalue
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::FastParsers::Blast::Table::Hsp - Internal class for tabular BLAST parser

=head1 VERSION

version 0.201110

=head1 SYNOPSIS

    # see Bio::FastParsers::Blast::Table

=head1 DESCRIPTION

This class implements a single line of a tabular BLAST report. Such a line
does not correspond to a hit but to a High-Scoring-Pair (HSP). All its methods
are accessors. Beyond the standard fields found in the BLAST tabular output
(e.g., C<hit_id>, C<evalue>), additional methods are available for easier
handling of reverse strand coordinates (e.g., C<query_start>, C<hit_strand>).

=head1 METHODS

=head2 query_id

Returns the id of the query sequence.

This method does not accept any arguments.

=head2 hit_id

Returns the id of the hit (or subject) sequence.

This method does not accept any arguments.

=head2 percent_identity

Returns the identity (in percents) of the HSP.

This method does not accept any arguments.

=head2 hsp_length

Returns the length (in nt or aa) of the HSP.

This method does not accept any arguments.

=head2 mismatches

Returns the number of mismatches of the HSP.

This method does not accept any arguments.

=head2 gaps

Returns the number of gaps (or gap openings) of the HSP.

This method does not accept any arguments.

=head2 query_from

Returns the HSP start in query coordinates. The value of C<query_from> is
higher than the value of C<query_to> on reverse strands.

This method does not accept any arguments.

=head2 query_to

Returns the HSP end in query coordinates. The value of C<query_to> is lower
than the value of C<query_from> on reverse strands.

This method does not accept any arguments.

=head2 hit_from

Returns the HSP start in hit (or subject) coordinates. The value of
C<hit_from> is higher than the value of C<hit_to> on reverse strands.

This method does not accept any arguments.

=head2 hit_to

Returns the HSP end in hit (or subject) coordinates. The value of C<hit_to> is
lower than the value of C<hit_from> on reverse strands.

This method does not accept any arguments.

=head2 evalue

Returns the E-value (or expect) of the HSP.

This method does not accept any arguments.

=head2 bit_score

Returns the score (in bits) of the HSP.

This method does not accept any arguments.

=head2 query_strand

Returns the strand (+1/-1) of the query in the HSP.

This method does not accept any arguments.

=head2 hit_strand

Returns the strand (+1/-1) of the hit in the HSP.

This method does not accept any arguments.

=head2 query_start

Returns the HSP start in query coordinates. The value of C<query_start> is
guaranteed to be lower than the value of C<query_end>.

This method does not accept any arguments.

=head2 query_end

Returns the HSP end in query coordinates. The value of C<query_end> is
guaranteed to be higher than the value of C<query_start>.

This method does not accept any arguments.

=head2 hit_start

Returns the HSP start in hit (or subject) coordinates. The value of
C<hit_start> is guaranteed to be lower than the value of C<hit_end>.

This method does not accept any arguments.

=head2 hit_end

Returns the HSP end in hit (or subject) coordinates. The value of C<hit_end>
is guaranteed to be higher than the value of C<hit_start>.

This method does not accept any arguments.

=head1 ALIASES

=head2 expect

Alias for C<evalue> method. For API consistency.

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
