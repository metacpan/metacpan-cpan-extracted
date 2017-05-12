#!/usr/bin/perl

# This script is a fairly simple demonstration of how AI::Categorizer
# can be used.  There are lots of other less-simple demonstrations
# (actually, they're doing much simpler things, but are probably
# harder to follow) in the tests in the t/ subdirectory.  The
# eg/categorizer script can also be a good example if you're willing
# to figure out a bit how it works.
#
# This script reads a training corpus from a directory of plain-text
# documents, trains a Naive Bayes categorizer on it, then tests the
# categorizer on a set of test documents.

use strict;
use AI::Categorizer;
use AI::Categorizer::Collection::Files;
use AI::Categorizer::Learner::NaiveBayes;
use File::Spec;

die("Usage: $0 <corpus>\n".
    "  A sample corpus (data set) can be downloaded from\n".
    "     http://www.cpan.org/authors/Ken_Williams/data/reuters-21578.tar.gz\n".
    "  or http://www.limnus.com/~ken/reuters-21578.tar.gz\n")
  unless @ARGV == 1;

my $corpus = shift;

my $training  = File::Spec->catfile( $corpus, 'training' );
my $test      = File::Spec->catfile( $corpus, 'test' );
my $cats      = File::Spec->catfile( $corpus, 'cats.txt' );
my $stopwords = File::Spec->catfile( $corpus, 'stopwords' );

my %params;
if (-e $stopwords) {
  $params{stopword_file} = $stopwords;
} else {
  warn "$stopwords not found - no stopwords will be used.\n";
}

if (-e $cats) {
  $params{category_file} = $cats;
} else {
  die "$cats not found - can't proceed without category information.\n";
}


# In a real-world application these Collection objects could be of any
# type (any Collection subclass).  Or you could create each Document
# object manually.  Or you could let the KnowledgeSet create the
# Collection objects for you.

$training = AI::Categorizer::Collection::Files->new( path => $training, %params );
$test     = AI::Categorizer::Collection::Files->new( path => $test, %params );

# We turn on verbose mode so you can watch the progress of loading &
# training.  This looks nicer if you have Time::Progress installed!

print "Loading training set\n";
my $k = AI::Categorizer::KnowledgeSet->new( verbose => 1 );
$k->load( collection => $training );

print "Training categorizer\n";
my $l = AI::Categorizer::Learner::NaiveBayes->new( verbose => 1 );
$l->train( knowledge_set => $k );

print "Categorizing test set\n";
my $experiment = $l->categorize_collection( collection => $test );

print $experiment->stats_table;


# If you want to get at the specific assigned categories for a
# specific document, you can do it like this:

my $doc = AI::Categorizer::Document->new
  ( content => "Hello, I am a pretty generic document with not much to say." );

my $h = $l->categorize( $doc );

print ("For test document:\n",
       "  Best category = ", $h->best_category, "\n",
       "  All categories = ", join(', ', $h->categories), "\n");
