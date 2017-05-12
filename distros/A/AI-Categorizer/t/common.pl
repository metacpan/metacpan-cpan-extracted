
use strict;
use Test;
use AI::Categorizer;
use AI::Categorizer::KnowledgeSet;
use AI::Categorizer::Collection::InMemory;

sub have_module {
  my $module = shift;
  return eval "use $module; 1";
}

sub need_module {
  my $module = shift;
  skip_test("$module not installed") unless have_module($module);
}

sub skip_test {
  my $msg = @_ ? shift() : '';
  print "1..0 # Skipped: $msg\n";
  exit;
}

sub training_docs {
  return (
	  doc1 => {categories => ['farming'],
		   content => 'Sheep are very valuable in farming.' },
	  doc2 => {categories => ['farming'],
		   content => 'Farming requires many kinds of animals.' },
	  doc3 => {categories => ['vampire'],
		   content => 'Vampires drink blood and vampires may be staked.' },
	  doc4 => {categories => ['vampire'],
		   content => 'Vampires cannot see their images in mirrors.'},
	 );
}

sub run_test_docs {
  my $l = shift;

  my $doc = new AI::Categorizer::Document
    ( name => 'test1',
      content => 'I would like to begin farming sheep.' );
  my $r = $l->categorize($doc);
  
  print "Categories: ", join(', ', $r->categories), "\n";
  ok($r->best_category, 'farming', "Best category is 'farming'");
  ok $r->in_category('farming'),  1, sprintf("threshold = %s, score = %s", $r->threshold, $r->scores('farming'));
  ok $r->in_category('vampire'), '', sprintf("threshold = %s, score = %s", $r->threshold, $r->scores('vampire'));
  
  ok $r->all_categories, 2, "Should be 2 categories in total";
  
  $doc = new AI::Categorizer::Document
    ( name => 'test2',
      content => "I see that many vampires may have eaten my beautiful daughter's blood." );
  $r = $l->categorize($doc);
  
  print "Categories: ", join(', ', $r->categories), "\n";
  ok($r->best_category, 'vampire', "Best category is 'vampire'");
  ok $r->in_category('farming'), '', sprintf("threshold = %s, score = %s", $r->threshold, $r->scores('farming'));
  ok $r->in_category('vampire'),  1, sprintf("threshold = %s, score = %s", $r->threshold, $r->scores('vampire'));
}

sub set_up_tests {
  my %params = @_;
  my $c = new AI::Categorizer(
			      knowledge_set => AI::Categorizer::KnowledgeSet->new
			      (
			       name => 'Vampires/Farmers',
			       stopwords => [qw(are be in of and)],
			      ),
			      verbose => $ENV{TEST_VERBOSE} ? 1 : 0,
			      %params,
			     );
  ok ref($c), 'AI::Categorizer', "Create an AI::Categorizer object";
  
  my %docs = training_docs();
  while (my ($name, $data) = each %docs) {
    $c->knowledge_set->make_document(name => $name, %$data);
  }

  my $l = $c->learner;
  ok $l;
  
  if ($params{learner_class}) {
    ok ref($l), $params{learner_class}, "Make sure the correct Learner class is instantiated";
  } else {
    ok 1, 1, "Dummy test";
  }

  $l->train;
  return ($l, \%docs);
}

sub perform_standard_tests {
  my ($l, $docs) = set_up_tests(@_);
  
  run_test_docs($l);

  # Make sure we can save state & restore state
  $l->save_state('t/state');
  $l = $l->restore_state('t/state');
  ok $l;

  run_test_docs($l);

  my $train_collection = AI::Categorizer::Collection::InMemory->new(data => $docs);
  ok $train_collection;
  
  my $h = $l->categorize_collection(collection => $train_collection);
  ok $h->micro_precision > 0.5;
}

sub num_setup_tests    () { 3 }
sub num_standard_tests () { num_setup_tests + 17 }

1;
