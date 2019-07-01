package Bio::Palantir::Refiner::ClusterPlus;
# ABSTRACT: Refiner internal class for handling ClusterPlus objects
$Bio::Palantir::Refiner::ClusterPlus::VERSION = '0.191800';
use Moose;
use namespace::autoclean;

use Smart::Comments;
use Data::UUID;

use aliased 'Bio::Palantir::Refiner::GenePlus';


# private attributes

has '_cluster' => (
    is      => 'ro',
    isa     => 'Bio::Palantir::Parser::Cluster',
    handles => [qw(
        rank name type sequence
        genomic_prot_begin genomic_prot_end genomic_prot_size
        genomic_prot_coordinates genomic_dna_begin genomic_dna_end
        genomic_dna_size genomic_dna_coordinates 
    )],
);

has 'gap_filling' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

has 'undef_cleaning' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

has 'from_seq' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has 'uui' => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => undef,
    default  => sub {
        my $self = shift;
        my $ug = Data::UUID->new;
        my $uui = $ug->create_str;    
        return $uui;
    }
);


# public array(s) of composed objects


has 'genes' => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[Bio::Palantir::Refiner::GenePlus]',
    writer  => '_set_genes',
    init_arg => undef,
    handles  => {
         count_genes => 'count',
           all_genes => 'elements',
           get_gene  => 'get',
          next_gene  => 'shift',        
    },
);

with 'Bio::Palantir::Roles::Modulable';     
with 'Bio::Palantir::Roles::Clusterable';   ## no critic (ProhibitMultipleWiths)


sub BUILD {
    my $self = shift;

    my @genes_plus;
    push @genes_plus, GenePlus->new( 
        _gene => $_, 
        gap_filling => $self->gap_filling,
        undef_cleaning => $self->undef_cleaning,
        from_seq => $self->from_seq,
    ) for $self->_cluster->all_genes;

    $self->_set_genes(\@genes_plus);
        
    $self->_update_ranks;

    return;
}

# public attributes

sub _update_ranks {
    my $self = shift;

    my $rank = 1;
    my $exp_rank = 1;
    
    for my $gene ($self->all_genes) {
       
        my @sorted_domains 
            = sort { $a->begin <=> $b->begin } $gene->all_domains;

        $sorted_domains[$_]->_set_rank($rank++) 
            for (0..(scalar @sorted_domains - 1));

        my @sorted_exp_domains 
            = sort { $a->begin <=> $b->begin } $gene->all_exp_domains;

        $sorted_exp_domains[$_]->_set_rank($exp_rank++) 
            for (0..(scalar @sorted_exp_domains - 1));
    }

    return;
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::Palantir::Refiner::ClusterPlus - Refiner internal class for handling ClusterPlus objects

=head1 VERSION

version 0.191800

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 ATTRIBUTES

=head2 genes

ArrayRef of L<Bio::Palantir::Refiner::Gene>

=head1 METHODS

=head2 count_genes

Returns the number of Genes of the Cluster.

    # $cluster is a Bio::Palantir::Refiner::Cluster
    my $count = $cluster->count_genes;

This method does not accept any arguments.

=head2 all_genes

Returns all the Genes of the Cluster (not an array reference).

    # $cluster is a Bio::Palantir::Refiner::Cluster
    my @genes = $cluster->all_genes;

This method does not accept any arguments.

=head2 get_gene

Returns one Gene of the Cluster by its index. You can also use
negative index numbers, just as with Perl's core array handling. If the
specified Gene does not exist, this method will return C<undef>.

    # $cluster is a Bio::Palantir::Refiner::Cluster
    my $gene = $cluster->get_gene($index);
    croak "Gene $index not found!" unless defined $gene;

This method accepts just one argument (and not an array slice).

=head2 next_gene

Shifts the first Gene of the array off and returns it, shortening the
array by 1 and moving everything down. If there are no more Genes in
the array, returns C<undef>.

    # $cluster is a Bio::Palantir::Refiner::Cluster
    while (my $gene = $cluster->next_gene) {
        # process $gene
        # ...
    }

This method does not accept any arguments.

=head1 AUTHOR

Loic MEUNIER <lmeunier@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by University of Liege / Unit of Eukaryotic Phylogenomics / Loic MEUNIER and Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
