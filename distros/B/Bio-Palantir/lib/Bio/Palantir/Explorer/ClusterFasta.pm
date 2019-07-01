package Bio::Palantir::Explorer::ClusterFasta;
# ABSTRACT: Explorer internal class for handling ClusterFasta objects
$Bio::Palantir::Explorer::ClusterFasta::VERSION = '0.191800';
use Moose;
use namespace::autoclean;

use Data::UUID;

use Bio::MUST::Core;

use aliased 'Bio::MUST::Core::Ali';
use aliased 'Bio::Palantir::Explorer::GeneFasta';
extends 'Bio::FastParsers::Base';


# public attributes

has $_ => (
    is => 'ro',
    isa => 'Num',
    init_arg => undef,
    writer => '_set_' . $_,
) for qw(begin end size);

has 'coordinates' => (
    is => 'ro',
    isa => 'ArrayRef[Num]',
    init_arg => undef,
    writer => '_set_coordinates',
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


# private attributes


# public array(s) of composed objects


has 'genes' => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[Bio::Palantir::Explorer::GeneFasta]',
    writer  => '_set_genes',
    init_arg => undef,
    handles  => {
         count_genes => 'count',
           all_genes => 'elements',
           get_gene  => 'get',
          next_gene  => 'shift',        
    },
);


## no critic (ProhibitUnusedPrivateSubroutines)


## use critic


sub BUILD {
    my $self = shift;

    my $ali = Ali->load($self->file);

    my $end = 0;
    my ($i, @genes_fasta);
    for my $gene ($ali->all_seqs) {

        my $seq   = $gene->seq;
        my $begin = $end + 1;
           $end   = $begin + length $seq; 
        my $size  = $end - $begin + 1;
        my @coordinates = ($begin, $end);

        push @genes_fasta, GeneFasta->new( 
            rank        => ++$i,
            name        => $gene->full_id,
            gene_begin  => 1,
            gene_end    => $size,
            size        => $size,
            coordinates => \@coordinates,
            protein_sequence => $seq,
        );
    }

    $self->_set_genes(\@genes_fasta);
    $self->_update_ranks;

    $self->_set_begin(1);
    $self->_set_end($end);
    $self->_set_coordinates([1, $end]);

    return;
}

sub _update_ranks {
    my $self = shift;

    my $rank = 1;
    
    for my $gene ($self->all_genes) {
       
        my @sorted_domains = 
            sort { $a->begin <=> $b->begin } $gene->all_domains;

        for my $i (0..(scalar @sorted_domains - 1)) {
            $sorted_domains[$i]->_set_rank($rank++);
        }
    }

    return;
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::Palantir::Explorer::ClusterFasta - Explorer internal class for handling ClusterFasta objects

=head1 VERSION

version 0.191800

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 ATTRIBUTES

=head2 genes

ArrayRef of L<Bio::Palantir::Explorer::GeneFasta>

=head1 METHODS

=head2 count_genes

Returns the number of Genes of the Cluster.

    # $cluster is a Bio::Palantir::Explorer::ClusterFasta
    my $count = $cluster->count_genes;

This method does not accept any arguments.

=head2 all_genes

Returns all the Genes of the Cluster (not an array reference).

    # $cluster is a Bio::Palantir::Explorer::ClusterFasta
    my @genes = $cluster->all_genes;

This method does not accept any arguments.

=head2 get_gene

Returns one Gene of the Cluster by its index. You can also use
negative index numbers, just as with Perl's core array handling. If the
specified Gene does not exist, this method will return C<undef>.

    # $cluster is a Bio::Palantir::Explorer::ClusterFasta
    my $gene = $cluster->get_gene($index);
    croak "Gene $index not found!" unless defined $gene;

This method accepts just one argument (and not an array slice).

=head2 next_gene

Shifts the first Gene of the array off and returns it, shortening the
array by 1 and moving everything down. If there are no more Genes in
the array, returns C<undef>.

    # $cluster is a Bio::Palantir::Explorer::ClusterFasta
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
