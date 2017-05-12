#!/usr/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use strict;
use Test;
BEGIN { 
  require 't/common.pl';
  need_module('Algorithm::NaiveBayes');
  plan tests => 15 + num_standard_tests();
}

ok(1);

#########################

perform_standard_tests(learner_class => 'AI::Categorizer::Learner::NaiveBayes');

#use Carp; $SIG{__DIE__} = \&Carp::confess;

my %docs = training_docs();

{
  ok my $c = new AI::Categorizer(collection_weighting => 'f');
  
  while (my ($name, $data) = each %docs) {
    $c->knowledge_set->make_document(name => $name, %$data);
  }
  
  $c->knowledge_set->finish;

  # Make sure collection_weighting is working
  ok $c->knowledge_set->document_frequency('vampires'), 2;
  for ('vampires', 'mirrors') {
    ok ($c->knowledge_set->document('doc4')->features->as_hash->{$_},
	log( keys(%docs) / $c->knowledge_set->document_frequency($_) )
       );
  }

  $c->learner->train( knowledge_set => $c->knowledge_set );
  ok $c->learner;
  
  my $doc = new AI::Categorizer::Document
    ( name => 'test1',
      content => 'I would like to begin farming sheep.' );
  ok $c->learner->categorize($doc)->best_category, 'farming';
}

{
  ok my $c = new AI::Categorizer(term_weighting => 'b');
  
  while (my ($name, $data) = each %docs) {
    $c->knowledge_set->make_document(name => $name, %$data);
  }
  
  $c->knowledge_set->finish;
  
  # Make sure term_weighting is working
  ok $c->knowledge_set->document('doc3')->features->as_hash->{vampires}, 1;
}

{
  ok my $c = new AI::Categorizer(term_weighting => 'n');
  
  while (my ($name, $data) = each %docs) {
    $c->knowledge_set->make_document(name => $name, %$data);
  }
  
  $c->knowledge_set->finish;
  
  # Make sure term_weighting is working
  ok $c->knowledge_set->document('doc3')->features->as_hash->{vampires}, 1;
  ok $c->knowledge_set->document('doc3')->features->as_hash->{blood}, 0.75;
  ok $c->knowledge_set->document('doc4')->features->as_hash->{mirrors}, 1;
}

{
  ok my $c = new AI::Categorizer(tfidf_weighting => 'txx');
  
  while (my ($name, $data) = each %docs) {
    $c->knowledge_set->make_document(name => $name, %$data);
  }
  
  $c->knowledge_set->finish;
  
  # Make sure term_weighting is working
  ok $c->knowledge_set->document('doc3')->features->as_hash->{vampires}, 2;
}
