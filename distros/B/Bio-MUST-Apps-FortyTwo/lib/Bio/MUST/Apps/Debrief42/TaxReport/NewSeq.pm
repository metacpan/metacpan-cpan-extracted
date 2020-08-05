package Bio::MUST::Apps::Debrief42::TaxReport::NewSeq;
# ABSTRACT: Internal class for tabular tax-report parser
# CONTRIBUTOR: Mick VAN VLIERBERGHE <mvanvlierberghe@doct.uliege.be>
$Bio::MUST::Apps::Debrief42::TaxReport::NewSeq::VERSION = '0.202160';
use Moose;
use namespace::autoclean;


# public attributes

has $_ => (
    is       => 'ro',
    isa      => 'Maybe[Str]',
    required => 1,
) for qw( seq_id contam_org lca lineage acc seq );

has $_ => (
    is       => 'ro',
    isa      => 'Maybe[Num]',
    required => 1,
) for qw( top_score rel_n mean_len mean_ident start end strand );

has 'outfile' => (
    is       => 'ro',
    isa      => 'Str',
);



sub heads {
    my $class = shift;

    return qw(
        seq_id contam_org
        top_score
        rel_n mean_len mean_ident lca lineage
        acc start end strand seq
    );  # Note: outfile attr is added by TaxReport parser!
}


sub stringify {
    my $self = shift;
    return join "\t", map { $self->$_ // q{} } $self->heads;
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Apps::Debrief42::TaxReport::NewSeq - Internal class for tabular tax-report parser

=head1 VERSION

version 0.202160

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 METHODS

=head2 heads

Class method returning all the attribute names (not an array reference).

    use aliased 'Bio::MUST::Apps::Debrief42::TaxReport::NewSeq';

    # $tax_report is an output file
    open my $fh, '>', $tax_report;
    say {$fh} '# ' . join "\t", NewSeq->heads;

This method does not accept any arguments.

=head2 stringify

Returns a string corresponding to NewSeq attribute values. The string is ready
to be printed as a single TaxReport line.

    # $fh is an output filehandle
    say {$fh} $new_seq->stringify;

This method does not accept any arguments.

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTOR

=for stopwords Mick VAN VLIERBERGHE

Mick VAN VLIERBERGHE <mvanvlierberghe@doct.uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
