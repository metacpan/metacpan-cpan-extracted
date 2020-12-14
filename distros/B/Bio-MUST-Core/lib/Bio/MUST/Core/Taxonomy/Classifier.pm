package Bio::MUST::Core::Taxonomy::Classifier;
# ABSTRACT: Helper class for multiple-criterion classifier based on taxonomy
$Bio::MUST::Core::Taxonomy::Classifier::VERSION = '0.203490';
use Moose;
use namespace::autoclean;

use Bio::MUST::Core::Types;
use aliased 'Bio::MUST::Core::IdList';


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

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Core::Taxonomy::Classifier - Helper class for multiple-criterion classifier based on taxonomy

=head1 VERSION

version 0.203490

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 METHODS

=head2 all_labels

=head2 classify

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
