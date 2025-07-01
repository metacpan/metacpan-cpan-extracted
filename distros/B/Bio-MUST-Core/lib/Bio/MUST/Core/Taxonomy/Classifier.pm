package Bio::MUST::Core::Taxonomy::Classifier;
# ABSTRACT: Helper class for multiple-criterion classifier based on taxonomy
$Bio::MUST::Core::Taxonomy::Classifier::VERSION = '0.251810';
use Moose;
use namespace::autoclean;

# use Smart::Comments;

use Const::Fast;
use List::AllUtils qw(indexes mesh partition_by pairmap);

use Bio::MUST::Core::Types;
use aliased 'Bio::MUST::Core::IdList';
use aliased 'Bio::MUST::Core::SeqMask';


has 'categories' => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[Bio::MUST::Core::Taxonomy::Category]',
    required => 1,
    handles  => {
        all_categories => 'elements',
    },
);



sub all_labels {
    my $self = shift;
    return map { $_->label } $self->all_categories;
}



sub classify {
    my $self     = shift;
    my $listable = shift;

    # loop through cats and return the first one matching input
    # this means that the cat order may affect the classification
    for my $cat ($self->all_categories) {
        return $cat->label if $cat->matches($listable);
    }

    # return undef if no suitable cat
    return;
}


# "magic" name used when a pattern has no category
const my $NOCAT => '_NOCAT_';

# TODO: come with better name for method?
# TODO: provide a shortcut if only one cat?

sub tax_masks {
    my $self = shift;
    my $ali  = shift;

    # TODO: profile and optimize as ideal_mask ?!?

    my $width = $ali->width;
    my $regex = $ali->gapmiss_regex;

    # collect site patterns in terms of valid states
    my %sites_for;
    for (my $site = 0; $site < $width; $site++) {
        my @indexes =                           # get seq indexes of states
            indexes { $_ !~ m/$regex/xms  }     # which are valid
            map     { $_->state_at($site) }     # and found at that site
            $ali->all_seqs;                     # across all seqs
        ;
        #### @indexes

        # store site for index pattern
        my $key = join q{,}, @indexes;
        push @{ $sites_for{$key} }, $site;
    }
    #### %sites_for

    # setup keys from patterns
    my @patterns = keys %sites_for;
    #### @patterns

    # fetch id lists for site patterns
    # Note: type coercion allows building an IdList from an ArrayRef[Seq]
    my @lists = map {
        IdList->new( ids => [ @{ $ali->seqs }[ split q{,} ] ] )
    } @patterns;
    #### @lists

    # attribute categories to site patterns based on corresponding id lists
    my @cats = map { $self->classify($_) // $NOCAT } @lists;
    #### @cats
    my %cat_for = mesh @patterns, @cats;
    #### %cat_for

    # partition patterns by category to build masks
    # Note: masks are defined by flattening of patterns' site lists
    my %patterns_for = partition_by { $cat_for{$_} } @patterns;
    delete $patterns_for{$NOCAT};
    #### %patterns_for

    my %mask_for = pairmap {
        $a => SeqMask->custom_mask(
            $width, [ map { @{$_} } @sites_for{ @{$b} } ]
        )
    } %patterns_for;
    #### %mask_for

    return \%mask_for;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Core::Taxonomy::Classifier - Helper class for multiple-criterion classifier based on taxonomy

=head1 VERSION

version 0.251810

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 METHODS

=head2 all_labels

=head2 classify

=head2 tax_masks

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
