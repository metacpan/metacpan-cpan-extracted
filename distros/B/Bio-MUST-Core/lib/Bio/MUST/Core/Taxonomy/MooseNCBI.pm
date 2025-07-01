package Bio::MUST::Core::Taxonomy::MooseNCBI;
# ABSTRACT: Wrapper class for serializing Bio::LITE::Taxonomy::NCBI object
$Bio::MUST::Core::Taxonomy::MooseNCBI::VERSION = '0.251810';
use Moose;
use namespace::autoclean;

use MooseX::NonMoose;

use Bio::LITE::Taxonomy::NCBI 0.10;         # for handling synonyms
extends 'Bio::LITE::Taxonomy::NCBI';

use Smart::Comments;


## no critic (ProhibitBuiltinHomonyms)

# provide pack and unpack methods for MooseX::Storage

use Storable;

sub pack {
    my $self = shift;

    # convert potential GLOB attributes to (useless) plain strings
    # this should not harm as Taxonomy has been already built
    $self->{namesFile} = 'serialized data';
    $self->{nodesFile} = 'serialized data';

    # pack data as would do MooseX::Storage
    # Note: not sure that the way of determining the class is Moosy enough
    my $pack = {
        __CLASS__ => ref($self),
             data => Storable::nfreeze($self)
    };
    return $pack;
}

sub unpack {
    my $class = shift;
    my $pack  = shift;

    # unpack data
    # Note: blessing is with the invokant class not the packed class
    my $object = bless Storable::thaw( $pack->{data} ), $class;
    return $object;
}

## use critic

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Core::Taxonomy::MooseNCBI - Wrapper class for serializing Bio::LITE::Taxonomy::NCBI object

=head1 VERSION

version 0.251810

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
