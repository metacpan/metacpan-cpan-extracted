package Bio::MUST::Core::Tree::Forest;
# ABSTRACT: Collection of (bootstrap) trees
$Bio::MUST::Core::Tree::Forest::VERSION = '0.251810';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

use Bio::Phylo::IO qw(parse);

use Bio::MUST::Core::Types;
use aliased 'Bio::MUST::Core::Tree';


# public array
has 'trees' => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[Bio::MUST::Core::Tree]',
    default  => sub { [] },
    handles  => {
        count_trees => 'count',
          all_trees => 'elements',
          add_tree  => 'push',
          get_tree  => 'get',
    },
);



sub restore_ids {
    my $self   = shift;
    my $mapper = shift;

    $_->restore_ids($mapper) for $self->all_trees;

    return;
}


sub load {
    my $class  = shift;
    my $infile = shift;

    my @trees;

    # build Bio::MUST::Core::Tree object from each Bio::Phylo::Forest::Tree
    my $forest = parse(-format => 'newick', -file => $infile);
    while (my $tree = $forest->next) {
        push @trees, Tree->new( tree => $tree );
    }

    return $class->new( trees => \@trees );
}


sub store {
    my $self    = shift;
    my $outfile = shift;

    open my $out, '>', $outfile;

    say {$out} join "\n", map {
        $_->tree->to_newick( -nodelabels => 0 )     # This might be an issue!
    } $self->all_trees;

    close $out;

    return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Core::Tree::Forest - Collection of (bootstrap) trees

=head1 VERSION

version 0.251810

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 METHODS

=head2 restore_ids

=head2 load

=head2 store

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
