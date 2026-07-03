#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use Algorithm::Classifier::NaiveBayes;

my $nb = Algorithm::Classifier::NaiveBayes->new;

my @tokens = $nb->tokenize('Buy Cheap  Pills');
is_deeply( \@tokens, [ 'buy', 'cheap', 'pills' ], 'tokenize splits on whitespace and lowercases' );

@tokens = $nb->tokenize('  leading and  trailing  ');
is_deeply( \@tokens, [ 'leading', 'and', 'trailing' ], 'tokenize produces no empty tokens' );

@tokens = $nb->tokenize('');
is_deeply( \@tokens, [], 'tokenize of empty string returns nothing' );

eval { $nb->tokenize(); };
like( $@, qr/No text specified/, 'tokenize with no text dies' );

eval { $nb->tokenize(undef); };
like( $@, qr/No text specified/, 'tokenize with undef text dies' );

my $nb_nolc = Algorithm::Classifier::NaiveBayes->new( 'lc_tokens' => 0 );
@tokens = $nb_nolc->tokenize('Buy Cheap Pills');
is_deeply( \@tokens, [ 'Buy', 'Cheap', 'Pills' ], 'lc_tokens=0 preserves case' );

my $nb_stop = Algorithm::Classifier::NaiveBayes->new( 'stop_regex' => 'at|a' );
@tokens = $nb_stop->tokenize('cat at a noon');
is_deeply( \@tokens, [ 'cat', 'noon' ], 'stop_regex drops whole-token matches only' );

my $nb_split = Algorithm::Classifier::NaiveBayes->new( 'token_splitter' => ',' );
@tokens = $nb_split->tokenize('a,b,,c');
is_deeply( \@tokens, [ 'a', 'b', 'c' ], 'custom token_splitter works' );

# n-grams
my $nb_bi = Algorithm::Classifier::NaiveBayes->new( 'ngrams' => 2 );
@tokens = $nb_bi->tokenize('Free Cruise Inside');
is_deeply( \@tokens, [ 'free', 'cruise', 'inside', 'free cruise', 'cruise inside' ],
	'ngrams=2 appends adjacent pairs' );

@tokens = $nb_bi->tokenize('solo');
is_deeply( \@tokens, ['solo'], 'ngrams=2 with a single token produces no pairs' );

my $nb_tri = Algorithm::Classifier::NaiveBayes->new( 'ngrams' => 3 );
@tokens = $nb_tri->tokenize('a b c');
is_deeply( \@tokens, [ 'a', 'b', 'c', 'a b', 'b c', 'a b c' ], 'ngrams=3 appends pairs and triplets' );

# stop words are removed before n-grams are generated
my $nb_bi_stop = Algorithm::Classifier::NaiveBayes->new( 'ngrams' => 2, 'stop_regex' => 'a' );
@tokens = $nb_bi_stop->tokenize('win a cruise');
is_deeply( \@tokens, [ 'win', 'cruise', 'win cruise' ], 'n-grams are generated after stop word removal' );

done_testing;
