#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use Algorithm::Classifier::NaiveBayes;

my $nb = Algorithm::Classifier::NaiveBayes->new;
$nb->train( 'spam', 'cheap pills cheap pills buy' );
$nb->train( 'ham',  'meeting tomorrow meeting pills' );

# validation
eval { $nb->prune(); };
like( $@, qr/No min count specified/, 'prune with no min count dies' );

eval { $nb->prune(0); };
like( $@, qr/greater than 0/, 'prune with a min count of 0 dies' );

eval { $nb->prune('x'); };
like( $@, qr/greater than 0/, 'prune with a non-numeric min count dies' );

# a min count of 1 is a noop
is( $nb->prune(1),                             0, 'prune of 1 removes nothing' );
is( scalar keys %{ $nb->{'model'}{'tokens'} }, 5, 'vocabulary unchanged after prune of 1' );

# counts... cheap=2, pills=3 across classes, buy=1, meeting=2, tomorrow=1
is( $nb->prune(2), 2, 'prune returns the number of tokens removed' );
ok( !exists $nb->{'model'}{'tokens'}{'buy'},      'rare token removed from the vocabulary' );
ok( !exists $nb->{'model'}{'tokens'}{'tomorrow'}, 'rare token removed from the vocabulary' );
ok( exists $nb->{'model'}{'tokens'}{'cheap'},     'common token kept' );
ok( exists $nb->{'model'}{'token_counts'}{'ham'}{'pills'},
	'token kept in a class where it is rare as the cross class total is high enough' );
ok( !exists $nb->{'model'}{'token_counts'}{'spam'}{'buy'}, 'rare token removed from token_counts' );

# class_totals decremented by what was removed
is( $nb->{'model'}{'class_totals'}{'spam'}, 4, 'class_totals decremented for spam' );
is( $nb->{'model'}{'class_totals'}{'ham'},  3, 'class_totals decremented for ham' );

# document counts and priors untouched
is( $nb->{'model'}{'total_docs'},           2, 'total_docs unchanged by prune' );
is( $nb->{'model'}{'class_counts'}{'spam'}, 1, 'class_counts unchanged by prune' );

# still classifies afterwards
is( $nb->classify('cheap pills'), 'spam', 'classify still works after pruning' );

# pruning everything leaves a working, if useless, model
is( $nb->prune(100), 3, 'prune can remove everything' );
is_deeply( $nb->{'model'}{'tokens'}, {}, 'vocabulary empty after pruning everything' );
ok( defined( $nb->classify('cheap pills') ), 'classify still works with a fully pruned model' );

done_testing;
