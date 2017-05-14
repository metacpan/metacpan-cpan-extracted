package Bio::Gonzales::Phylo::Util;

use warnings;
use strict;
use Carp;

use 5.010;

use Bio::Phylo::IO qw/parse unparse/;

use base 'Exporter';
our ( @EXPORT, @EXPORT_OK, %EXPORT_TAGS );
our $VERSION = '0.0546'; # VERSION

@EXPORT      = qw();
%EXPORT_TAGS = ();
@EXPORT_OK   = qw(leaf_mapper consensus);

sub leaf_mapper {
    my ($pattern) = @_;
    $pattern //= 's%09d';

    my $handler;
    if ( ref $pattern eq 'CODE' ) {
        $handler = $pattern;
    } elsif ( ref $pattern eq 'HASH' ) {
        my $i = 1;
        $handler = sub {
            my ($id) = @_;
            
            return $pattern->{$id} // $id . '.NA';
        };
    } else {
        $handler = sub {
            my ($id, $i) = @_;
            return sprintf $pattern, $i;
        };
    }

    return sub {
        my ($tree) = @_;
        return unless ($tree);

        my $leaves = $tree->get_terminals;
        my $i = 0;

        my %map;
        for my $l (@$leaves) {
            my $orig_id = $l->get_name;
            my $id      = $handler->($orig_id, $i++);
            $l->set_name($id);
            $map{$id} = $orig_id;
        }
        return \%map;
    };
}

sub consensus {
    my ( $infile, $outfile, $cutoff ) = @_;

    my $forest = parse(
        -format => 'newick',
        -file   => $infile,
    );

    #Bio::Phylo::Forest
    my $consensus = $forest->make_consensus( -branches => 'average', -fraction => $cutoff // 0.5);
    #Bio::Phylo::Forest::Tree
    open my $outfh, '>', $outfile or die $!;
    print $outfh $consensus->to_newick( -nodelabels => 1 );
    $outfh->close;

}

1;

__END__

=head1 NAME

Bio::Gonzales::Phylo::Util - utility functions for phylogenetic analysis

=head1 SYNOPSIS

    use Bio::Gonzales::Phylo::Util qw(leaf_mapper consensus_tree);

=head1 DESCRIPTION

=head1 SUBROUTINES

=over 4

=item B<< $map_iterator = leaf_mapper($code_ref // $pattern_or_map // '%s09d') >>

Example for a code reference:

    my $map;
    my $handler = sub {
        my ($id) = @_;
        
        return $map->{$id} // $id . '.NA';
    };

    my $map_iterator = leaf_mapper($handler);

    my $mapped_tree = $map_iterator->($tree);

The iterator takes a Bio::Phylo::Forest::Tree object and remaps it. The
mapping takes place directly on the tree, thus alters it.

=item B<< consensus_tree($input_trees_file, $consensus_tree_file) >>

Parses the C<$input_tree_file>, builds a consensus tree and writes it to
C<$consensus_tree_file>.

=back

=head1 SEE ALSO

=head1 AUTHOR

jw bargsten, C<< <joachim.bargsten at wur.nl> >>

=cut
