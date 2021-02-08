package Bio::MUST::Apps::Debrief42::OrgReport;
# ABSTRACT: Internal class for tabular tax-report parser
# CONTRIBUTOR: Mick VAN VLIERBERGHE <mvanvlierberghe@doct.uliege.be>
$Bio::MUST::Apps::Debrief42::OrgReport::VERSION = '0.210370';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

use Bio::MUST::Core;
use aliased 'Bio::MUST::Core::SeqId';
use aliased 'Bio::MUST::Apps::Debrief42::TaxReport';


has 'org' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);


has '_new_seqs_by_' . $_ => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      =>
        'HashRef[ArrayRef[Bio::MUST::Apps::Debrief42::TaxReport::NewSeq]]',
    required => 1,
    handles  => {
                    'all_' . $_ . 's'    => 'keys',
            'new_seqs_by_' . $_ . '_for' => 'get',
        'all_new_seqs_by_' . $_          => 'values',
    },
) for qw(outfile acc);


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Apps::Debrief42::OrgReport - Internal class for tabular tax-report parser

=head1 VERSION

version 0.210370

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

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
