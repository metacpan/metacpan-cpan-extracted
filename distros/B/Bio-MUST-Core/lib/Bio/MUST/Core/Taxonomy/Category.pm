package Bio::MUST::Core::Taxonomy::Category;
# ABSTRACT: Helper class for multiple-criterion classifier based on taxonomy
$Bio::MUST::Core::Taxonomy::Category::VERSION = '0.251810';
use Moose;
use namespace::autoclean;

use Bio::MUST::Core::Types;


has 'label' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);


has 'description' => (
    is       => 'ro',
    isa      => 'Str',
    default  => 'no description',
);


has 'criteria' => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[Bio::MUST::Core::Taxonomy::Criterion]',
    required => 1,
    handles  => {
        all_criteria => 'elements',
    },
);



sub matches {
    my $self     = shift;
    my $listable = shift;
        
    # loop through criteria and fail on the first one not matching input
    # this means that the multiple criteria are linked by logical ANDs
    for my $criterion ($self->all_criteria) {
        return 0 unless $criterion->matches($listable);
    }

    # return success
    return 1;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Core::Taxonomy::Category - Helper class for multiple-criterion classifier based on taxonomy

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
