#!/usr/bin/perl -w

use strict;
use Test;
BEGIN { plan tests => 13 };

use AI::Categorizer;
use File::Spec;
require File::Spec->catfile('t', 'common.pl');

ok 1;  # Loaded

# Test InMemory collection
use AI::Categorizer::Collection::InMemory;
my $c = AI::Categorizer::Collection::InMemory->new(data => {training_docs()});
ok $c;
exercise_collection($c, 4);

# Test Files collection
use AI::Categorizer::Collection::Files;
$c = AI::Categorizer::Collection::Files->new(path => File::Spec->catdir('t', 'traindocs'),
					     category_hash => {
							       doc1 => ['farming'],
							       doc2 => ['farming'],
							       doc3 => ['vampire'],
							       doc4 => ['vampire'],
							      },
					    );
ok $c;
exercise_collection($c, 4);

# 5 tests here
sub exercise_collection {
  my ($c, $num_docs) = @_;
  
  my $d = $c->next;
  ok $d;
  ok $d->isa('AI::Categorizer::Document');
  
  $c->rewind;
  my $d2 = $c->next;
  ok $d2->name, $d->name, "Make sure we get the same document after a rewind";
  
  my $count = $c->count_documents;
  ok $count, $num_docs, "Make sure we have the expected number of documents";
  $d2 = $c->next;
  my $count2 = $c->count_documents;
  ok $count2, $num_docs,
    "Make sure the count isn't affected by the iterator position (the reverse may not be true)";
}
