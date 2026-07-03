#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use Algorithm::Classifier::NaiveBayes;

my $nb = Algorithm::Classifier::NaiveBayes->new;
isa_ok( $nb, 'Algorithm::Classifier::NaiveBayes', 'new' );
is( $nb->{'model'}{'lc_tokens'},      1,         'lc_tokens defaults to 1' );
is( $nb->{'model'}{'token_splitter'}, '\s+',     'token_splitter defaults to \s+' );
is( $nb->{'model'}{'stop_regex'},     undef,     'stop_regex defaults to undef' );
is( $nb->{'model'}{'total_docs'},     0,         'total_docs starts at 0' );
is( $nb->{'model'}{'smoothing'},      'laplace', 'smoothing defaults to laplace' );
is( $nb->{'model'}{'alpha'},          1,         'alpha defaults to 1 for laplace' );

my $lidstone = Algorithm::Classifier::NaiveBayes->new( 'smoothing' => 'lidstone' );
is( $lidstone->{'model'}{'smoothing'}, 'lidstone', 'smoothing arg is used' );
is( $lidstone->{'model'}{'alpha'},     0.5,        'alpha defaults to 0.5 for lidstone' );

my $lidstone_alpha = Algorithm::Classifier::NaiveBayes->new( 'smoothing' => 'lidstone', 'alpha' => 0.1 );
is( $lidstone_alpha->{'model'}{'alpha'}, 0.1, 'alpha arg is used' );

is( $nb->{'model'}{'ngrams'}, 1, 'ngrams defaults to 1' );
my $bigrams = Algorithm::Classifier::NaiveBayes->new( 'ngrams' => 2 );
is( $bigrams->{'model'}{'ngrams'}, 2, 'ngrams arg is used' );

is( $nb->{'model'}{'token_weighting'}, 'count', 'token_weighting defaults to count' );
my $binary = Algorithm::Classifier::NaiveBayes->new( 'token_weighting' => 'binary' );
is( $binary->{'model'}{'token_weighting'}, 'binary', 'token_weighting arg is used' );

is( $nb->{'model'}{'priors'}, 'trained', 'priors defaults to trained' );
my $uniform = Algorithm::Classifier::NaiveBayes->new( 'priors' => 'uniform' );
is( $uniform->{'model'}{'priors'}, 'uniform', 'priors arg is used' );

my $nb_args = Algorithm::Classifier::NaiveBayes->new(
	'lc_tokens'      => 0,
	'token_splitter' => ',',
	'stop_regex'     => 'foo',
);
is( $nb_args->{'model'}{'lc_tokens'},      0,     'lc_tokens arg is used' );
is( $nb_args->{'model'}{'token_splitter'}, ',',   'token_splitter arg is used' );
is( $nb_args->{'model'}{'stop_regex'},     'foo', 'stop_regex arg is used' );

# arg sanity checking
eval { Algorithm::Classifier::NaiveBayes->new( 'derp' => 1 ); };
like( $@, qr/not a known arg/, 'unknown args die' );

eval { Algorithm::Classifier::NaiveBayes->new( 'token_splitter' => '(' ); };
like( $@, qr/does not compile/, 'non-compiling token_splitter dies' );

eval { Algorithm::Classifier::NaiveBayes->new( 'stop_regex' => '[a-' ); };
like( $@, qr/does not compile/, 'non-compiling stop_regex dies' );

eval { Algorithm::Classifier::NaiveBayes->new( 'token_splitter' => '' ); };
like( $@, qr/empty string/, 'empty token_splitter dies' );

eval { Algorithm::Classifier::NaiveBayes->new( 'stop_regex' => [] ); };
like( $@, qr/ref of type/, 'non-Regexp ref stop_regex dies' );

eval { Algorithm::Classifier::NaiveBayes->new( 'lc_tokens' => {} ); };
like( $@, qr/ref of type/, 'ref lc_tokens dies' );

eval { Algorithm::Classifier::NaiveBayes->new( 'stop_regex' => qr/at|a/ ); };
is( $@, '', 'qr// Regexp stop_regex is accepted' );

eval { Algorithm::Classifier::NaiveBayes->new( 'token_splitter' => undef ); };
is( $@, '', 'explicit undef args are accepted' );

eval { Algorithm::Classifier::NaiveBayes->new( 'smoothing' => 'derp' ); };
like( $@, qr/smoothing must be either/, 'unknown smoothing dies' );

eval { Algorithm::Classifier::NaiveBayes->new( 'alpha' => 0.5 ); };
like( $@, qr/alpha may only be specified/, 'alpha with laplace smoothing dies' );

eval { Algorithm::Classifier::NaiveBayes->new( 'smoothing' => 'lidstone', 'alpha' => 0 ); };
like( $@, qr/greater than 0/, 'alpha of 0 dies' );

eval { Algorithm::Classifier::NaiveBayes->new( 'smoothing' => 'lidstone', 'alpha' => 'x' ); };
like( $@, qr/greater than 0/, 'non-numeric alpha dies' );

eval { Algorithm::Classifier::NaiveBayes->new( 'smoothing' => 'lidstone', 'alpha' => '.5' ); };
is( $@, '', 'a alpha of .5 is accepted' );

eval { Algorithm::Classifier::NaiveBayes->new( 'ngrams' => 0 ); };
like( $@, qr/ngrams must be/, 'a ngrams of 0 dies' );

eval { Algorithm::Classifier::NaiveBayes->new( 'ngrams' => 'x' ); };
like( $@, qr/ngrams must be/, 'a non-numeric ngrams dies' );

eval { Algorithm::Classifier::NaiveBayes->new( 'ngrams' => 1.5 ); };
like( $@, qr/ngrams must be/, 'a fractional ngrams dies' );

eval { Algorithm::Classifier::NaiveBayes->new( 'token_weighting' => 'derp' ); };
like( $@, qr/token_weighting must be either/, 'unknown token_weighting dies' );

eval { Algorithm::Classifier::NaiveBayes->new( 'priors' => 'derp' ); };
like( $@, qr/priors must be either/, 'unknown priors dies' );

done_testing;
