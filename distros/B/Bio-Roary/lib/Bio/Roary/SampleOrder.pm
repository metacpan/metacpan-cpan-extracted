package Bio::Roary::SampleOrder;
$Bio::Roary::SampleOrder::VERSION = '3.9.1';
# ABSTRACT: Take in a tree file and return an ordering of the samples


use Moose;
use Bio::TreeIO;

has 'tree_file'       => ( is => 'ro', isa => 'Str',      required => 1 );
has 'tree_format'     => ( is => 'ro', isa => 'Str',      default  => 'newick' );
has 'ordered_samples' => ( is => 'ro', isa => 'ArrayRef', lazy     => 1, builder => '_build_ordered_samples' );

# 'b|breadth' first order or 'd|depth' first order
has 'search_strategy' => ( is => 'ro', isa => 'Str', default =>  'depth' );
has 'sortby' => (is => 'ro', isa => 'Maybe[Str]');


sub _build_ordered_samples {
    my ($self) = @_;
    my $input = Bio::TreeIO->new(
        -file   => $self->tree_file,
        -format => $self->tree_format
    );
    my $tree = $input->next_tree;
    my @taxa;
    for my $leaf_node ( $tree->get_nodes($self->search_strategy,$self->sortby) ) {
      if($leaf_node->is_Leaf)
      {
        push( @taxa, $leaf_node->id );
      }
    }
    return \@taxa;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::Roary::SampleOrder - Take in a tree file and return an ordering of the samples

=head1 VERSION

version 3.9.1

=head1 SYNOPSIS

Take in a tree file and return an ordering of the samples. Defaults to depth first search
   use Bio::Roary::SampleOrder;

   my $obj = Bio::Roary::SampleOrder->new(
       tree_file        => $tree_file,
     );
   $obj->ordered_samples();

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
