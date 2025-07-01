package Bio::MUST::Core::Taxonomy::Criterion;
# ABSTRACT: Helper class for multiple-criterion classifier based on taxonomy
$Bio::MUST::Core::Taxonomy::Criterion::VERSION = '0.251810';
use Moose;
use namespace::autoclean;

use List::AllUtils qw(sum count_by);

use Bio::MUST::Core::Types;


has 'tax_filter' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Taxonomy::Filter',
    required => 1,
    handles  => [ qw(is_allowed) ],
);


has 'min_seq_count' => (
    is       => 'ro',
    isa      => 'Num',
    default  => 1,
);


has $_ => (
    is       => 'ro',
    isa      => 'Maybe[Num]',
    default  => undef,
) for qw(              max_seq_count
         min_org_count max_org_count
         min_copy_mean max_copy_mean
);



sub matches {
    my $self     = shift;
    my $listable = shift;

    # case 1: handle classification of single ids

    # this should work for:
    # - SeqId objects
    # - stringified lineages
    # - mere strings
    unless ( ref $listable && $listable->can('all_seq_ids') ) {
        # TODO: make this robust to ArrayRef[] (via coercion)
        return $self->is_allowed($listable);
    }

    # case 2: handle "true" listable objects

    # get seq_ids passing tax_filter
    my @seq_ids = grep { $self->is_allowed($_) } $listable->all_seq_ids;
    my $seq_n = @seq_ids;

    # return success if positively avoided taxa are indeed absent
    unless ($seq_n) {
        return 1
            if ( defined $self->max_seq_count && !$self->max_seq_count )
            || ( defined $self->max_org_count && !$self->max_org_count )
        ;
    }

    # return failure unless #seqs within allowed bounds
    # by default there is no upper bound on #seqs
    return 0 if                                 $seq_n < $self->min_seq_count;
    return 0 if defined $self->max_seq_count && $seq_n > $self->max_seq_count;

    # return success if no more condition for criterion
    # this is optimized for speed
    return 1
        unless defined $self->min_org_count || defined $self->max_org_count
            || defined $self->min_copy_mean || defined $self->max_copy_mean
    ;

    # compute #orgs, #seqs/org and mean(copy/org)
    # these statistics only pertain to seq_ids having passed tax_filter
    my %count_for = count_by { $_->full_org // $_->taxon_id } @seq_ids;
    # Note: use taxon_id if full_org is not defined (for tax-aware abbr ids)
    # this implies that each taxon_id must correspond to a single org
    my $org_n = keys %count_for;
    my $cpy_n = (sum values %count_for) / $org_n;

    # return failure unless #orgs within allowed bounds
    # by default there is no lower nor upper bound on #seqs
    return 0 if defined $self->min_org_count && $org_n < $self->min_org_count;
    return 0 if defined $self->max_org_count && $org_n > $self->max_org_count;

    # return failure unless mean(copy/org) within allowed bounds
    # by default there is no lower nor upper bound on mean(copy/org)
    return 0 if defined $self->min_copy_mean && $cpy_n < $self->min_copy_mean;
    return 0 if defined $self->max_copy_mean && $cpy_n > $self->max_copy_mean;

    # return success
    return 1;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Core::Taxonomy::Criterion - Helper class for multiple-criterion classifier based on taxonomy

=head1 VERSION

version 0.251810

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 METHODS

=head2 matches

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
