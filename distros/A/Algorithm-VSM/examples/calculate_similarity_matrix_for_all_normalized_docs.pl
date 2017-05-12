#!/usr/bin/perl -w

use lib '../blib/lib', '../blib/arch';

## calculate_similarity_matrix_for_all_normalized_docs.pl


#  This script demonstrates how you can calculate the similarity matrix for
#  all of the documents in your corpus.  The (i,j)th element of the output
#  matrix is the dot-vector based similarity between the i-th document and
#  the j-th document.  The index associated with a documnet is its place in
#  an alphabetically sorted list of all the documents.

#  This scirpt compares documents using their NORMALIZED vector
#  representations.

#  The similarity matrices are stored in a CSV file whose column headings
#  are the names of the documents.  The same is the case with the entries in
#  the first column.  

use strict;
use Algorithm::VSM;
use Text::CSV;

my $corpus_dir = "minicorpus";
my $stop_words_file = "stop_words.txt";   

my $vsm = Algorithm::VSM->new( 
                   break_camelcased_and_underscored  => 1,  # default: 1
                   case_sensitive           => 0,           # default: 0 
                   corpus_directory         => $corpus_dir,
                   file_types               => ['.txt', '.java'],
                   min_word_length          => 4,
                   stop_words_file          => $stop_words_file,
                   want_stemming            => 1,           # default: 0
          );

$vsm->get_corpus_vocabulary_and_word_counts();
$vsm->generate_document_vectors();

#    If you would like to directly measure the similarity between two
#    specific documents, uncomment the following two statements.
#    Obviously, you will have to change the arguments to suit your needs.
#    Note that the arguments "AddArray.java" and "ArrayBasic.java" are
#    names of specific documents in the subdirectory 'corpus' of the
#    'examples' directory of the distro.  You must change these to the
#    filenames of the documents you want to compare.
#my $similarity = $vsm->pairwise_similarity_for_docs("AddArray.java", "ArrayBasic.java");
#print "Similarity score: $similarity\n";

#    If you would the above calculation to be carried out with normalized
#    document vectors, uncomment the following two statements.  Again, you
#    must change the arguments strings "AddArray.java" and "ArrayBasic.java"
#    to the names of the documents you want to compare.
#my $similarity2 = $vsm->pairwise_similarity_for_normalized_docs("AddArray.java", "ArrayBasic.java");
#print "Similarity score for normalized docs: $similarity\n";

my @docs = @{$vsm->get_all_document_names()};

my @similarity_matrix;
foreach my $i (0..@docs-1) {
    my @one_row = ();
    foreach my $j (0..@docs-1) {
        push @one_row, $vsm->pairwise_similarity_for_normalized_docs($docs[$i], $docs[$j]);
    }
    push @similarity_matrix, \@one_row;
}

foreach my $m (0..@similarity_matrix-1) {
    my @row = @{$similarity_matrix[$m]};
    foreach my $n (0..@row-1) {
        my $sim_val = $row[$n];
        $sim_val =~ s/^(\d+\.\d{1,4})\d*$/$1/;        
        print "$sim_val ";
    }
    print "\n";
}

foreach my $m (0..@similarity_matrix-1) {
    unshift @{$similarity_matrix[$m]}, $docs[$m];
}
unshift @docs, "       ";
unshift @similarity_matrix, \@docs;
my $csv = Text::CSV->new ( { binary => 1 } )  # should set binary attribute.
    or die "Cannot use CSV: ".Text::CSV->error_diag ();
$csv->eol ("\r\n");
open my $fh, ">:encoding(utf8)", "SimilarityMatrixNormalizedDocs.csv" 
                                       or die "SimilarityMatrixNormalizedDocs.csv: $!";
#$csv->print ($fh, $_) for @rows;
$csv->print ($fh, $_) for @similarity_matrix;
close $fh or die "SimilarityMatrixNormalizedDocs.csv: $!";
