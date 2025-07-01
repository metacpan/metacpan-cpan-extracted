package Bio::MUST::Core::Taxonomy::Labeler;
# ABSTRACT: Helper class for simple labeler based on taxonomy
$Bio::MUST::Core::Taxonomy::Labeler::VERSION = '0.251810';
use Moose;
use namespace::autoclean;

use Carp;

use Bio::MUST::Core::Types;
with 'Bio::MUST::Core::Roles::Taxable';


has 'labels' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::IdList',
    required => 1,
    coerce   => 1,
    handles  => {
         all_labels => 'all_ids',
        is_a_label  => 'is_listed',
    },
);


sub BUILD {
    my $self = shift;

    # warn in case of ambiguous taxa
    for my $taxon ( $self->all_labels ) {
        carp "[BMC] Warning: $taxon is taxonomically ambiguous in labeler!"
            if $self->tax->is_dupe($taxon);
    }

    return;
}



sub classify {
    my $self   = shift;
    my $seq_id = shift;
    my $args   = shift // {};

    my $greedy = $args->{greedy} // 0;

    my @lineage = $self->tax->fetch_lineage($seq_id);
    while (my $taxon = $greedy ? shift @lineage : pop @lineage) {
        return $taxon if $self->is_a_label($taxon);
    }

    # return undef if no suitable taxon
    return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Core::Taxonomy::Labeler - Helper class for simple labeler based on taxonomy

=head1 VERSION

version 0.251810

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 METHODS

=head2 classify

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
