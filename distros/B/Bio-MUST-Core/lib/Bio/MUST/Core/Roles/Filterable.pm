package Bio::MUST::Core::Roles::Filterable;
# ABSTRACT: Filterable Moose role for objects that behave as filters
$Bio::MUST::Core::Roles::Filterable::VERSION = '0.251810';
use Moose::Role;

use autodie;
use feature qw(say);

use Smart::Comments '###';

use Carp;
use Const::Fast;

use Bio::MUST::Core::Types;
use Bio::MUST::Core::Constants qw(:seqids);

requires 'is_allowed';


has '_specs' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::IdList',
    required => 1,
    coerce   => 1,
    handles  => {
        all_specs => 'all_ids',
    },
);


has '_is_' . $_ => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef',
    init_arg => undef,
    writer   => '_set_is_' . $_,
    handles  => {
        'all_' . $_ => 'keys',
         'is_' . $_ => 'defined',
    },
) for qw(wanted unwanted);


# TODO: allow specifying taxa as partial lineages to solve ambiguities
# TODO: allow specifying taxa as taxid and/or mustids (for strains)

# regexes for deriving filter from specifications
const my $WANTED   => qr{\A \+ \s* (.*) }xms;
const my $UNWANTED => qr{\A \- \s* (.*) }xms;

sub BUILD {
    my $self = shift;

    # parse filter specifications
    my   @wanted = map { $_ =~   $WANTED ? $1 : () } $self->all_specs;
    my @unwanted = map { $_ =~ $UNWANTED ? $1 : () } $self->all_specs;

    # only for tax_filters
    if ( $self->can('tax') ) {
        #### TAXONOMIC FILTER

        # warn in case of ambiguous taxa
        for my $taxon (@wanted, @unwanted) {
            carp "[BMC] Warning: $taxon is taxonomically ambiguous in filter!"
                if $self->tax->is_dupe($taxon);
        }

        # build filtering hashes from wanted and unwanted arrays
        # Note: we want no virus by default but exclude nothing
        push @wanted, 'cellular organisms' unless @wanted;
    }

    my %is_wanted   = map { $_ => 1 }   @wanted;
    my %is_unwanted = map { $_ => 1 } @unwanted;

    # store HashRefs for filter
    $self->_set_is_wanted(  \%is_wanted  );
    $self->_set_is_unwanted(\%is_unwanted);

    return;
}


sub score {                                 ## no critic (RequireArgUnpacking)
    my $self    = shift;
    my @seq_ids = @_;

    my $seen;
    my $score = 0;

    for my $seq_id (@seq_ids) {
        #### s: $seq_id->full_id
        my $res = $self->is_allowed($seq_id);
        #### $res

        # track if at least one id passed filter
        $seen ||= $res;

        # increment score: undef => 0 ; otherwise +1 / -1
        $score += !defined $res ? 0 : $res ? +1 : -1;
        #### $score
    }

    # further return seen flag in list context
    return wantarray ? ($score, $seen) : $score;
}

no Moose::Role;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Core::Roles::Filterable - Filterable Moose role for objects that behave as filters

=head1 VERSION

version 0.251810

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 METHODS

=head2 score

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
