package Bio::FastParsers::Blast::Table::Hsp;
# ABSTRACT: internal class for tabular BLAST parser
$Bio::FastParsers::Blast::Table::Hsp::VERSION = '0.180330';
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

Bio::FastParsers::Blast::Table::Hsp - internal class for tabular BLAST parser

=head1 VERSION

version 0.180330

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

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
