#!/usr/bin/perl -w

use strict;
use Test;
BEGIN { plan tests => 27, todo => [] };

use AI::Categorizer;
use AI::Categorizer::Document;
use AI::Categorizer::FeatureVector;

ok(1);
my $docclass = 'AI::Categorizer::Document';

# Test empty document creation
{
  my $d = $docclass->new;
  ok ref($d), $docclass, "Basic empty document creation";
  ok $d->features, undef;
}

# Test basic document creation
{
  my $d = $docclass->new(content => "Hello world");
  ok ref($d), $docclass, "Basic document creation with 'content' parameter";
  ok $d->features->includes('hello'), 1;
  ok $d->features->includes('world'), 1;
  ok $d->features->includes('foo'),  '';
}

# Test document creation with 'parse'
{
  require AI::Categorizer::Document::Text;
  my $d = AI::Categorizer::Document::Text->new( parse => "Hello world" );
  ok ref($d), 'AI::Categorizer::Document::Text', "Document creation with 'parse' parameter";
  ok $d->features->includes('hello'), 1;
  ok $d->features->includes('world'), 1;
  ok $d->features->includes('foo'),  '';
}

# Test document creation with 'features'
{
  my $d = $docclass->new(features => AI::Categorizer::FeatureVector->new(features => {one => 1, two => 2}));
  ok ref($d), $docclass, "Document creation with 'features' parameter";
  ok $d->features->value('one'), 1;
  ok $d->features->value('two'), 2;
  ok $d->features->includes('foo'), '';
}
  

# Test some stemming & stopword stuff.
{
  my $d = $docclass->new
    (
     name => 'test',
     stopwords => ['stemmed'],
     stemming => 'porter',
     content  => 'stopword processing should happen after stemming',
     # Becomes qw(stopword process    should happen after stem    )
    );
  ok $d->stopword_behavior, 'stem', "stopword_behavior() is 'stem'";
  
  ok $d->features->includes('stopword'), 1,  "Should include 'stopword'";
  ok $d->features->includes('stemming'), '', "Shouldn't include 'stemming'";
  ok $d->features->includes('stem'),     '', "Shouldn't include 'stem'";
  print "Features: @{[ $d->features->names ]}\n";
}

{
  my $d = $docclass->new
    (
     name => 'test',
     stopwords => ['stemmed'],
     stemming => 'porter',
     stopword_behavior => 'no_stem',
     content  => 'stopword processing should happen after stemming',
     # Becomes qw(stopword process    should happen after stem    )
    );
  ok $d->stopword_behavior, 'no_stem', "stopword_behavior() is 'no_stem'";
  
  ok $d->features->includes('stopword'), 1,  "Should include 'stopword'";
  ok $d->features->includes('stemming'), '', "Shouldn't include 'stemming'";
  ok $d->features->includes('stem'),     1,  "Should include 'stem'";
  print "Features: @{[ $d->features->names ]}\n";
}

{
  my $d = $docclass->new
    (
     name => 'test',
     stopwords => ['stem'],
     stemming => 'porter',
     stopword_behavior => 'pre_stemmed',
     content  => 'stopword processing should happen after stemming',
     # Becomes qw(stopword process    should happen after stem    )
    );
  ok $d->stopword_behavior, 'pre_stemmed', "stopword_behavior() is 'pre_stemmed'";
  
  ok $d->features->includes('stopword'), 1,  "Should include 'stopword'";
  ok $d->features->includes('stemming'), '', "Shouldn't include 'stemming'";
  ok $d->features->includes('stem'),     '', "Shouldn't include 'stem'";
  print "Features: @{[ $d->features->names ]}\n";
}
